package mapper

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

func ToDailyMetricResponse(m models.StudentDailyMetric) dto.DailyMetricResponse {
	return dto.DailyMetricResponse{
		Date:             apptime.FormatDate(m.MetricDate),
		MoodScore:        m.MoodScore,
		MoodLabel:        service.MoodScaleLabel(m.MoodScore),
		StressLevel:      m.StressLevel,
		StressLabel:      service.StressScaleLabel(m.StressLevel),
		SleepHours:       m.SleepHours,
		EmotionLabel:     m.EmotionLabel,
		EmotionLabelText: service.EmotionLabelText(m.EmotionLabel),
		AcademicTrigger:  m.AcademicTrigger,
	}
}

func toDailyMetricResponses(metrics []models.StudentDailyMetric) []dto.DailyMetricResponse {
	out := make([]dto.DailyMetricResponse, 0, len(metrics))
	for i := range metrics {
		out = append(out, ToDailyMetricResponse(metrics[i]))
	}
	return out
}

// ToWeeklyMoodSummary menyusun ringkasan Senin–Minggu dari daftar check-in
// yang sudah ada (bisa kurang dari 7 baris bila ada hari yang terlewat).
//
// streakMetrics adalah rentang yang lebih panjang dari satu minggu, karena
// rangkaian check-in bisa bermula sebelum hari Senin minggu ini.
func ToWeeklyMoodSummary(
	weekStart, weekEnd time.Time,
	metrics []models.StudentDailyMetric,
	streakMetrics []models.StudentDailyMetric,
) dto.WeeklyMoodSummaryResponse {
	days := toDailyMetricResponses(metrics)

	var today *dto.DailyMetricResponse
	todayDate := apptime.FormatDate(apptime.Today())
	for i := range days {
		if days[i].Date == todayDate {
			copied := days[i]
			today = &copied
			break
		}
	}

	return dto.WeeklyMoodSummaryResponse{
		WeekStart:     apptime.FormatDate(weekStart),
		WeekEnd:       apptime.FormatDate(weekEnd),
		Today:         today,
		Days:          days,
		CheckinCount:  len(days),
		CurrentStreak: service.CurrentStreak(streakMetrics, apptime.Today()),
	}
}

// ToDailyMetricOptions menyusun seluruh pilihan check-in beserta batas backdate.
func ToDailyMetricOptions(maxBackdateDays int) dto.DailyMetricOptionsResponse {
	moodScale := make([]dto.ScaleOptionResponse, 0, len(constants.MoodScaleOptions))
	for _, option := range constants.MoodScaleOptions {
		moodScale = append(moodScale, dto.ScaleOptionResponse{Value: option.Value, Label: option.Label})
	}

	stressScale := make([]dto.ScaleOptionResponse, 0, len(constants.StressScaleOptions))
	for _, option := range constants.StressScaleOptions {
		stressScale = append(stressScale, dto.ScaleOptionResponse{Value: option.Value, Label: option.Label})
	}

	emotions := make([]dto.CodedOptionResponse, 0, len(constants.EmotionCheckinOptions))
	for _, option := range constants.EmotionCheckinOptions {
		emotions = append(emotions, dto.CodedOptionResponse{Value: option.Value, Label: option.Label})
	}

	return dto.DailyMetricOptionsResponse{
		MoodScale:       moodScale,
		StressScale:     stressScale,
		Emotions:        emotions,
		MaxBackdateDays: maxBackdateDays,
	}
}

// ToMonthlyMood menyusun kalender mood satu bulan penuh.
func ToMonthlyMood(month time.Time, metrics []models.StudentDailyMetric) dto.MonthlyMoodResponse {
	first := apptime.StartOfMonth(month)
	last := apptime.EndOfMonth(month)
	averages := service.AverageMetrics(metrics)

	return dto.MonthlyMoodResponse{
		Month:        apptime.FormatMonth(first),
		MonthLabel:   apptime.FormatMonthLabel(first),
		FirstDate:    apptime.FormatDate(first),
		LastDate:     apptime.FormatDate(last),
		DaysInMonth:  apptime.DaysInMonth(first),
		Days:         toDailyMetricResponses(metrics),
		CheckinCount: len(metrics),
		AvgMood:      averages.Mood,
		HasNextMonth: last.Before(apptime.Today()),
	}
}

// ToMoodStats menyusun statistik periode untuk tab Mood.
//
// Di bawah service.MoodStatsMinPoints titik data, response tetap 200 tetapi
// IsSufficient=false dan tanpa angka rata-rata — pola yang sama dengan
// k-anonymity dan EWS: lebih baik mengatakan "belum cukup" daripada
// menampilkan angka yang terlihat pasti padahal tidak.
func ToMoodStats(periodDays int, from, to time.Time, metrics []models.StudentDailyMetric) dto.MoodStatsResponse {
	response := dto.MoodStatsResponse{
		PeriodDays:   periodDays,
		From:         apptime.FormatDate(from),
		To:           apptime.FormatDate(to),
		Points:       make([]dto.MoodTrendPoint, 0, len(metrics)),
		CheckinCount: len(metrics),
	}

	for _, m := range metrics {
		response.Points = append(response.Points, dto.MoodTrendPoint{
			Date:        apptime.FormatDate(m.MetricDate),
			MoodScore:   m.MoodScore,
			StressLevel: m.StressLevel,
			SleepHours:  m.SleepHours,
		})
	}

	if len(metrics) < service.MoodStatsMinPoints {
		response.Message = "Data belum cukup untuk menampilkan pola. Lanjutkan check-in beberapa hari lagi."
		return response
	}

	averages := service.AverageMetrics(metrics)
	response.IsSufficient = true
	response.AvgMood = averages.Mood
	response.AvgStress = averages.Stress
	response.AvgSleepHours = averages.Sleep
	response.CurrentStreak = service.CurrentStreak(metrics, apptime.Today())
	response.LongestStreak = service.LongestStreak(metrics)

	for _, share := range service.EmotionShares(metrics) {
		response.EmotionDistribution = append(response.EmotionDistribution, dto.EmotionShareResponse{
			Emotion:    share.Emotion,
			Label:      service.EmotionLabelText(share.Emotion),
			Count:      share.Count,
			Percentage: share.Percentage,
			IsNegative: share.IsNegative,
		})
	}

	for _, share := range service.TopTriggers(metrics, 3) {
		response.TopTriggers = append(response.TopTriggers, dto.TriggerShareResponse{
			Trigger: share.Trigger,
			Label:   constants.AcademicTriggerLabel(share.Trigger),
			Count:   share.Count,
		})
	}

	return response
}
