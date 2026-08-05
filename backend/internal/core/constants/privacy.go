package constants

// ShareLevel adalah tingkat berbagi data mahasiswa ke Dosen Pembimbing.
// Enforcement dilakukan di server-side (usecase mentor), bukan di client.
type ShareLevel string

const (
	// ShareLevelClosed (Tertutup): backend mengembalikan indikator NULL/kosong.
	ShareLevelClosed ShareLevel = "CLOSED"
	// ShareLevelSummary (Ringkasan): hanya indikator kondisi, tanpa tren.
	ShareLevelSummary ShareLevel = "SUMMARY"
	// ShareLevelSummaryTrend (Ringkasan + Tren): indikator + grafik tren mingguan.
	ShareLevelSummaryTrend ShareLevel = "SUMMARY_TREND"
)

var AllShareLevels = []ShareLevel{ShareLevelClosed, ShareLevelSummary, ShareLevelSummaryTrend}

func (s ShareLevel) String() string { return string(s) }

func (s ShareLevel) IsValid() bool {
	for _, v := range AllShareLevels {
		if v == s {
			return true
		}
	}
	return false
}

// AllowsIndicator: apakah dosen boleh melihat indikator kondisi sama sekali.
func (s ShareLevel) AllowsIndicator() bool {
	return s == ShareLevelSummary || s == ShareLevelSummaryTrend
}

// AllowsTrend: apakah dosen boleh melihat grafik tren mingguan.
func (s ShareLevel) AllowsTrend() bool { return s == ShareLevelSummaryTrend }

// EWSLevel adalah status Early Warning System yang dihitung server.
type EWSLevel string

const (
	EWSLevelInsufficient EWSLevel = "INSUFFICIENT_DATA" // "Data belum cukup"
	EWSLevelNormal       EWSLevel = "NORMAL"            // score 0
	EWSLevelWatch        EWSLevel = "WATCH"             // score 1 - Waspada
	EWSLevelRisk         EWSLevel = "RISK"              // score 2 - Risiko
	EWSLevelIntervention EWSLevel = "INTERVENTION"      // score >=3 atau DASS-21 Severe
)

var ewsLevelLabel = map[EWSLevel]string{
	EWSLevelInsufficient: "Data belum cukup",
	EWSLevelNormal:       "Normal",
	EWSLevelWatch:        "Waspada",
	EWSLevelRisk:         "Risiko",
	EWSLevelIntervention: "Perlu Intervensi",
}

func (l EWSLevel) String() string { return string(l) }

func (l EWSLevel) Label() string { return ewsLevelLabel[l] }

// Priority dipakai untuk sorting daftar bimbingan (tinggi = tampil di atas).
func (l EWSLevel) Priority() int {
	switch l {
	case EWSLevelIntervention:
		return 4
	case EWSLevelRisk:
		return 3
	case EWSLevelWatch:
		return 2
	case EWSLevelNormal:
		return 1
	default:
		return 0
	}
}

// EWSLevelFromScore memetakan skor indikator (0-4) ke level.
// dassSevere memaksa level INTERVENTION sesuai aturan klinis dokumen Sanctuary.
func EWSLevelFromScore(score int, dassSevere bool) EWSLevel {
	if dassSevere || score >= 3 {
		return EWSLevelIntervention
	}
	switch {
	case score >= 2:
		return EWSLevelRisk
	case score == 1:
		return EWSLevelWatch
	default:
		return EWSLevelNormal
	}
}

// Kode indikator EWS (dipakai pada kolom jsonb early_warning_logs.indicators).
const (
	IndicatorLowMoodStreak   = "LOW_MOOD_STREAK"
	IndicatorNegativeEmotion = "NEGATIVE_EMOTION_RATIO"
	IndicatorDassWorsening   = "DASS_WORSENING"
	IndicatorLowSleep        = "LOW_SLEEP_NIGHTS"
)

// DASS-21 severity.
type DassSeverity string

const (
	DassNormal          DassSeverity = "NORMAL"
	DassMild            DassSeverity = "MILD"
	DassModerate        DassSeverity = "MODERATE"
	DassSevere          DassSeverity = "SEVERE"
	DassExtremelySevere DassSeverity = "EXTREMELY_SEVERE"
)

// IsSevere dipakai EWS engine sebagai pemicu langsung "Perlu Intervensi".
func (d DassSeverity) IsSevere() bool {
	return d == DassSevere || d == DassExtremelySevere
}

// Label emosi hasil analisis jurnal (mock analyzer saat ini).
const (
	EmotionJoy     = "JOY"
	EmotionCalm    = "CALM"
	EmotionNeutral = "NEUTRAL"
	EmotionSad     = "SAD"
	EmotionAnxious = "ANXIOUS"
	EmotionAngry   = "ANGRY"
	EmotionTired   = "TIRED"
)

// NegativeEmotions dipakai indikator EWS #2.
var NegativeEmotions = map[string]bool{
	EmotionSad:     true,
	EmotionAnxious: true,
	EmotionAngry:   true,
	EmotionTired:   true,
}

func IsNegativeEmotion(label string) bool { return NegativeEmotions[label] }
