package repositories

import (
	"context"
	"time"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/mentor/data/models"
)

type EarlyWarningRepository interface {
	Save(ctx context.Context, log *models.EarlyWarningLog) error
	// LatestSince mengambil hasil evaluasi terakhir yang masih dianggap segar,
	// agar daftar bimbingan tidak menghitung ulang EWS pada setiap permintaan.
	LatestSince(ctx context.Context, studentIDs []string, since time.Time) (map[string]models.EarlyWarningLog, error)
	HistoryForStudent(ctx context.Context, studentID string, limit int) ([]models.EarlyWarningLog, error)
}

type earlyWarningRepository struct{ db *gorm.DB }

func NewEarlyWarningRepository(db *gorm.DB) EarlyWarningRepository {
	return &earlyWarningRepository{db: db}
}

func (r *earlyWarningRepository) Save(ctx context.Context, log *models.EarlyWarningLog) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	return utils.TranslateDBError(r.db.WithContext(ctx).Create(log).Error, "")
}

func (r *earlyWarningRepository) LatestSince(ctx context.Context, studentIDs []string, since time.Time) (map[string]models.EarlyWarningLog, error) {
	out := make(map[string]models.EarlyWarningLog, len(studentIDs))
	if len(studentIDs) == 0 {
		return out, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	// DISTINCT ON mengambil satu baris terbaru per mahasiswa dalam satu query
	// (menghindari N+1 pada daftar bimbingan).
	var logs []models.EarlyWarningLog
	err := r.db.WithContext(ctx).
		Raw(`SELECT DISTINCT ON (student_id) *
		     FROM early_warning_logs
		     WHERE student_id IN ? AND evaluated_at >= ?
		     ORDER BY student_id, evaluated_at DESC`, studentIDs, since).
		Scan(&logs).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, "")
	}

	for _, log := range logs {
		out[log.StudentID] = log
	}
	return out, nil
}

func (r *earlyWarningRepository) HistoryForStudent(ctx context.Context, studentID string, limit int) ([]models.EarlyWarningLog, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var logs []models.EarlyWarningLog
	err := r.db.WithContext(ctx).
		Where("student_id = ?", studentID).
		Order("evaluated_at DESC").
		Limit(limit).
		Find(&logs).Error
	return logs, utils.TranslateDBError(err, "")
}
