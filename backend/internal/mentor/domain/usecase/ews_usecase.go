package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
	mentormodels "github.com/gilabs/sanctuary/internal/mentor/data/models"
	mentorrepo "github.com/gilabs/sanctuary/internal/mentor/data/repositories"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
	studentrepo "github.com/gilabs/sanctuary/internal/student/data/repositories"
)

// ==================================================================
// EARLY WARNING SYSTEM ENGINE
//
// Skor dihitung SERVER-SIDE dari 4 indikator (dokumen Sanctuary):
//
//	1. LOW_MOOD_STREAK        — mood rendah lebih dari 5 hari berturut-turut
//	2. NEGATIVE_EMOTION_RATIO — emosi negatif > 60% (minimal 4 data)
//	3. DASS_WORSENING         — skor DASS-21 memburuk dibanding skrining sebelumnya
//	4. LOW_SLEEP_NIGHTS       — kurang tidur (<5 jam) minimal 2 malam
//
// Level: 0 = Normal, 1 = Waspada, 2 = Risiko, >=3 = Perlu Intervensi.
// DASS-21 pada kategori Severe/Extremely Severe langsung -> Perlu Intervensi.
// Bila data harian di bawah ambang minimum -> "Data belum cukup".
//
// Seluruh ambang berasal dari config (EWSConfig), bukan angka hardcode,
// agar dapat dikalibrasi tim konseling tanpa mengubah kode.
// ==================================================================

// Indicator adalah rincian satu indikator (disimpan pada kolom jsonb).
type Indicator struct {
	Code      string  `json:"code"`
	Label     string  `json:"label"`
	Triggered bool    `json:"triggered"`
	Value     float64 `json:"value"`
	Threshold float64 `json:"threshold"`
	Detail    string  `json:"detail"`
}

// EWSResult adalah keluaran engine (belum disaring aturan privasi).
type EWSResult struct {
	StudentID    string
	Score        int
	Level        constants.EWSLevel
	Indicators   []Indicator
	IsSufficient bool
	DataPoints   int
	DassSevere   bool
	EvaluatedAt  time.Time
	WindowDays   int
}

type EWSUsecase interface {
	// Evaluate menghitung EWS satu mahasiswa dan menyimpan lognya.
	Evaluate(ctx context.Context, studentID string, advisorID *string) (EWSResult, error)
	// EvaluateMany dipakai daftar bimbingan; memakai cache log harian bila masih segar.
	EvaluateMany(ctx context.Context, studentIDs []string, advisorID *string) (map[string]EWSResult, error)
	// Calculate adalah inti kalkulasi murni (tanpa I/O) — mudah diuji unit.
	//
	// emotions berisi hitungan label emosi hasil analisis JURNAL pada jendela
	// yang sama; hanya label dan jumlahnya, tanpa satu pun teks jurnal.
	Calculate(
		studentID string,
		metrics []studentmodels.StudentDailyMetric,
		emotions []studentrepo.EmotionCount,
		dass []studentmodels.Dass21Result,
	) EWSResult
}

type ewsUsecase struct {
	metrics  studentrepo.DailyMetricRepository
	journals studentrepo.JournalRepository
	dass     studentrepo.DassRepository
	logs     mentorrepo.EarlyWarningRepository
	cfg      config.EWSConfig
}

func NewEWSUsecase(
	metrics studentrepo.DailyMetricRepository,
	journals studentrepo.JournalRepository,
	dass studentrepo.DassRepository,
	logs mentorrepo.EarlyWarningRepository,
	cfg config.EWSConfig,
) EWSUsecase {
	return &ewsUsecase{metrics: metrics, journals: journals, dass: dass, logs: logs, cfg: cfg}
}

func (u *ewsUsecase) Evaluate(ctx context.Context, studentID string, advisorID *string) (EWSResult, error) {
	from := apptime.DaysAgo(u.cfg.LookbackDays)
	to := apptime.Today()

	metrics, err := u.metrics.ListByUserRange(ctx, studentID, from, to)
	if err != nil {
		return EWSResult{}, err
	}
	// D-3: emosi negatif dihitung dari analisis jurnal, bukan check-in mood —
	// mood sudah diwakili indikator #1, dan menghitungnya lagi di sini membuat
	// satu hari buruk menaikkan skor dua kali.
	emotions, err := u.journals.EmotionDistributionForUser(ctx, studentID, from, to)
	if err != nil {
		return EWSResult{}, err
	}
	dassResults, err := u.dass.LatestTwoForUser(ctx, studentID)
	if err != nil {
		return EWSResult{}, err
	}

	result := u.Calculate(studentID, metrics, emotions, dassResults)

	if err := u.persist(ctx, result, advisorID); err != nil {
		return result, err
	}
	return result, nil
}

func (u *ewsUsecase) EvaluateMany(ctx context.Context, studentIDs []string, advisorID *string) (map[string]EWSResult, error) {
	out := make(map[string]EWSResult, len(studentIDs))
	if len(studentIDs) == 0 {
		return out, nil
	}

	// Log yang dievaluasi hari ini dianggap masih berlaku (check-in bersifat harian).
	cached, err := u.logs.LatestSince(ctx, studentIDs, apptime.Today())
	if err != nil {
		return nil, err
	}

	for _, id := range studentIDs {
		if log, ok := cached[id]; ok {
			out[id] = fromLog(log, u.cfg.LookbackDays)
			continue
		}
		result, err := u.Evaluate(ctx, id, advisorID)
		if err != nil {
			return nil, err
		}
		out[id] = result
	}
	return out, nil
}

// ------------------------------------------------------------------
// Kalkulasi murni
// ------------------------------------------------------------------

func (u *ewsUsecase) Calculate(
	studentID string,
	metrics []studentmodels.StudentDailyMetric,
	emotions []studentrepo.EmotionCount,
	dassResults []studentmodels.Dass21Result,
) EWSResult {
	now := apptime.Now()

	result := EWSResult{
		StudentID:   studentID,
		DataPoints:  len(metrics),
		EvaluatedAt: now,
		WindowDays:  u.cfg.LookbackDays,
	}

	// Data belum cukup: jangan pernah menampilkan level menyesatkan ke dosen.
	if len(metrics) < u.cfg.MinDataPoints {
		result.Level = constants.EWSLevelInsufficient
		result.IsSufficient = false
		result.Indicators = []Indicator{}
		return result
	}
	result.IsSufficient = true

	indicators := []Indicator{
		u.indicatorLowMoodStreak(metrics),
		u.indicatorNegativeEmotion(emotions),
		u.indicatorDassWorsening(dassResults),
		u.indicatorLowSleep(metrics),
	}

	score := 0
	for _, ind := range indicators {
		if ind.Triggered {
			score++
		}
	}

	dassSevere := len(dassResults) > 0 && dassResults[0].HasSevere()

	result.Indicators = indicators
	result.Score = score
	result.DassSevere = dassSevere
	result.Level = constants.EWSLevelFromScore(score, dassSevere)
	return result
}

// Indikator 1 — mood rendah berturut-turut.
// Streak dihitung pada hari kalender yang benar-benar berurutan; hari tanpa
// check-in memutus rangkaian (tidak diasumsikan buruk maupun baik).
func (u *ewsUsecase) indicatorLowMoodStreak(metrics []studentmodels.StudentDailyMetric) Indicator {
	longest, current := 0, 0
	var prevDate time.Time

	for i, m := range metrics {
		isLow := m.MoodScore <= u.cfg.LowMoodThreshold
		consecutive := i > 0 && m.MetricDate.Sub(prevDate) <= 24*time.Hour+time.Minute

		switch {
		case isLow && consecutive:
			current++
		case isLow:
			current = 1
		default:
			current = 0
		}
		if current > longest {
			longest = current
		}
		prevDate = m.MetricDate
	}

	// Ambang bersifat "lebih dari" sesuai aturan: mood rendah > 5 hari.
	triggered := longest > u.cfg.LowMoodMinStreakDays

	return Indicator{
		Code:      constants.IndicatorLowMoodStreak,
		Label:     "Mood rendah berturut-turut",
		Triggered: triggered,
		Value:     float64(longest),
		Threshold: float64(u.cfg.LowMoodMinStreakDays),
		Detail:    fmt.Sprintf("Rangkaian terpanjang %d hari (mood <= %d)", longest, u.cfg.LowMoodThreshold),
	}
}

// Indikator 2 — rasio emosi negatif > 60% dengan minimal 4 hasil analisis.
//
// Sumbernya HANYA analisis jurnal (D-3). Sebelumnya indikator ini membaca
// emotion_label pada check-in mood, padahal mood check-in sudah diwakili
// indikator #1 — satu hari buruk terhitung dua kali. Sejak label emosi dihapus
// dari form check-in, kolom itu juga tidak lagi terisi.
func (u *ewsUsecase) indicatorNegativeEmotion(emotions []studentrepo.EmotionCount) Indicator {
	labeled, negative := 0, 0
	for _, e := range emotions {
		if e.EmotionLabel == "" {
			continue
		}
		labeled += e.Total
		if constants.IsNegativeEmotion(e.EmotionLabel) {
			negative += e.Total
		}
	}

	ratio := 0.0
	if labeled > 0 {
		ratio = float64(negative) / float64(labeled)
	}

	triggered := labeled >= u.cfg.NegativeEmotionSamples && ratio > u.cfg.NegativeEmotionRatio
	detail := fmt.Sprintf("%d dari %d jurnal teranalisis bernada negatif", negative, labeled)
	if labeled < u.cfg.NegativeEmotionSamples {
		detail = fmt.Sprintf("Baru %d jurnal teranalisis (minimal %d untuk dinilai)", labeled, u.cfg.NegativeEmotionSamples)
	}

	return Indicator{
		Code:      constants.IndicatorNegativeEmotion,
		Label:     "Dominasi emosi negatif",
		Triggered: triggered,
		Value:     round2(ratio),
		Threshold: u.cfg.NegativeEmotionRatio,
		Detail:    detail,
	}
}

// Indikator 3 — DASS-21 memburuk dibanding skrining sebelumnya.
// dassResults diurutkan terbaru lebih dulu.
func (u *ewsUsecase) indicatorDassWorsening(dassResults []studentmodels.Dass21Result) Indicator {
	indicator := Indicator{
		Code:      constants.IndicatorDassWorsening,
		Label:     "Skor DASS-21 memburuk",
		Threshold: 0,
		Detail:    "Belum ada dua hasil skrining untuk dibandingkan",
	}
	if len(dassResults) < 2 {
		return indicator
	}

	latest, previous := dassResults[0], dassResults[1]
	delta := latest.TotalScore() - previous.TotalScore()

	// Memburuk bila total skor naik, atau muncul kategori Severe yang sebelumnya tidak ada.
	severityWorsened := latest.HasSevere() && !previous.HasSevere()

	indicator.Triggered = delta > 0 || severityWorsened
	indicator.Value = float64(delta)
	indicator.Detail = fmt.Sprintf("Total skor %d → %d (%+d)", previous.TotalScore(), latest.TotalScore(), delta)
	return indicator
}

// Indikator 4 — kurang tidur minimal 2 malam pada rentang evaluasi.
func (u *ewsUsecase) indicatorLowSleep(metrics []studentmodels.StudentDailyMetric) Indicator {
	nights := 0
	for _, m := range metrics {
		if m.SleepHours < u.cfg.LowSleepHours {
			nights++
		}
	}

	return Indicator{
		Code:      constants.IndicatorLowSleep,
		Label:     "Kurang tidur",
		Triggered: nights >= u.cfg.LowSleepMinNights,
		Value:     float64(nights),
		Threshold: float64(u.cfg.LowSleepMinNights),
		Detail:    fmt.Sprintf("%d malam dengan tidur < %.0f jam", nights, u.cfg.LowSleepHours),
	}
}

// ------------------------------------------------------------------
// Persistensi & konversi
// ------------------------------------------------------------------

func (u *ewsUsecase) persist(ctx context.Context, result EWSResult, advisorID *string) error {
	payload, err := json.Marshal(result.Indicators)
	if err != nil {
		return utils.WrapInternal(err)
	}

	return u.logs.Save(ctx, &mentormodels.EarlyWarningLog{
		StudentID:    result.StudentID,
		AdvisorID:    advisorID,
		Score:        result.Score,
		Level:        result.Level,
		Indicators:   payload,
		IsSufficient: result.IsSufficient,
		DataPoints:   result.DataPoints,
		DassSevere:   result.DassSevere,
		EvaluatedAt:  result.EvaluatedAt,
	})
}

func fromLog(log mentormodels.EarlyWarningLog, windowDays int) EWSResult {
	var indicators []Indicator
	if len(log.Indicators) > 0 {
		_ = json.Unmarshal(log.Indicators, &indicators)
	}
	return EWSResult{
		StudentID:    log.StudentID,
		Score:        log.Score,
		Level:        log.Level,
		Indicators:   indicators,
		IsSufficient: log.IsSufficient,
		DataPoints:   log.DataPoints,
		DassSevere:   log.DassSevere,
		EvaluatedAt:  log.EvaluatedAt,
		WindowDays:   windowDays,
	}
}

func round2(v float64) float64 { return float64(int(v*100+0.5)) / 100 }
