package repositories

import (
	"context"
	"time"

	"gorm.io/gorm"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/utils"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
)

// ContactRequestSummary adalah proyeksi permintaan "minta dihubungi" yang boleh
// dilihat dosen: SIAPA dan KAPAN.
//
// Kolom student_contact_requests.note SENGAJA TIDAK ADA di struct ini dan tidak
// pernah masuk daftar SELECT (D-6). Menghentikannya di lapisan repository —
// bukan hanya di DTO — berarti tidak ada jalur kode di atas sini yang bisa
// membocorkannya, bahkan karena kelalaian.
type ContactRequestSummary struct {
	RequestID     string    `gorm:"column:request_id"`
	StudentID     string    `gorm:"column:student_id"`
	FullName      string    `gorm:"column:full_name"`
	StudentNumber *string   `gorm:"column:student_number"`
	RequestedAt   time.Time `gorm:"column:requested_at"`
}

// AdviseeRepository membaca data identitas mahasiswa bimbingan.
// Seluruh query WAJIB terikat advisor_id dari token dosen.
type AdviseeRepository interface {
	ListByAdvisor(ctx context.Context, advisorID string) ([]authmodels.User, error)
	// FindAdvisee mengembalikan ADVISOR_ASSIGNMENT_REQUIRED bila mahasiswa
	// bukan bimbingan dosen tersebut.
	FindAdvisee(ctx context.Context, advisorID, studentID string) (*authmodels.User, error)
	// OpenContactRequests dipakai daftar bimbingan (menandai baris + waktunya),
	// dikunci pada proyeksi tanpa `note`.
	OpenContactRequests(ctx context.Context, advisorID string) (map[string]ContactRequestSummary, error)
	// ListOpenContactRequests dipakai layar "minta dihubungi" (L-BIM-03),
	// terurut dari permintaan terlama agar tidak ada yang terlewat.
	ListOpenContactRequests(ctx context.Context, advisorID string) ([]ContactRequestSummary, error)
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

func (r *adviseeRepository) OpenContactRequests(ctx context.Context, advisorID string) (map[string]ContactRequestSummary, error) {
	requests, err := r.ListOpenContactRequests(ctx, advisorID)
	if err != nil {
		return nil, err
	}

	out := make(map[string]ContactRequestSummary, len(requests))
	for _, req := range requests {
		out[req.StudentID] = req
	}
	return out, nil
}

// ListOpenContactRequests menuliskan daftar SELECT secara eksplisit.
//
// JANGAN mengganti Select() ini dengan Find(&models.StudentContactRequest{}):
// model tersebut memuat kolom `note` yang tidak boleh sampai ke dosen (D-6).
func (r *adviseeRepository) ListOpenContactRequests(ctx context.Context, advisorID string) ([]ContactRequestSummary, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var rows []ContactRequestSummary
	err := r.db.WithContext(ctx).
		Model(&studentmodels.StudentContactRequest{}).
		Select(`student_contact_requests.id          AS request_id,
		        student_contact_requests.student_id  AS student_id,
		        student_contact_requests.created_at  AS requested_at,
		        users.full_name                      AS full_name,
		        users.student_number                 AS student_number`).
		Joins("JOIN users ON users.id = student_contact_requests.student_id").
		Where("student_contact_requests.advisor_id = ?", advisorID).
		Where("student_contact_requests.status = ?", studentmodels.ContactRequestOpen).
		Where("users.is_active = true AND users.deleted_at IS NULL").
		Order("student_contact_requests.created_at ASC").
		Scan(&rows).Error
	return rows, utils.TranslateDBError(err, "")
}
