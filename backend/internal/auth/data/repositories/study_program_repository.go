package repositories

import (
	"context"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// StudyProgramRepository menyediakan daftar program studi untuk dropdown
// formulir pendaftaran mahasiswa dan kelola akun Admin.
type StudyProgramRepository interface {
	List(ctx context.Context) ([]models.StudyProgram, error)
	FindByID(ctx context.Context, id string) (*models.StudyProgram, error)
}

type studyProgramRepository struct{ db *gorm.DB }

func NewStudyProgramRepository(db *gorm.DB) StudyProgramRepository {
	return &studyProgramRepository{db: db}
}

func (r *studyProgramRepository) List(ctx context.Context) ([]models.StudyProgram, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var programs []models.StudyProgram
	err := r.db.WithContext(ctx).Order("name ASC").Find(&programs).Error
	return programs, utils.TranslateDBError(err, "")
}

func (r *studyProgramRepository) FindByID(ctx context.Context, id string) (*models.StudyProgram, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var program models.StudyProgram
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&program).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, utils.CodeStudyProgramNotFound)
	}
	return &program, nil
}
