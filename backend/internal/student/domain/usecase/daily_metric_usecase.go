package usecase

import (
	"context"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/mapper"
)

// DailyMetricUsecase melayani ringkasan check-in mood milik mahasiswa
// sendiri — dipakai kartu "Ringkasan Hari Ini" & "Kalender Mood Mingguan"
// pada Beranda. Hanya data kuantitatif (mood/stres/tidur); tidak ada konten
// jurnal bebas di sini.
type DailyMetricUsecase interface {
	WeeklySummary(ctx context.Context, userID string) (dto.WeeklyMoodSummaryResponse, error)
	SaveMetric(ctx context.Context, userID string, req dto.SaveDailyMetricRequest) (dto.DailyMetricResponse, error)
}

type dailyMetricUsecase struct {
	repo repositories.DailyMetricRepository
}

func NewDailyMetricUsecase(repo repositories.DailyMetricRepository) DailyMetricUsecase {
	return &dailyMetricUsecase{repo: repo}
}

func (u *dailyMetricUsecase) WeeklySummary(ctx context.Context, userID string) (dto.WeeklyMoodSummaryResponse, error) {
	weekStart := apptime.StartOfWeek(apptime.Today())
	weekEnd := apptime.EndOfWeek(apptime.Today())

	metrics, err := u.repo.ListByUserRange(ctx, userID, weekStart, weekEnd)
	if err != nil {
		return dto.WeeklyMoodSummaryResponse{}, err
	}

	return mapper.ToWeeklyMoodSummary(weekStart, weekEnd, metrics), nil
}

func (u *dailyMetricUsecase) SaveMetric(ctx context.Context, userID string, req dto.SaveDailyMetricRequest) (dto.DailyMetricResponse, error) {
	metricDate := apptime.Today()
	if req.MetricDate != "" {
		if parsed, err := apptime.ParseDate(req.MetricDate); err == nil {
			metricDate = parsed
		}
	}

	metric := models.StudentDailyMetric{
		UserID:          userID,
		MetricDate:      metricDate,
		MoodScore:       req.MoodScore,
		StressLevel:     req.StressLevel,
		SleepHours:      req.SleepHours,
		EmotionLabel:    req.EmotionLabel,
		AcademicTrigger: req.AcademicTrigger,
	}

	if err := u.repo.Upsert(ctx, &metric); err != nil {
		return dto.DailyMetricResponse{}, err
	}

	return mapper.ToDailyMetricResponse(metric), nil
}

