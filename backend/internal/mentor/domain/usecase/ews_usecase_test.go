package usecase

import (
	"testing"
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
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
func metric(dayOffset, mood, stress int, sleep float64, emotion string) studentmodels.StudentDailyMetric {
	return studentmodels.StudentDailyMetric{
		MetricDate:   apptime.Today().AddDate(0, 0, -dayOffset),
		MoodScore:    mood,
		StressLevel:  stress,
		SleepHours:   sleep,
		EmotionLabel: emotion,
	}
}

func TestCalculate_InsufficientData(t *testing.T) {
	engine := testEngine()

	result := engine.Calculate("student-1", []studentmodels.StudentDailyMetric{
		metric(2, 1, 5, 4, constants.EmotionSad),
		metric(1, 1, 5, 4, constants.EmotionSad),
	}, nil)

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
		metric(5, 4, 2, 7.5, constants.EmotionCalm),
		metric(4, 4, 2, 8, constants.EmotionJoy),
		metric(3, 5, 1, 7, constants.EmotionCalm),
		metric(2, 4, 2, 7, constants.EmotionNeutral),
		metric(1, 4, 2, 7.5, constants.EmotionJoy),
	}

	result := engine.Calculate("student-1", metrics, nil)

	if result.Score != 0 || result.Level != constants.EWSLevelNormal {
		t.Fatalf("score=%d level=%s, want 0/NORMAL", result.Score, result.Level)
	}
}

func TestCalculate_LowMoodStreakNeedsMoreThanFiveDays(t *testing.T) {
	engine := testEngine()

	// Tepat 5 hari mood rendah berturut-turut: BELUM memicu (aturan "> 5 hari").
	fiveDays := []studentmodels.StudentDailyMetric{
		metric(5, 2, 3, 7, constants.EmotionNeutral),
		metric(4, 2, 3, 7, constants.EmotionNeutral),
		metric(3, 1, 3, 7, constants.EmotionNeutral),
		metric(2, 2, 3, 7, constants.EmotionNeutral),
		metric(1, 2, 3, 7, constants.EmotionNeutral),
	}
	if triggered := engine.indicatorLowMoodStreak(fiveDays).Triggered; triggered {
		t.Fatalf("5-day streak should not trigger")
	}

	sixDays := append([]studentmodels.StudentDailyMetric{metric(6, 2, 3, 7, constants.EmotionNeutral)}, fiveDays...)
	if triggered := engine.indicatorLowMoodStreak(sixDays).Triggered; !triggered {
		t.Fatalf("6-day streak should trigger")
	}
}

func TestCalculate_LowMoodStreakBrokenByMissingDay(t *testing.T) {
	engine := testEngine()

	// Ada lompatan tanggal (hari ke-4 tidak check-in) → rangkaian terputus.
	metrics := []studentmodels.StudentDailyMetric{
		metric(8, 1, 4, 6, constants.EmotionSad),
		metric(7, 1, 4, 6, constants.EmotionSad),
		metric(6, 1, 4, 6, constants.EmotionSad),
		metric(3, 1, 4, 6, constants.EmotionSad),
		metric(2, 1, 4, 6, constants.EmotionSad),
		metric(1, 1, 4, 6, constants.EmotionSad),
	}

	if triggered := engine.indicatorLowMoodStreak(metrics).Triggered; triggered {
		t.Fatalf("streak interrupted by missing days should not trigger")
	}
}

func TestCalculate_NegativeEmotionRatio(t *testing.T) {
	engine := testEngine()

	// 3 dari 4 = 75% > 60% dan memenuhi minimal 4 sampel.
	metrics := []studentmodels.StudentDailyMetric{
		metric(4, 3, 3, 7, constants.EmotionAnxious),
		metric(3, 3, 3, 7, constants.EmotionSad),
		metric(2, 3, 3, 7, constants.EmotionTired),
		metric(1, 4, 2, 7, constants.EmotionCalm),
	}

	indicator := engine.indicatorNegativeEmotion(metrics)
	if !indicator.Triggered {
		t.Fatalf("expected negative emotion indicator to trigger, got %+v", indicator)
	}

	// Sampel kurang dari 4 tidak boleh memicu walau seluruhnya negatif.
	few := metrics[:3]
	if engine.indicatorNegativeEmotion(few).Triggered {
		t.Fatalf("fewer than min samples should not trigger")
	}
}

func TestCalculate_LowSleepNights(t *testing.T) {
	engine := testEngine()

	metrics := []studentmodels.StudentDailyMetric{
		metric(4, 3, 3, 4.5, constants.EmotionTired),
		metric(3, 3, 3, 6.5, constants.EmotionNeutral),
		metric(2, 3, 3, 4.0, constants.EmotionTired),
		metric(1, 3, 3, 7.0, constants.EmotionNeutral),
	}

	if !engine.indicatorLowSleep(metrics).Triggered {
		t.Fatalf("two nights under 5 hours should trigger")
	}
}

func TestCalculate_DassSevereForcesIntervention(t *testing.T) {
	engine := testEngine()

	metrics := []studentmodels.StudentDailyMetric{
		metric(4, 4, 2, 7, constants.EmotionCalm),
		metric(3, 4, 2, 7, constants.EmotionJoy),
		metric(2, 4, 2, 7, constants.EmotionCalm),
		metric(1, 5, 1, 8, constants.EmotionJoy),
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

	result := engine.Calculate("student-1", metrics, dass)

	if result.Score != 0 {
		t.Fatalf("score = %d, want 0 (no daily indicator triggered)", result.Score)
	}
	if result.Level != constants.EWSLevelIntervention {
		t.Fatalf("level = %s, want INTERVENTION because DASS is severe", result.Level)
	}
}

func TestCalculate_ScoreToLevelMapping(t *testing.T) {
	engine := testEngine()

	// Memicu 3 indikator: streak mood rendah (6 hari), emosi negatif, kurang tidur.
	metrics := []studentmodels.StudentDailyMetric{
		metric(6, 1, 5, 4.0, constants.EmotionSad),
		metric(5, 2, 5, 4.5, constants.EmotionAnxious),
		metric(4, 1, 4, 6.0, constants.EmotionSad),
		metric(3, 2, 4, 6.5, constants.EmotionTired),
		metric(2, 1, 5, 7.0, constants.EmotionSad),
		metric(1, 2, 5, 7.0, constants.EmotionAnxious),
	}

	result := engine.Calculate("student-1", metrics, nil)

	if result.Score < 3 {
		t.Fatalf("score = %d, want >= 3 (%+v)", result.Score, result.Indicators)
	}
	if result.Level != constants.EWSLevelIntervention {
		t.Fatalf("level = %s, want INTERVENTION", result.Level)
	}
}
