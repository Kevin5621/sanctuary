package repositories

import (
	"context"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
)

// GroupAggregate adalah hasil agregasi kuantitatif untuk sekelompok mahasiswa.
// Tidak memuat identitas individu — konsumen wajib melewati k-anonymity guard
// sebelum mengeluarkan angka ini.
type GroupAggregate struct {
	StudentCount  int     `gorm:"column:student_count"`
	AvgMood       float64 `gorm:"column:avg_mood"`
	AvgStress     float64 `gorm:"column:avg_stress"`
	AvgSleepHours float64 `gorm:"column:avg_sleep"`
	DataPoints    int     `gorm:"column:data_points"`
}

// EmotionCount dipakai sebaran emosi (mahasiswa & agregat kelompok).
type EmotionCount struct {
	EmotionLabel string `gorm:"column:emotion_label" json:"emotion_label"`
	Total        int    `gorm:"column:total" json:"total"`
}

// WeeklyPoint adalah satu titik pada grafik tren mingguan.
// Hanya dikirim ke dosen bila share_level = SUMMARY_TREND.
type WeeklyPoint struct {
	WeekStart time.Time `gorm:"column:week_start" json:"-"`
	AvgMood   float64   `gorm:"column:avg_mood" json:"avg_mood"`
	AvgStress float64   `gorm:"column:avg_stress" json:"avg_stress"`
	AvgSleep  float64   `gorm:"column:avg_sleep" json:"avg_sleep"`
	Entries   int       `gorm:"column:entries" json:"entries"`
}

type DailyMetricRepository interface {
	Upsert(ctx context.Context, metric *models.StudentDailyMetric) error
	ExistsOnDate(ctx context.Context, userID string, date time.Time) (bool, error)
	ListByUserRange(ctx context.Context, userID string, from, to time.Time) ([]models.StudentDailyMetric, error)
	// WeeklyTrend dipakai grafik tren mingguan (level berbagi SUMMARY_TREND).
	WeeklyTrend(ctx context.Context, userID string, from, to time.Time) ([]WeeklyPoint, error)
	// LastCheckinDates menghindari N+1 pada daftar bimbingan.
	LastCheckinDates(ctx context.Context, userIDs []string) (map[string]time.Time, error)
	// AggregateForUsers dipakai dosen (kondisi kelompok) & kaprodi (dashboard prodi).
	AggregateForUsers(ctx context.Context, userIDs []string, from, to time.Time) (GroupAggregate, error)
	EmotionDistribution(ctx context.Context, userIDs []string, from, to time.Time) ([]EmotionCount, error)
	// CountActiveStudents = mahasiswa dengan minimal satu check-in pada rentang.
	CountActiveStudents(ctx context.Context, userIDs []string, from, to time.Time) (int, error)
}

type dailyMetricRepository struct{ db *gorm.DB }

func NewDailyMetricRepository(db *gorm.DB) DailyMetricRepository {
	return &dailyMetricRepository{db: db}
}

func (r *dailyMetricRepository) Upsert(ctx context.Context, metric *models.StudentDailyMetric) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "user_id"}, {Name: "metric_date"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"mood_score", "stress_level", "sleep_hours", "academic_trigger", "emotion_label", "updated_at",
		}),
	}).Create(metric).Error
	return utils.TranslateDBError(err, "")
}

func (r *dailyMetricRepository) ExistsOnDate(ctx context.Context, userID string, date time.Time) (bool, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var count int64
	err := r.db.WithContext(ctx).Model(&models.StudentDailyMetric{}).
		Where("user_id = ? AND metric_date = ?", userID, date).
		Count(&count).Error
	return count > 0, utils.TranslateDBError(err, "")
}

func (r *dailyMetricRepository) ListByUserRange(ctx context.Context, userID string, from, to time.Time) ([]models.StudentDailyMetric, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var metrics []models.StudentDailyMetric
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND metric_date BETWEEN ? AND ?", userID, from, to).
		Order("metric_date ASC").
		Find(&metrics).Error
	return metrics, utils.TranslateDBError(err, "")
}

func (r *dailyMetricRepository) WeeklyTrend(ctx context.Context, userID string, from, to time.Time) ([]WeeklyPoint, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var points []WeeklyPoint
	err := r.db.WithContext(ctx).Model(&models.StudentDailyMetric{}).
		Select(`date_trunc('week', metric_date) AS week_start,
		        AVG(mood_score) AS avg_mood,
		        AVG(stress_level) AS avg_stress,
		        AVG(sleep_hours) AS avg_sleep,
		        COUNT(*) AS entries`).
		Where("user_id = ? AND metric_date BETWEEN ? AND ?", userID, from, to).
		Group("week_start").
		Order("week_start ASC").
		Scan(&points).Error
	return points, utils.TranslateDBError(err, "")
}

func (r *dailyMetricRepository) LastCheckinDates(ctx context.Context, userIDs []string) (map[string]time.Time, error) {
	out := make(map[string]time.Time, len(userIDs))
	if len(userIDs) == 0 {
		return out, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var rows []struct {
		UserID   string    `gorm:"column:user_id"`
		LastDate time.Time `gorm:"column:last_date"`
	}
	err := r.db.WithContext(ctx).Model(&models.StudentDailyMetric{}).
		Select("user_id, MAX(metric_date) AS last_date").
		Where("user_id IN ?", userIDs).
		Group("user_id").
		Scan(&rows).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, "")
	}

	for _, row := range rows {
		out[row.UserID] = row.LastDate
	}
	return out, nil
}

func (r *dailyMetricRepository) AggregateForUsers(ctx context.Context, userIDs []string, from, to time.Time) (GroupAggregate, error) {
	var agg GroupAggregate
	if len(userIDs) == 0 {
		return agg, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).Model(&models.StudentDailyMetric{}).
		Select(`COUNT(DISTINCT user_id) AS student_count,
		        COALESCE(AVG(mood_score), 0) AS avg_mood,
		        COALESCE(AVG(stress_level), 0) AS avg_stress,
		        COALESCE(AVG(sleep_hours), 0) AS avg_sleep,
		        COUNT(*) AS data_points`).
		Where("user_id IN ? AND metric_date BETWEEN ? AND ?", userIDs, from, to).
		Scan(&agg).Error
	return agg, utils.TranslateDBError(err, "")
}

func (r *dailyMetricRepository) EmotionDistribution(ctx context.Context, userIDs []string, from, to time.Time) ([]EmotionCount, error) {
	if len(userIDs) == 0 {
		return nil, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var rows []EmotionCount
	err := r.db.WithContext(ctx).Model(&models.StudentDailyMetric{}).
		Select("emotion_label, COUNT(*) AS total").
		Where("user_id IN ? AND metric_date BETWEEN ? AND ? AND emotion_label <> ''", userIDs, from, to).
		Group("emotion_label").
		Order("total DESC").
		Scan(&rows).Error
	return rows, utils.TranslateDBError(err, "")
}

func (r *dailyMetricRepository) CountActiveStudents(ctx context.Context, userIDs []string, from, to time.Time) (int, error) {
	if len(userIDs) == 0 {
		return 0, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var count int64
	err := r.db.WithContext(ctx).Model(&models.StudentDailyMetric{}).
		Where("user_id IN ? AND metric_date BETWEEN ? AND ?", userIDs, from, to).
		Distinct("user_id").
		Count(&count).Error
	return int(count), utils.TranslateDBError(err, "")
}
