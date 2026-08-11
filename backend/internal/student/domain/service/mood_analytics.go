package service

import (
	"sort"
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/student/data/models"
)

// ------------------------------------------------------------------
// Analitik mood milik mahasiswa sendiri.
//
// Seluruh fungsi di sini murni (tanpa I/O) dan menerima daftar check-in yang
// sudah diurutkan menaik menurut tanggal, sehingga aturan hitungnya dapat
// diuji tanpa database. Angka yang dihasilkan hanya dikonsumsi pemilik data;
// agregat lintas mahasiswa punya jalur terpisah yang melewati k-anonymity.
// ------------------------------------------------------------------

// MoodStatsMinPoints adalah jumlah titik minimum sebelum statistik ditampilkan.
// Di bawah ini, rata-rata dan grafik lebih menyesatkan daripada informatif —
// aturan yang sama dipakai EWS ("Data belum cukup", bukan "Normal").
const MoodStatsMinPoints = 3

// MoodAverages adalah rata-rata tiga metrik utama.
type MoodAverages struct {
	Mood   float64
	Stress float64
	Sleep  float64
}

// TriggerShare adalah frekuensi satu pemicu akademik.
type TriggerShare struct {
	Trigger string
	Count   int
}

// AverageMetrics menghitung rata-rata mood, stres, dan jam tidur.
// Daftar kosong menghasilkan nol — pemanggil yang memutuskan apakah nol itu
// layak ditampilkan (lihat MoodStatsMinPoints).
func AverageMetrics(metrics []models.StudentDailyMetric) MoodAverages {
	if len(metrics) == 0 {
		return MoodAverages{}
	}

	var mood, stress, sleep float64
	for _, m := range metrics {
		mood += float64(m.MoodScore)
		stress += float64(m.StressLevel)
		sleep += m.SleepHours
	}

	count := float64(len(metrics))
	return MoodAverages{
		Mood:   round2(mood / count),
		Stress: round2(stress / count),
		Sleep:  round2(sleep / count),
	}
}

// CurrentStreak menghitung rangkaian check-in berturut-turut yang masih hidup.
//
// Rangkaian dihitung mundur dari hari ini. Bila hari ini belum diisi, hitungan
// dimulai dari kemarin: rangkaian yang dibangun berminggu-minggu tidak pantas
// dinyatakan putus hanya karena mahasiswa belum sempat membuka aplikasi pagi
// ini. Rangkaian baru benar-benar putus setelah satu hari penuh terlewat.
func CurrentStreak(metrics []models.StudentDailyMetric, today time.Time) int {
	if len(metrics) == 0 {
		return 0
	}

	filled := make(map[string]bool, len(metrics))
	for _, m := range metrics {
		filled[apptime.FormatDate(m.MetricDate)] = true
	}

	cursor := apptime.StartOfDay(today)
	if !filled[apptime.FormatDate(cursor)] {
		cursor = cursor.AddDate(0, 0, -1)
	}

	streak := 0
	for filled[apptime.FormatDate(cursor)] {
		streak++
		cursor = cursor.AddDate(0, 0, -1)
	}
	return streak
}

// LongestStreak mencari rangkaian hari berurutan terpanjang pada daftar.
func LongestStreak(metrics []models.StudentDailyMetric) int {
	if len(metrics) == 0 {
		return 0
	}

	dates := make([]time.Time, 0, len(metrics))
	for _, m := range metrics {
		dates = append(dates, apptime.StartOfDay(m.MetricDate))
	}
	sort.Slice(dates, func(i, j int) bool { return dates[i].Before(dates[j]) })

	longest, current := 1, 1
	for i := 1; i < len(dates); i++ {
		gap := dates[i].Sub(dates[i-1])
		switch {
		case gap == 0:
			continue // tanggal ganda tidak menambah panjang rangkaian
		case gap <= 24*time.Hour+time.Minute:
			current++
		default:
			current = 1
		}
		if current > longest {
			longest = current
		}
	}
	return longest
}

// TopTriggers mengembalikan pemicu akademik terbanyak, maksimal limit item.
func TopTriggers(metrics []models.StudentDailyMetric, limit int) []TriggerShare {
	counts := map[string]int{}
	for _, m := range metrics {
		if m.AcademicTrigger == "" {
			continue
		}
		counts[m.AcademicTrigger]++
	}
	if len(counts) == 0 {
		return nil
	}

	shares := make([]TriggerShare, 0, len(counts))
	for trigger, count := range counts {
		shares = append(shares, TriggerShare{Trigger: trigger, Count: count})
	}
	sort.Slice(shares, func(i, j int) bool {
		if shares[i].Count != shares[j].Count {
			return shares[i].Count > shares[j].Count
		}
		return shares[i].Trigger < shares[j].Trigger
	})

	if limit > 0 && len(shares) > limit {
		shares = shares[:limit]
	}
	return shares
}

// MoodScaleLabel menerjemahkan skor mood 1..5 menjadi teks.
func MoodScaleLabel(score int) string {
	for _, option := range constants.MoodScaleOptions {
		if option.Value == score {
			return option.Label
		}
	}
	return ""
}

// StressScaleLabel menerjemahkan tingkat stres 1..5 menjadi teks.
func StressScaleLabel(level int) string {
	for _, option := range constants.StressScaleOptions {
		if option.Value == level {
			return option.Label
		}
	}
	return ""
}

func round2(v float64) float64 { return float64(int(v*100+0.5)) / 100 }
