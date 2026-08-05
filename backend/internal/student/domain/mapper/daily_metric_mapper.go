package mapper

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

func ToDailyMetricResponse(m models.StudentDailyMetric) dto.DailyMetricResponse {
	return dto.DailyMetricResponse{
		Date:             apptime.FormatDate(m.MetricDate),
		MoodScore:        m.MoodScore,
		StressLevel:      m.StressLevel,
		SleepHours:       m.SleepHours,
		EmotionLabel:     m.EmotionLabel,
		EmotionLabelText: service.EmotionLabelText(m.EmotionLabel),
		AcademicTrigger:  m.AcademicTrigger,
	}
}

// ToWeeklyMoodSummary menyusun ringkasan Senin–Minggu dari daftar check-in
// yang sudah ada (bisa kurang dari 7 baris bila ada hari yang terlewat).
func ToWeeklyMoodSummary(weekStart, weekEnd time.Time, metrics []models.StudentDailyMetric) dto.WeeklyMoodSummaryResponse {
	days := make([]dto.DailyMetricResponse, 0, len(metrics))
	var today *dto.DailyMetricResponse

	todayDate := apptime.FormatDate(apptime.Today())
	for i := range metrics {
		item := ToDailyMetricResponse(metrics[i])
		days = append(days, item)
		if item.Date == todayDate {
			copied := item
			today = &copied
		}
	}

	return dto.WeeklyMoodSummaryResponse{
		WeekStart: apptime.FormatDate(weekStart),
		WeekEnd:   apptime.FormatDate(weekEnd),
		Today:     today,
		Days:      days,
	}
}
