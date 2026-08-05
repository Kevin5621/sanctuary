package service

import (
	"testing"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/student/data/models"
)

// checkin membangun satu check-in berjarak dayOffset hari dari hari ini.
func checkin(dayOffset, mood, stress int, sleep float64, emotion, trigger string) models.StudentDailyMetric {
	return models.StudentDailyMetric{
		MetricDate:      apptime.DaysAgo(dayOffset),
		MoodScore:       mood,
		StressLevel:     stress,
		SleepHours:      sleep,
		EmotionLabel:    emotion,
		AcademicTrigger: trigger,
	}
}

func TestAverageMetrics(t *testing.T) {
	metrics := []models.StudentDailyMetric{
		checkin(2, 4, 2, 7.0, constants.EmotionCalm, ""),
		checkin(1, 2, 4, 5.0, constants.EmotionSad, ""),
	}

	averages := AverageMetrics(metrics)

	if averages.Mood != 3 {
		t.Errorf("rata-rata mood = %v, want 3", averages.Mood)
	}
	if averages.Stress != 3 {
		t.Errorf("rata-rata stres = %v, want 3", averages.Stress)
	}
	if averages.Sleep != 6 {
		t.Errorf("rata-rata tidur = %v, want 6", averages.Sleep)
	}
}

func TestAverageMetrics_EmptyReturnsZero(t *testing.T) {
	if averages := AverageMetrics(nil); averages.Mood != 0 {
		t.Fatalf("daftar kosong harus menghasilkan nol, dapat %v", averages.Mood)
	}
}

func TestCurrentStreak_CountsBackFromToday(t *testing.T) {
	metrics := []models.StudentDailyMetric{
		checkin(2, 4, 2, 7, constants.EmotionCalm, ""),
		checkin(1, 4, 2, 7, constants.EmotionCalm, ""),
		checkin(0, 4, 2, 7, constants.EmotionCalm, ""),
	}

	if got := CurrentStreak(metrics, apptime.Today()); got != 3 {
		t.Fatalf("streak = %d, want 3", got)
	}
}

// Rangkaian tidak boleh dinyatakan putus hanya karena mahasiswa belum sempat
// check-in pagi ini — aturan ini yang membuat streak terasa adil.
func TestCurrentStreak_TodayNotYetFilledStillCounts(t *testing.T) {
	metrics := []models.StudentDailyMetric{
		checkin(3, 4, 2, 7, constants.EmotionCalm, ""),
		checkin(2, 4, 2, 7, constants.EmotionCalm, ""),
		checkin(1, 4, 2, 7, constants.EmotionCalm, ""),
	}

	if got := CurrentStreak(metrics, apptime.Today()); got != 3 {
		t.Fatalf("streak = %d, want 3", got)
	}
}

func TestCurrentStreak_BreaksAfterAFullMissedDay(t *testing.T) {
	metrics := []models.StudentDailyMetric{
		checkin(4, 4, 2, 7, constants.EmotionCalm, ""),
		checkin(3, 4, 2, 7, constants.EmotionCalm, ""),
		// hari ke-2 terlewat
		checkin(1, 4, 2, 7, constants.EmotionCalm, ""),
	}

	if got := CurrentStreak(metrics, apptime.Today()); got != 1 {
		t.Fatalf("streak = %d, want 1 (rangkaian sebelum lubang tidak ikut)", got)
	}
}

func TestCurrentStreak_EmptyIsZero(t *testing.T) {
	if got := CurrentStreak(nil, apptime.Today()); got != 0 {
		t.Fatalf("streak = %d, want 0", got)
	}
}

func TestLongestStreak_IgnoresGaps(t *testing.T) {
	metrics := []models.StudentDailyMetric{
		checkin(10, 4, 2, 7, constants.EmotionCalm, ""),
		checkin(9, 4, 2, 7, constants.EmotionCalm, ""),
		checkin(8, 4, 2, 7, constants.EmotionCalm, ""),
		checkin(8-4, 4, 2, 7, constants.EmotionCalm, ""), // lubang 3 hari
		checkin(3, 4, 2, 7, constants.EmotionCalm, ""),
	}

	if got := LongestStreak(metrics); got != 3 {
		t.Fatalf("rangkaian terpanjang = %d, want 3", got)
	}
}

func TestEmotionShares_SkipsUnlabelledDays(t *testing.T) {
	metrics := []models.StudentDailyMetric{
		checkin(3, 2, 4, 6, constants.EmotionSad, ""),
		checkin(2, 2, 4, 6, constants.EmotionSad, ""),
		checkin(1, 4, 2, 7, constants.EmotionCalm, ""),
		checkin(0, 4, 2, 7, "", ""), // tanpa label, tidak ikut dihitung
	}

	shares := EmotionShares(metrics)

	if len(shares) != 2 {
		t.Fatalf("jumlah label = %d, want 2", len(shares))
	}
	if shares[0].Emotion != constants.EmotionSad || shares[0].Count != 2 {
		t.Fatalf("label teratas = %+v, want SAD x2", shares[0])
	}
	// Persentase dihitung dari hari BERLABEL (3), bukan total check-in (4).
	if shares[0].Percentage != 66.67 {
		t.Fatalf("persentase = %v, want 66.67", shares[0].Percentage)
	}
	if !shares[0].IsNegative {
		t.Error("SAD harus ditandai sebagai emosi negatif")
	}
}

func TestEmotionShares_NoLabelsReturnsNil(t *testing.T) {
	metrics := []models.StudentDailyMetric{checkin(1, 3, 3, 7, "", "")}
	if shares := EmotionShares(metrics); shares != nil {
		t.Fatalf("tanpa label harus nil, dapat %v", shares)
	}
}

func TestTopTriggers_SortedAndLimited(t *testing.T) {
	metrics := []models.StudentDailyMetric{
		checkin(5, 3, 3, 7, constants.EmotionNeutral, constants.TriggerAssignment),
		checkin(4, 3, 3, 7, constants.EmotionNeutral, constants.TriggerAssignment),
		checkin(3, 3, 3, 7, constants.EmotionNeutral, constants.TriggerExam),
		checkin(2, 3, 3, 7, constants.EmotionNeutral, constants.TriggerThesis),
		checkin(1, 3, 3, 7, constants.EmotionNeutral, ""), // tanpa pemicu
	}

	triggers := TopTriggers(metrics, 2)

	if len(triggers) != 2 {
		t.Fatalf("jumlah pemicu = %d, want 2", len(triggers))
	}
	if triggers[0].Trigger != constants.TriggerAssignment || triggers[0].Count != 2 {
		t.Fatalf("pemicu teratas = %+v, want TUGAS x2", triggers[0])
	}
}

func TestScaleLabels(t *testing.T) {
	if MoodScaleLabel(5) == "" {
		t.Error("skor mood 5 harus punya label")
	}
	if StressScaleLabel(1) == "" {
		t.Error("tingkat stres 1 harus punya label")
	}
	if MoodScaleLabel(9) != "" {
		t.Error("skor di luar skala tidak boleh mengarang label")
	}
}
