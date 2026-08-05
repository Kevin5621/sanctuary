package repositories

import (
	"context"

	"gorm.io/gorm"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/utils"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
)

// AdviseeRepository membaca data identitas mahasiswa bimbingan.
// Seluruh query WAJIB terikat advisor_id dari token dosen.
type AdviseeRepository interface {
	ListByAdvisor(ctx context.Context, advisorID string) ([]authmodels.User, error)
	// FindAdvisee mengembalikan ADVISOR_ASSIGNMENT_REQUIRED bila mahasiswa
	// bukan bimbingan dosen tersebut.
	FindAdvisee(ctx context.Context, advisorID, studentID string) (*authmodels.User, error)
	OpenContactRequests(ctx context.Context, advisorID string) (map[string]studentmodels.StudentContactRequest, error)
}

type adviseeRepository struct{ db *gorm.DB }

func NewAdviseeRepository(db *gorm.DB) AdviseeRepository { return &adviseeRepository{db: db} }

func (r *adviseeRepository) ListByAdvisor(ctx context.Context, advisorID string) ([]authmodels.User, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var students []authmodels.User
	err := r.db.WithContext(ctx).
		Where("advisor_id = ? AND is_active = true", advisorID).
		Order("full_name ASC").
		Find(&students).Error
	return students, utils.TranslateDBError(err, "")
}

func (r *adviseeRepository) FindAdvisee(ctx context.Context, advisorID, studentID string) (*authmodels.User, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var student authmodels.User
	err := r.db.WithContext(ctx).
		Where("id = ? AND advisor_id = ? AND is_active = true", studentID, advisorID).
		First(&student).Error
	if err != nil {
		// Tidak membedakan "tidak ada" vs "bukan bimbingan Anda" agar dosen
		// tidak dapat memetakan keberadaan mahasiswa di luar bimbingannya.
		return nil, utils.TranslateDBError(err, utils.CodeAdvisorAssignmentRequired)
	}
	return &student, nil
}

func (r *adviseeRepository) OpenContactRequests(ctx context.Context, advisorID string) (map[string]studentmodels.StudentContactRequest, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var requests []studentmodels.StudentContactRequest
	err := r.db.WithContext(ctx).
		Where("advisor_id = ? AND status = ?", advisorID, studentmodels.ContactRequestOpen).
		Find(&requests).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, "")
	}

	out := make(map[string]studentmodels.StudentContactRequest, len(requests))
	for _, req := range requests {
		out[req.StudentID] = req
	}
	return out, nil
}
