package repositories

import (
	"context"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/mentor/data/models"
)

type AdvisorNoteRepository interface {
	Create(ctx context.Context, note *models.AdvisorNote) error
	ListByMentorAndStudent(ctx context.Context, mentorID, studentID string) ([]models.AdvisorNote, error)
	Delete(ctx context.Context, mentorID, noteID string) error
}

type advisorNoteRepository struct {
	db *gorm.DB
}

func NewAdvisorNoteRepository(db *gorm.DB) AdvisorNoteRepository {
	return &advisorNoteRepository{db: db}
}

func (r *advisorNoteRepository) Create(ctx context.Context, note *models.AdvisorNote) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).Create(note).Error
	return utils.TranslateDBError(err, "")
}

func (r *advisorNoteRepository) ListByMentorAndStudent(ctx context.Context, mentorID, studentID string) ([]models.AdvisorNote, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var notes []models.AdvisorNote
	err := r.db.WithContext(ctx).
		Where("mentor_id = ? AND student_id = ?", mentorID, studentID).
		Order("interaction_date DESC").
		Find(&notes).Error
	return notes, utils.TranslateDBError(err, "")
}

func (r *advisorNoteRepository) Delete(ctx context.Context, mentorID, noteID string) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).
		Where("id = ? AND mentor_id = ?", noteID, mentorID).
		Delete(&models.AdvisorNote{}).Error
	return utils.TranslateDBError(err, "")
}
