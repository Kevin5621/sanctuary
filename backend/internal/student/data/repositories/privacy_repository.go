package repositories

import (
	"context"
	"errors"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
)

type PrivacyRepository interface {
	// GetOrDefault mengembalikan setting tersimpan, atau default privacy-first
	// (in-memory, tidak ditulis ke DB) bila mahasiswa belum pernah mengatur.
	GetOrDefault(ctx context.Context, userID string) (*models.StudentPrivacySetting, error)
	Upsert(ctx context.Context, setting *models.StudentPrivacySetting) error
	// FindManyByUserIDs mencegah N+1 saat dosen membuka daftar bimbingan.
	FindManyByUserIDs(ctx context.Context, userIDs []string) (map[string]*models.StudentPrivacySetting, error)
}

type privacyRepository struct{ db *gorm.DB }

func NewPrivacyRepository(db *gorm.DB) PrivacyRepository { return &privacyRepository{db: db} }

func (r *privacyRepository) GetOrDefault(ctx context.Context, userID string) (*models.StudentPrivacySetting, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var setting models.StudentPrivacySetting
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&setting).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return models.DefaultPrivacySetting(userID), nil
		}
		return nil, utils.TranslateDBError(err, "")
	}
	return &setting, nil
}

func (r *privacyRepository) Upsert(ctx context.Context, setting *models.StudentPrivacySetting) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "user_id"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"share_level", "allow_early_warning", "allow_program_statistic", "updated_at",
		}),
	}).Create(setting).Error
	return utils.TranslateDBError(err, "")
}

func (r *privacyRepository) FindManyByUserIDs(ctx context.Context, userIDs []string) (map[string]*models.StudentPrivacySetting, error) {
	result := make(map[string]*models.StudentPrivacySetting, len(userIDs))
	if len(userIDs) == 0 {
		return result, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var settings []models.StudentPrivacySetting
	if err := r.db.WithContext(ctx).Where("user_id IN ?", userIDs).Find(&settings).Error; err != nil {
		return nil, utils.TranslateDBError(err, "")
	}
	for i := range settings {
		result[settings[i].UserID] = &settings[i]
	}
	// Mahasiswa tanpa baris setting diperlakukan sebagai default (Tertutup).
	for _, id := range userIDs {
		if _, ok := result[id]; !ok {
			result[id] = models.DefaultPrivacySetting(id)
		}
	}
	return result, nil
}
