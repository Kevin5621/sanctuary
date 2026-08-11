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
//
// Seluruh query WAJIB terikat advisor_id dari token dosen, kini lewat tabel
// pasangan student_advisors: seorang mahasiswa boleh punya beberapa pembimbing,
// dan masing-masing melihat mahasiswa itu di daftarnya sendiri.
type AdviseeRepository interface {
	ListByAdvisor(ctx context.Context, advisorID string) ([]authmodels.User, error)
	// FindAdvisee mengembalikan ADVISOR_ASSIGNMENT_REQUIRED bila mahasiswa
	// bukan bimbingan dosen tersebut.
	FindAdvisee(ctx context.Context, advisorID, studentID string) (*authmodels.User, error)
	// CoAdvisors adalah pembimbing LAIN dari seorang mahasiswa. Murni
	// administratif (nama saja) supaya dosen tahu ia tidak sendirian menangani
	// mahasiswa tersebut — tanpa satu pun angka kondisi.
	CoAdvisors(ctx context.Context, advisorID, studentID string) ([]string, error)
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
		Joins("JOIN student_advisors ON student_advisors.student_id = users.id").
		Where("student_advisors.advisor_id = ?", advisorID).
		Where("users.is_active = true").
		Order("users.full_name ASC").
		Find(&students).Error
	return students, utils.TranslateDBError(err, "")
}

func (r *adviseeRepository) FindAdvisee(ctx context.Context, advisorID, studentID string) (*authmodels.User, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var student authmodels.User
	err := r.db.WithContext(ctx).
		Joins("JOIN student_advisors ON student_advisors.student_id = users.id").
		Where("users.id = ? AND student_advisors.advisor_id = ?", studentID, advisorID).
		Where("users.is_active = true").
		First(&student).Error
	if err != nil {
		// Tidak membedakan "tidak ada" vs "bukan bimbingan Anda" agar dosen
		// tidak dapat memetakan keberadaan mahasiswa di luar bimbingannya.
		return nil, utils.TranslateDBError(err, utils.CodeAdvisorAssignmentRequired)
	}
	return &student, nil
}

// CoAdvisors hanya boleh dipanggil SETELAH FindAdvisee lolos: query-nya sendiri
// tidak memverifikasi bahwa pemanggil membimbing mahasiswa tersebut, dan tanpa
// gerbang itu ia berubah menjadi cara memetakan pembimbing mahasiswa mana pun.
func (r *adviseeRepository) CoAdvisors(ctx context.Context, advisorID, studentID string) ([]string, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var names []string
	err := r.db.WithContext(ctx).
		Model(&authmodels.StudentAdvisor{}).
		Joins("JOIN users AS advisors ON advisors.id = student_advisors.advisor_id").
		Where("student_advisors.student_id = ? AND student_advisors.advisor_id <> ?", studentID, advisorID).
		Where("advisors.is_active = true AND advisors.deleted_at IS NULL").
		Order("advisors.full_name ASC").
		Pluck("advisors.full_name", &names).Error
	return names, utils.TranslateDBError(err, "")
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
//
// Penerima permintaan ditentukan lewat student_advisors, bukan kolom pada
// permintaan itu sendiri: satu isyarat "minta dihubungi" memang ditujukan ke
// SELURUH pembimbing mahasiswa tersebut.
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
		Joins(`JOIN student_advisors
		       ON student_advisors.student_id = student_contact_requests.student_id
		       AND student_advisors.advisor_id = ?`, advisorID).
		Where("student_contact_requests.status = ?", studentmodels.ContactRequestOpen).
		Where("users.is_active = true AND users.deleted_at IS NULL").
		Order("student_contact_requests.created_at ASC").
		Scan(&rows).Error
	return rows, utils.TranslateDBError(err, "")
}
