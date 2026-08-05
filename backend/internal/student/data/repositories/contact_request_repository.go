package repositories

import (
	"context"
	"errors"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
)

// ContactRequestRepository menyimpan status "minta dihubungi".
//
// Baris di sini adalah satu-satunya isyarat yang dikirim mahasiswa secara
// aktif ke dosen. Kolom Note ikut tersimpan tetapi TIDAK PERNAH dibaca oleh
// jalur dosen — lihat mentor_dto: yang sampai ke pembimbing hanya nama dan
// waktu, tanpa sebab.
type ContactRequestRepository interface {
	// FindOpenByStudent mengembalikan (nil, nil) bila tidak ada yang terbuka.
	FindOpenByStudent(ctx context.Context, studentID string) (*models.StudentContactRequest, error)
	Create(ctx context.Context, request *models.StudentContactRequest) error
	// CancelOpenByStudent membatalkan permintaan yang masih terbuka.
	CancelOpenByStudent(ctx context.Context, studentID string) error
	// ListOpenByAdvisor dipakai daftar bimbingan dosen.
	ListOpenByAdvisor(ctx context.Context, advisorID string) ([]models.StudentContactRequest, error)
}

type contactRequestRepository struct{ db *gorm.DB }

func NewContactRequestRepository(db *gorm.DB) ContactRequestRepository {
	return &contactRequestRepository{db: db}
}

func (r *contactRequestRepository) FindOpenByStudent(ctx context.Context, studentID string) (*models.StudentContactRequest, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var request models.StudentContactRequest
	err := r.db.WithContext(ctx).
		Where("student_id = ? AND status = ?", studentID, models.ContactRequestOpen).
		First(&request).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, utils.TranslateDBError(err, "")
	}
	return &request, nil
}

func (r *contactRequestRepository) Create(ctx context.Context, request *models.StudentContactRequest) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	// Unique index parsial (status = OPEN) menjaga agar tidak ada dua
	// permintaan terbuka walau dua tap terjadi bersamaan.
	err := r.db.WithContext(ctx).Create(request).Error
	return utils.TranslateDBError(err, utils.CodeContactRequestExists)
}

func (r *contactRequestRepository) CancelOpenByStudent(ctx context.Context, studentID string) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	now := apptime.Now()
	res := r.db.WithContext(ctx).Model(&models.StudentContactRequest{}).
		Where("student_id = ? AND status = ?", studentID, models.ContactRequestOpen).
		Updates(map[string]any{
			"status":     models.ContactRequestCancelled,
			"handled_at": now,
		})
	if res.Error != nil {
		return utils.TranslateDBError(res.Error, "")
	}
	if res.RowsAffected == 0 {
		return utils.NewError(utils.CodeNotFound)
	}
	return nil
}

func (r *contactRequestRepository) ListOpenByAdvisor(ctx context.Context, advisorID string) ([]models.StudentContactRequest, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var requests []models.StudentContactRequest
	err := r.db.WithContext(ctx).
		Where("advisor_id = ? AND status = ?", advisorID, models.ContactRequestOpen).
		Order("created_at ASC").
		Find(&requests).Error
	return requests, utils.TranslateDBError(err, "")
}
