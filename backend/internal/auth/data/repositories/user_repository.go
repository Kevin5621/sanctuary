package repositories

import (
	"context"
	"strings"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

type UserRepository interface {
	FindByEmail(ctx context.Context, email string) (*models.User, error)
	FindByID(ctx context.Context, id string) (*models.User, error)
	TouchLastLogin(ctx context.Context, tx *gorm.DB, userID string) error
	CountAdvisees(ctx context.Context, advisorID string) (int64, error)
}

type userRepository struct{ db *gorm.DB }

func NewUserRepository(db *gorm.DB) UserRepository { return &userRepository{db: db} }

func (r *userRepository) FindByEmail(ctx context.Context, email string) (*models.User, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var user models.User
	err := r.db.WithContext(ctx).
		Preload("Role").
		Preload("StudyProgram").
		Where("lower(email) = ?", strings.ToLower(strings.TrimSpace(email))).
		First(&user).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, utils.CodeUserNotFound)
	}
	return &user, nil
}

func (r *userRepository) FindByID(ctx context.Context, id string) (*models.User, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var user models.User
	err := r.db.WithContext(ctx).
		Preload("Role").
		Preload("StudyProgram").
		Where("id = ?", id).
		First(&user).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, utils.CodeUserNotFound)
	}
	return &user, nil
}

func (r *userRepository) TouchLastLogin(ctx context.Context, tx *gorm.DB, userID string) error {
	db := r.db
	if tx != nil {
		db = tx
	}
	err := db.WithContext(ctx).Model(&models.User{}).
		Where("id = ?", userID).
		UpdateColumn("last_login_at", gorm.Expr("now()")).Error
	return utils.TranslateDBError(err, "")
}

func (r *userRepository) CountAdvisees(ctx context.Context, advisorID string) (int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var total int64
	err := r.db.WithContext(ctx).Model(&models.User{}).
		Where("advisor_id = ? AND is_active = true", advisorID).
		Count(&total).Error
	return total, utils.TranslateDBError(err, "")
}
