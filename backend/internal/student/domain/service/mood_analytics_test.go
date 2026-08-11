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

// Sebaran emosi tidak lagi dihitung dari check-in: form check-in hanya
// menanyakan skala mood, dan emosi bernama datang dari analisis jurnal (D-3).
// Pengujiannya ada di mapper.BuildEmotionDistribution / journal usecase.

func TestTopTriggers_SortedAndLimited(t *testing.T) {
	metrics := []models.StudentDailyMetric{
		checkin(5, 3, 3, 7, constants.EmotionNeutral, "Tugas kuliah"),
		checkin(4, 3, 3, 7, constants.EmotionNeutral, "Tugas kuliah"),
		checkin(3, 3, 3, 7, constants.EmotionNeutral, "Ujian (UTS/UAS)"),
		checkin(2, 3, 3, 7, constants.EmotionNeutral, "Skripsi / tugas akhir"),
		checkin(1, 3, 3, 7, constants.EmotionNeutral, ""), // tanpa pemicu
	}

	triggers := TopTriggers(metrics, 2)

	if len(triggers) != 2 {
		t.Fatalf("jumlah pemicu = %d, want 2", len(triggers))
	}
	if triggers[0].Trigger != "Tugas kuliah" || triggers[0].Count != 2 {
		t.Fatalf("pemicu teratas = %+v, want Tugas kuliah x2", triggers[0])
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
