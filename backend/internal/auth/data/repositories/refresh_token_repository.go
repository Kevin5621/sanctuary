package repositories

import (
	"context"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

type RefreshTokenRepository interface {
	Create(ctx context.Context, tx *gorm.DB, token *models.RefreshToken) error
	// LockByHash memakai SELECT ... FOR UPDATE agar rotasi token bebas race condition.
	LockByHash(ctx context.Context, tx *gorm.DB, hash string) (*models.RefreshToken, error)
	Revoke(ctx context.Context, tx *gorm.DB, id string, replacedBy *string, at time.Time) error
	RevokeAllForUser(ctx context.Context, tx *gorm.DB, userID string, at time.Time) error
	DeleteExpired(ctx context.Context, before time.Time) (int64, error)
}

type refreshTokenRepository struct{ db *gorm.DB }

func NewRefreshTokenRepository(db *gorm.DB) RefreshTokenRepository {
	return &refreshTokenRepository{db: db}
}

func (r *refreshTokenRepository) conn(tx *gorm.DB) *gorm.DB {
	if tx != nil {
		return tx
	}
	return r.db
}

func (r *refreshTokenRepository) Create(ctx context.Context, tx *gorm.DB, token *models.RefreshToken) error {
	err := r.conn(tx).WithContext(ctx).Create(token).Error
	return utils.TranslateDBError(err, "")
}

func (r *refreshTokenRepository) LockByHash(ctx context.Context, tx *gorm.DB, hash string) (*models.RefreshToken, error) {
	var token models.RefreshToken
	err := r.conn(tx).WithContext(ctx).
		Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("token_hash = ?", hash).
		First(&token).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, utils.CodeRefreshTokenInvalid)
	}
	return &token, nil
}

func (r *refreshTokenRepository) Revoke(ctx context.Context, tx *gorm.DB, id string, replacedBy *string, at time.Time) error {
	err := r.conn(tx).WithContext(ctx).Model(&models.RefreshToken{}).
		Where("id = ? AND revoked_at IS NULL", id).
		Updates(map[string]any{"revoked_at": at, "replaced_by_id": replacedBy}).Error
	return utils.TranslateDBError(err, "")
}

// RevokeAllForUser dipanggil saat terdeteksi token reuse (indikasi pencurian token).
func (r *refreshTokenRepository) RevokeAllForUser(ctx context.Context, tx *gorm.DB, userID string, at time.Time) error {
	err := r.conn(tx).WithContext(ctx).Model(&models.RefreshToken{}).
		Where("user_id = ? AND revoked_at IS NULL", userID).
		Update("revoked_at", at).Error
	return utils.TranslateDBError(err, "")
}

func (r *refreshTokenRepository) DeleteExpired(ctx context.Context, before time.Time) (int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	res := r.db.WithContext(ctx).Where("expires_at < ?", before).Delete(&models.RefreshToken{})
	return res.RowsAffected, utils.TranslateDBError(res.Error, "")
}
