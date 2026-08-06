package repositories

import (
	"context"
	"errors"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
)

// AIConsentRepository menyimpan keputusan mahasiswa atas D-5.
//
// Seperti repository konten privat lainnya, setiap method wajib menerima
// userID. Tidak ada method yang dapat membaca keputusan seluruh pengguna:
// daftar siapa yang memakai Terapis AI bukan informasi yang dibutuhkan peran
// mana pun di aplikasi ini, dan menyediakan query-nya hanya menciptakan
// permukaan kebocoran baru.
type AIConsentRepository interface {
	// FindByUser mengembalikan (nil, nil) bila mahasiswa belum pernah memutuskan.
	// "Belum memutuskan" adalah keadaan sah, bukan error.
	FindByUser(ctx context.Context, userID string) (*models.AIChatConsent, error)
	Upsert(ctx context.Context, consent *models.AIChatConsent) error
}

type aiConsentRepository struct{ db *gorm.DB }

func NewAIConsentRepository(db *gorm.DB) AIConsentRepository {
	return &aiConsentRepository{db: db}
}

func (r *aiConsentRepository) FindByUser(ctx context.Context, userID string) (*models.AIChatConsent, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var consent models.AIChatConsent
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&consent).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, utils.TranslateDBError(err, "")
	}
	return &consent, nil
}

// Upsert menimpa keputusan sebelumnya berdasarkan user_id.
//
// Menimpa (bukan menumpuk baris) dipilih agar tidak pernah ada dua keputusan
// aktif yang saling bertentangan untuk satu mahasiswa — gate harus punya satu
// jawaban yang tidak ambigu. Jejak perubahannya tetap terekam di audit log.
func (r *aiConsentRepository) Upsert(ctx context.Context, consent *models.AIChatConsent) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "user_id"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"status", "notice_version", "consented_at", "decided_at", "updated_at",
		}),
	}).Create(consent).Error
	return utils.TranslateDBError(err, "")
}
