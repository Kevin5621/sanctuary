package repositories

import (
	"context"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
)

type DassRepository interface {
	Create(ctx context.Context, result *models.Dass21Result) error
	// LatestTwoForUser dipakai EWS untuk mendeteksi tren memburuk.
	LatestTwoForUser(ctx context.Context, userID string) ([]models.Dass21Result, error)
	ListByUser(ctx context.Context, userID string, limit int) ([]models.Dass21Result, error)
	// CountScreenedUsers dipakai metrik "sudah skrining" pada dashboard kaprodi.
	CountScreenedUsers(ctx context.Context, userIDs []string) (int, error)
}

type dassRepository struct{ db *gorm.DB }

func NewDassRepository(db *gorm.DB) DassRepository { return &dassRepository{db: db} }

func (r *dassRepository) Create(ctx context.Context, result *models.Dass21Result) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	return utils.TranslateDBError(r.db.WithContext(ctx).Create(result).Error, "")
}

func (r *dassRepository) LatestTwoForUser(ctx context.Context, userID string) ([]models.Dass21Result, error) {
	return r.ListByUser(ctx, userID, 2)
}

func (r *dassRepository) ListByUser(ctx context.Context, userID string, limit int) ([]models.Dass21Result, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var results []models.Dass21Result
	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("taken_at DESC").
		Limit(limit).
		Find(&results).Error
	return results, utils.TranslateDBError(err, "")
}

func (r *dassRepository) CountScreenedUsers(ctx context.Context, userIDs []string) (int, error) {
	if len(userIDs) == 0 {
		return 0, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var count int64
	err := r.db.WithContext(ctx).Model(&models.Dass21Result{}).
		Where("user_id IN ?", userIDs).
		Distinct("user_id").
		Count(&count).Error
	return int(count), utils.TranslateDBError(err, "")
}
