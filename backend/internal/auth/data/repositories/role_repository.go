package repositories

import (
	"context"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// RoleRepository menerjemahkan kode peran menjadi baris roles.
// Dipakai saat membuat akun: role_id tidak pernah datang dari klien, selalu
// diturunkan dari kode peran yang sudah divalidasi usecase.
type RoleRepository interface {
	FindByCode(ctx context.Context, code constants.Role) (*models.Role, error)
}

type roleRepository struct{ db *gorm.DB }

func NewRoleRepository(db *gorm.DB) RoleRepository { return &roleRepository{db: db} }

func (r *roleRepository) FindByCode(ctx context.Context, code constants.Role) (*models.Role, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var role models.Role
	err := r.db.WithContext(ctx).Where("code = ?", code.String()).First(&role).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, utils.CodeNotFound)
	}
	return &role, nil
}
