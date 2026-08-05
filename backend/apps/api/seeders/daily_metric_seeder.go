package seeders

import (
	"context"
	"fmt"
	"hash/fnv"
	"math/rand"
	"time"

	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
)

// baselineTriggers dipakai data latar. Daftarnya sengaja lebih sempit daripada
// constants.AcademicTriggerOptions agar sebaran pemicu punya pemenang yang
// jelas — kartu "pemicu tersering" jadi ada isinya.
var baselineTriggers = []string{
	constants.TriggerAssignment,
	constants.TriggerExam,
	constants.TriggerThesis,
	"", // sebagian hari memang tanpa pemicu tertentu
}

// seedDailyMetrics mengisi riwayat check-in mood.
//
// Dua lapis, sesuai catatan di profiles.go: 14 hari terakhir memakai deret
// yang ditulis tangan (agar EWS dapat diprediksi), dan hari ke-15 hingga ke-90
// dibangkitkan deterministik dari id mahasiswa (agar kalender bulanan dan
// grafik 30 hari punya isi tanpa mengganggu hasil EWS).
func (s *Seeder) seedDailyMetrics(ctx context.Context, studentID string, profile conditionProfile) error {
	metrics := make([]studentmodels.StudentDailyMetric, 0, metricHistoryDays)
	metrics = append(metrics, buildRecentMetrics(studentID, profile)...)
	metrics = append(metrics, buildBaselineMetrics(studentID, profile)...)

	if len(metrics) == 0 {
		return nil
	}

	return s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "user_id"}, {Name: "metric_date"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"mood_score", "stress_level", "sleep_hours", "academic_trigger", "emotion_label", "updated_at",
		}),
	}).CreateInBatches(&metrics, 100).Error
}

// buildRecentMetrics menulis jendela yang dibaca EWS.
// index 0 = hari terlama, index terakhir = kemarin.
func buildRecentMetrics(studentID string, profile conditionProfile) []studentmodels.StudentDailyMetric {
	days := len(profile.Moods)
	metrics := make([]studentmodels.StudentDailyMetric, 0, days+1)

	triggers := []string{
		constants.TriggerAssignment,
		constants.TriggerExam,
		constants.TriggerThesis,
		constants.TriggerPresentation,
		"",
	}

	for i := range days {
		date := apptime.DaysAgo(days - i)
		metrics = append(metrics, newMetric(studentID, date,
			profile.Moods[i], profile.Stress[i], profile.Sleep[i],
			profile.Emotions[i], triggers[i%len(triggers)],
		))
	}

	if profile.FilledToday && days > 0 {
		last := days - 1
		metrics = append(metrics, newMetric(studentID, apptime.Today(),
			profile.Moods[last], profile.Stress[last], profile.Sleep[last],
			profile.Emotions[last], constants.TriggerAssignment,
		))
	}
	return metrics
}

// buildBaselineMetrics membangkitkan data latar di luar jendela EWS.
//
// Sumber acaknya diturunkan dari id mahasiswa, sehingga menjalankan seeder
// berulang kali menghasilkan riwayat yang sama persis — syarat agar data demo
// dapat dipakai sebagai acuan pengujian.
func buildBaselineMetrics(studentID string, profile conditionProfile) []studentmodels.StudentDailyMetric {
	if profile.BaselineDays <= recentWindowDays || len(profile.BaselineEmotions) == 0 {
		return nil
	}

	rng := rand.New(rand.NewSource(int64(hashString(studentID))))
	metrics := make([]studentmodels.StudentDailyMetric, 0, profile.BaselineDays)

	// Mulai satu hari setelah jendela terkini agar tidak ada tabrakan tanggal.
	for daysAgo := len(profile.Moods) + 1; daysAgo <= profile.BaselineDays; daysAgo++ {
		if rng.Float64() > profile.BaselineFillRate {
			continue // hari terlewat — kalender memang tidak selalu penuh
		}

		mood := clampInt(profile.BaselineMood+rng.Intn(3)-1, constants.MoodScoreMin, constants.MoodScoreMax)
		stress := clampInt(profile.BaselineStress+rng.Intn(3)-1, constants.StressLevelMin, constants.StressLevelMax)
		sleep := roundHalf(profile.BaselineSleep + float64(rng.Intn(5)-2)*0.5)

		metrics = append(metrics, newMetric(studentID, apptime.DaysAgo(daysAgo),
			mood, stress, sleep,
			profile.BaselineEmotions[rng.Intn(len(profile.BaselineEmotions))],
			baselineTriggers[rng.Intn(len(baselineTriggers))],
		))
	}
	return metrics
}

func newMetric(
	studentID string,
	date time.Time,
	mood, stress int,
	sleep float64,
	emotion, trigger string,
) studentmodels.StudentDailyMetric {
	metric := studentmodels.StudentDailyMetric{
		UserID:          studentID,
		MetricDate:      date,
		MoodScore:       mood,
		StressLevel:     stress,
		SleepHours:      sleep,
		EmotionLabel:    emotion,
		AcademicTrigger: trigger,
	}
	metric.ID = deterministicID(fmt.Sprintf("metric:%s:%s", studentID, apptime.FormatDate(date)))
	return metric
}

func hashString(s string) uint32 {
	h := fnv.New32a()
	_, _ = h.Write([]byte(s))
	return h.Sum32()
}

func clampInt(v, min, max int) int {
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}

// roundHalf menjaga jam tidur pada kelipatan 0,5 dan dalam rentang yang wajar
// (kolomnya numeric(3,1) dengan CHECK 0..24).
func roundHalf(v float64) float64 {
	if v < 3 {
		v = 3
	}
	if v > 10 {
		v = 10
	}
	return float64(int(v*2+0.5)) / 2
}
