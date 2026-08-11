package seeders

import (
	"sort"
	"testing"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	mentorusecase "github.com/gilabs/sanctuary/internal/mentor/domain/usecase"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
	studentrepo "github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

// ExpectedLevel pada setiap conditionProfile adalah janji kepada QA: akun demo
// ini akan terlihat sebagai level tersebut di layar dosen. Selama ini janji itu
// hanya berupa komentar, sehingga perubahan pada data demo — atau pada mesin
// EWS — bisa membatalkannya tanpa ada yang tahu.
//
// Pengujian ini menjalankan mesin EWS yang sesungguhnya atas data yang benar-
// benar ditulis seeder: check-in dari profil, dan emosi dari analyzer yang
// membaca jurnal (tulisan tangan + latar), persis seperti seedJournals.
//
// Ia menjadi penting setelah indikator #2 dikembalikan ke sumber D-3 (analisis
// jurnal). Sejak itu jumlah dan urutan jurnal latar ikut menentukan level akun
// demo, dan itu tidak terlihat dari membaca profiles.go saja.
func TestDemoProfilesMatchExpectedEWSLevel(t *testing.T) {
	if len(demoProfiles) != len(studentSpecs) {
		t.Fatalf("profil demo (%d) dan mahasiswa demo (%d) tidak sepadan",
			len(demoProfiles), len(studentSpecs))
	}

	engine := mentorusecase.NewEWSUsecase(nil, nil, nil, nil, defaultEWSConfig())
	analyzer := service.NewEmotionAnalyzer()

	for i, profile := range demoProfiles {
		t.Run(profile.Key, func(t *testing.T) {
			// ID mahasiswa bersifat deterministik, dan sebaran jurnal latar
			// diturunkan darinya — memakai id yang sama dengan seeder membuat
			// pengujian ini menilai data yang benar-benar masuk basis data.
			studentID := deterministicID("user:" + studentSpecs[i].Email)

			result := engine.Calculate(
				studentID,
				seededMetricsInWindow(studentID, profile),
				seededJournalEmotions(analyzer, studentID, profile),
				seededDassResults(profile),
			)

			if result.Level != profile.ExpectedLevel {
				t.Fatalf("level = %s, want %s (skor %d, indikator %+v)",
					result.Level, profile.ExpectedLevel, result.Score, result.Indicators)
			}
		})
	}
}

// defaultEWSConfig menyalin nilai default config.Load agar ambang yang diuji
// adalah ambang yang dipakai aplikasi saat dijalankan tanpa env khusus.
func defaultEWSConfig() config.EWSConfig {
	return config.EWSConfig{
		LookbackDays:           14,
		MinDataPoints:          4,
		LowMoodThreshold:       2,
		LowMoodMinStreakDays:   5,
		NegativeEmotionRatio:   0.6,
		NegativeEmotionSamples: 4,
		LowSleepHours:          5,
		LowSleepMinNights:      2,
	}
}

// seededMetricsInWindow meniru ListByUserRange: hanya check-in pada jendela EWS,
// urut menaik menurut tanggal (indikator rangkaian bergantung pada urutan itu).
func seededMetricsInWindow(studentID string, profile conditionProfile) []studentmodels.StudentDailyMetric {
	from := apptime.DaysAgo(defaultEWSConfig().LookbackDays)

	all := append(buildRecentMetrics(studentID, profile), buildBaselineMetrics(studentID, profile)...)
	metrics := make([]studentmodels.StudentDailyMetric, 0, len(all))
	for _, m := range all {
		if !m.MetricDate.Before(from) {
			metrics = append(metrics, m)
		}
	}

	sort.Slice(metrics, func(i, j int) bool { return metrics[i].MetricDate.Before(metrics[j].MetricDate) })
	return metrics
}

// seededJournalEmotions meniru JournalRepository.EmotionDistributionForUser:
// hanya jurnal teranalisis di dalam jendela, dihitung per label.
func seededJournalEmotions(
	analyzer service.EmotionAnalyzer,
	studentID string,
	profile conditionProfile,
) []studentrepo.EmotionCount {
	lookback := defaultEWSConfig().LookbackDays

	counts := map[string]int{}
	for _, seed := range append(profile.Journals, backgroundJournals(studentID, profile)...) {
		if !seed.Analyzed || seed.DaysAgo > lookback {
			continue
		}
		counts[analyzer.Analyze(seed.Content).EmotionLabel]++
	}

	out := make([]studentrepo.EmotionCount, 0, len(counts))
	for label, total := range counts {
		out = append(out, studentrepo.EmotionCount{EmotionLabel: label, Total: total})
	}
	return out
}

// seededDassResults meniru LatestTwoForUser: hasil terbaru lebih dulu.
func seededDassResults(profile conditionProfile) []studentmodels.Dass21Result {
	results := make([]studentmodels.Dass21Result, 0, len(profile.Dass))
	for _, seed := range profile.Dass {
		score := service.ScoreDass21(buildDassAnswers(seed))
		results = append(results, studentmodels.Dass21Result{
			DepressionScore:    score.Depression.Score,
			AnxietyScore:       score.Anxiety.Score,
			StressScore:        score.Stress.Score,
			DepressionSeverity: score.Depression.Severity,
			AnxietySeverity:    score.Anxiety.Severity,
			StressSeverity:     score.Stress.Severity,
			TakenAt:            apptime.DaysAgo(seed.DaysAgo),
		})
	}

	sort.Slice(results, func(i, j int) bool { return results[i].TakenAt.After(results[j].TakenAt) })
	return results
}
