package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/mapper"
)

// streakLookbackDays adalah jendela yang dibaca untuk menghitung rangkaian
// check-in. Cukup panjang agar rangkaian panjang tetap terhitung, tetapi
// tetap terbatas supaya query tidak tumbuh seiring umur akun.
const streakLookbackDays = 120

// DailyMetricUsecase melayani check-in mood dan riwayatnya — seluruhnya milik
// mahasiswa sendiri. Hanya data kuantitatif (mood/stres/tidur/emosi terpilih);
// tidak ada konten jurnal bebas di sini.
type DailyMetricUsecase interface {
	Options(ctx context.Context) dto.DailyMetricOptionsResponse
	WeeklySummary(ctx context.Context, userID string) (dto.WeeklyMoodSummaryResponse, error)
	Monthly(ctx context.Context, userID, month string) (dto.MonthlyMoodResponse, error)
	Stats(ctx context.Context, userID string, periodDays int) (dto.MoodStatsResponse, error)
	SaveMetric(ctx context.Context, userID string, req dto.SaveDailyMetricRequest) (dto.DailyMetricResponse, error)
}

type dailyMetricUsecase struct {
	repo repositories.DailyMetricRepository
	cfg  config.StudentConfig
}

func NewDailyMetricUsecase(repo repositories.DailyMetricRepository, cfg config.StudentConfig) DailyMetricUsecase {
	return &dailyMetricUsecase{repo: repo, cfg: cfg}
}

func (u *dailyMetricUsecase) Options(context.Context) dto.DailyMetricOptionsResponse {
	return mapper.ToDailyMetricOptions(u.cfg.MaxBackdateDays)
}

func (u *dailyMetricUsecase) WeeklySummary(ctx context.Context, userID string) (dto.WeeklyMoodSummaryResponse, error) {
	today := apptime.Today()
	weekStart := apptime.StartOfWeek(today)
	weekEnd := apptime.EndOfWeek(today)

	// Satu query rentang panjang, lalu minggu berjalan disaring di memori:
	// rangkaian check-in kerap bermula sebelum Senin, dan dua query terpisah
	// akan membaca baris yang sama dua kali.
	streakMetrics, err := u.repo.ListByUserRange(ctx, userID, apptime.DaysAgo(streakLookbackDays), today)
	if err != nil {
		return dto.WeeklyMoodSummaryResponse{}, err
	}

	week := make([]models.StudentDailyMetric, 0, 7)
	for _, m := range streakMetrics {
		date := apptime.StartOfDay(m.MetricDate)
		if !date.Before(weekStart) && !date.After(weekEnd) {
			week = append(week, m)
		}
	}

	return mapper.ToWeeklyMoodSummary(weekStart, weekEnd, week, streakMetrics), nil
}

func (u *dailyMetricUsecase) Monthly(ctx context.Context, userID, month string) (dto.MonthlyMoodResponse, error) {
	target := apptime.StartOfMonth(apptime.Today())
	if month != "" {
		parsed, err := apptime.ParseMonth(month)
		if err != nil {
			return dto.MonthlyMoodResponse{}, utils.NewErrorWithMessage(
				utils.CodeInvalidQueryParam, "Parameter month harus berformat YYYY-MM",
			)
		}
		target = apptime.StartOfMonth(parsed)
	}

	// Bulan di masa depan pasti kosong; menolaknya lebih jujur daripada
	// mengembalikan kalender kosong yang terlihat seperti data hilang.
	if target.After(apptime.StartOfMonth(apptime.Today())) {
		return dto.MonthlyMoodResponse{}, utils.NewError(utils.CodeFutureDateNotAllowed)
	}

	metrics, err := u.repo.ListByUserRange(ctx, userID, target, apptime.EndOfMonth(target))
	if err != nil {
		return dto.MonthlyMoodResponse{}, err
	}
	return mapper.ToMonthlyMood(target, metrics), nil
}

func (u *dailyMetricUsecase) Stats(ctx context.Context, userID string, periodDays int) (dto.MoodStatsResponse, error) {
	if periodDays <= 0 {
		periodDays = u.cfg.MoodStatsDefaultPeriod
	}
	if periodDays > u.cfg.MoodStatsMaxPeriod {
		periodDays = u.cfg.MoodStatsMaxPeriod
	}

	to := apptime.Today()
	from := apptime.DaysAgo(periodDays - 1)

	metrics, err := u.repo.ListByUserRange(ctx, userID, from, to)
	if err != nil {
		return dto.MoodStatsResponse{}, err
	}
	return mapper.ToMoodStats(periodDays, from, to, metrics), nil
}

func (u *dailyMetricUsecase) SaveMetric(ctx context.Context, userID string, req dto.SaveDailyMetricRequest) (dto.DailyMetricResponse, error) {
	metricDate, err := u.resolveMetricDate(req.MetricDate)
	if err != nil {
		return dto.DailyMetricResponse{}, err
	}

	if !constants.IsValidCheckinEmotion(req.EmotionLabel) {
		return dto.DailyMetricResponse{}, utils.NewFieldErrors([]utils.FieldError{{
			Field:   "emotion_label",
			Code:    utils.CodeInvalidEnum,
			Message: "Emosi tidak termasuk pilihan yang tersedia",
		}})
	}
	if !constants.IsValidAcademicTrigger(req.AcademicTrigger) {
		return dto.DailyMetricResponse{}, utils.NewFieldErrors([]utils.FieldError{{
			Field:   "academic_trigger",
			Code:    utils.CodeInvalidEnum,
			Message: "Pemicu tidak termasuk pilihan yang tersedia",
		}})
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

	// Upsert, bukan insert: satu hari hanya punya satu kondisi. Mengisi ulang
	// hari yang sama berarti memperbaiki, bukan menambah baris baru.
	if err := u.repo.Upsert(ctx, &metric); err != nil {
		return dto.DailyMetricResponse{}, err
	}
	return mapper.ToDailyMetricResponse(metric), nil
}

// resolveMetricDate memvalidasi tanggal check-in terhadap dua batas:
// tidak boleh ke masa depan, dan tidak lebih lama dari MaxBackdateDays.
func (u *dailyMetricUsecase) resolveMetricDate(raw string) (time.Time, error) {
	today := apptime.Today()
	if raw == "" {
		return today, nil
	}

	parsed, err := apptime.ParseDate(raw)
	if err != nil {
		return time.Time{}, utils.NewError(utils.CodeInvalidDate)
	}
	parsed = apptime.StartOfDay(parsed)

	if parsed.After(today) {
		return time.Time{}, utils.NewError(utils.CodeFutureDateNotAllowed)
	}

	earliest := today.AddDate(0, 0, -u.cfg.MaxBackdateDays)
	if parsed.Before(earliest) {
		return time.Time{}, utils.NewErrorWithMessage(
			utils.CodeBackdateLimitExceeded,
			fmt.Sprintf("Check-in hanya dapat diisi mundur maksimal %d hari", u.cfg.MaxBackdateDays),
		)
	}
	return parsed, nil
}
