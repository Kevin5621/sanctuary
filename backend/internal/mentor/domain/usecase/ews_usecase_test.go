package usecase

import (
	"testing"
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
	studentrepo "github.com/gilabs/sanctuary/internal/student/data/repositories"
)

func testEngine() *ewsUsecase {
	return &ewsUsecase{cfg: config.EWSConfig{
		LookbackDays:           14,
		MinDataPoints:          4,
		LowMoodThreshold:       2,
		LowMoodMinStreakDays:   5,
		NegativeEmotionRatio:   0.6,
		NegativeEmotionSamples: 4,
		LowSleepHours:          5,
		LowSleepMinNights:      2,
	}}
}

// metric membantu menyusun rangkaian check-in harian berurutan.
//
// Tidak ada label emosi di sini: check-in hanya kuantitatif, dan emosi yang
// dinilai EWS #2 datang dari analisis jurnal (D-3).
func metric(dayOffset, mood, stress int, sleep float64) studentmodels.StudentDailyMetric {
	return studentmodels.StudentDailyMetric{
		MetricDate:  apptime.Today().AddDate(0, 0, -dayOffset),
		MoodScore:   mood,
		StressLevel: stress,
		SleepHours:  sleep,
	}
}

// journalEmotions menyusun hitungan label emosi hasil analisis jurnal, bentuk
// yang sama dengan yang dikembalikan JournalRepository.
func journalEmotions(pairs ...any) []studentrepo.EmotionCount {
	out := make([]studentrepo.EmotionCount, 0, len(pairs)/2)
	for i := 0; i < len(pairs); i += 2 {
		out = append(out, studentrepo.EmotionCount{
			EmotionLabel: pairs[i].(string),
			Total:        pairs[i+1].(int),
		})
	}
	return out
}

func TestCalculate_InsufficientData(t *testing.T) {
	engine := testEngine()

	result := engine.Calculate("student-1", []studentmodels.StudentDailyMetric{
		metric(2, 1, 5, 4),
		metric(1, 1, 5, 4),
	}, nil, nil)

	if result.IsSufficient {
		t.Fatalf("expected insufficient data with 2 check-ins")
	}
	if result.Level != constants.EWSLevelInsufficient {
		t.Fatalf("level = %s, want %s", result.Level, constants.EWSLevelInsufficient)
	}
}

func TestCalculate_NormalWhenNoIndicatorTriggered(t *testing.T) {
	engine := testEngine()

	metrics := []studentmodels.StudentDailyMetric{
		metric(5, 4, 2, 7.5),
		metric(4, 4, 2, 8),
		metric(3, 5, 1, 7),
		metric(2, 4, 2, 7),
		metric(1, 4, 2, 7.5),
	}

	result := engine.Calculate("student-1", metrics, nil, nil)

	if result.Score != 0 || result.Level != constants.EWSLevelNormal {
		t.Fatalf("score=%d level=%s, want 0/NORMAL", result.Score, result.Level)
	}
}

func TestCalculate_LowMoodStreakNeedsMoreThanFiveDays(t *testing.T) {
	engine := testEngine()

	// Tepat 5 hari mood rendah berturut-turut: BELUM memicu (aturan "> 5 hari").
	fiveDays := []studentmodels.StudentDailyMetric{
		metric(5, 2, 3, 7),
		metric(4, 2, 3, 7),
		metric(3, 1, 3, 7),
		metric(2, 2, 3, 7),
		metric(1, 2, 3, 7),
	}
	if triggered := engine.indicatorLowMoodStreak(fiveDays).Triggered; triggered {
		t.Fatalf("5-day streak should not trigger")
	}

	sixDays := append([]studentmodels.StudentDailyMetric{metric(6, 2, 3, 7)}, fiveDays...)
	if triggered := engine.indicatorLowMoodStreak(sixDays).Triggered; !triggered {
		t.Fatalf("6-day streak should trigger")
	}
}

func TestCalculate_LowMoodStreakBrokenByMissingDay(t *testing.T) {
	engine := testEngine()

	// Ada lompatan tanggal (hari ke-4 tidak check-in) → rangkaian terputus.
	metrics := []studentmodels.StudentDailyMetric{
		metric(8, 1, 4, 6),
		metric(7, 1, 4, 6),
		metric(6, 1, 4, 6),
		metric(3, 1, 4, 6),
		metric(2, 1, 4, 6),
		metric(1, 1, 4, 6),
	}

	if triggered := engine.indicatorLowMoodStreak(metrics).Triggered; triggered {
		t.Fatalf("streak interrupted by missing days should not trigger")
	}
}

// EWS #2 dihitung dari analisis jurnal (D-3), bukan check-in mood.
func TestCalculate_NegativeEmotionRatio(t *testing.T) {
	engine := testEngine()

	// 3 dari 4 jurnal = 75% > 60% dan memenuhi minimal 4 sampel.
	indicator := engine.indicatorNegativeEmotion(journalEmotions(
		constants.EmotionAnxious, 2,
		constants.EmotionSad, 1,
		constants.EmotionCalm, 1,
	))
	if !indicator.Triggered {
		t.Fatalf("expected negative emotion indicator to trigger, got %+v", indicator)
	}

	// Sampel kurang dari 4 tidak boleh memicu walau seluruhnya negatif.
	few := journalEmotions(constants.EmotionSad, 3)
	if engine.indicatorNegativeEmotion(few).Triggered {
		t.Fatalf("fewer than min samples should not trigger")
	}
}

// D-3: mood check-in sudah diwakili indikator #1. Baris check-in lama yang
// masih menyimpan emotion_label tidak boleh ikut menaikkan indikator ini —
// satu hari buruk hanya boleh dihitung sekali.
func TestNegativeEmotion_IgnoresCheckinEmotionLabels(t *testing.T) {
	engine := testEngine()

	legacy := []studentmodels.StudentDailyMetric{
		metric(4, 1, 5, 7), metric(3, 1, 5, 7), metric(2, 1, 5, 7), metric(1, 1, 5, 7),
	}
	for i := range legacy {
		legacy[i].EmotionLabel = constants.EmotionSad
	}

	result := engine.Calculate("student-1", legacy, nil, nil)

	for _, ind := range result.Indicators {
		if ind.Code == constants.IndicatorNegativeEmotion && ind.Triggered {
			t.Fatalf("emosi pada check-in tidak boleh memicu EWS #2: %+v", ind)
		}
	}
}

func TestCalculate_LowSleepNights(t *testing.T) {
	engine := testEngine()

	metrics := []studentmodels.StudentDailyMetric{
		metric(4, 3, 3, 4.5),
		metric(3, 3, 3, 6.5),
		metric(2, 3, 3, 4.0),
		metric(1, 3, 3, 7.0),
	}

	if !engine.indicatorLowSleep(metrics).Triggered {
		t.Fatalf("two nights under 5 hours should trigger")
	}
}

func TestCalculate_DassSevereForcesIntervention(t *testing.T) {
	engine := testEngine()

	metrics := []studentmodels.StudentDailyMetric{
		metric(4, 4, 2, 7),
		metric(3, 4, 2, 7),
		metric(2, 4, 2, 7),
		metric(1, 5, 1, 8),
	}
	dass := []studentmodels.Dass21Result{{
		DepressionScore:    28,
		AnxietyScore:       20,
		StressScore:        30,
		DepressionSeverity: constants.DassExtremelySevere,
		AnxietySeverity:    constants.DassSevere,
		StressSeverity:     constants.DassModerate,
		TakenAt:            time.Now(),
	}}

	result := engine.Calculate("student-1", metrics, nil, dass)

	if result.Score != 0 {
		t.Fatalf("score = %d, want 0 (no daily indicator triggered)", result.Score)
	}
	if result.Level != constants.EWSLevelIntervention {
		t.Fatalf("level = %s, want INTERVENTION because DASS is severe", result.Level)
	}
}

func TestCalculate_ScoreToLevelMapping(t *testing.T) {
	engine := testEngine()

	// Memicu 3 indikator: streak mood rendah (6 hari), emosi negatif jurnal,
	// dan kurang tidur.
	metrics := []studentmodels.StudentDailyMetric{
		metric(6, 1, 5, 4.0),
		metric(5, 2, 5, 4.5),
		metric(4, 1, 4, 6.0),
		metric(3, 2, 4, 6.5),
		metric(2, 1, 5, 7.0),
		metric(1, 2, 5, 7.0),
	}

	emotions := journalEmotions(constants.EmotionSad, 3, constants.EmotionAnxious, 2)

	result := engine.Calculate("student-1", metrics, emotions, nil)

	if result.Score < 3 {
		t.Fatalf("score = %d, want >= 3 (%+v)", result.Score, result.Indicators)
	}
	if result.Level != constants.EWSLevelIntervention {
		t.Fatalf("level = %s, want INTERVENTION", result.Level)
	}
}
