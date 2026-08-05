package repositories

import (
	"context"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/support/data/models"
)

type EmergencyContactRepository interface {
	List(ctx context.Context, p utils.Pagination, activeOnly bool) ([]models.EmergencyContact, int64, error)
	// FindByID dengan activeOnly=true dipakai peran non-Admin (A-BAN-02):
	// baris nonaktif harus berperilaku seolah tidak ada, bukan sekadar
	// disembunyikan dari daftar.
	FindByID(ctx context.Context, id string, activeOnly bool) (*models.EmergencyContact, error)
	Create(ctx context.Context, contact *models.EmergencyContact) error
	Update(ctx context.Context, contact *models.EmergencyContact) error
	Delete(ctx context.Context, id string) error
}

type emergencyContactRepository struct{ db *gorm.DB }

func NewEmergencyContactRepository(db *gorm.DB) EmergencyContactRepository {
	return &emergencyContactRepository{db: db}
}

// sortWhitelist mencegah SQL injection lewat parameter sort_by.
var sortWhitelist = map[string]string{
	"sort_order":   "sort_order",
	"name":         "name",
	"service_type": "service_type",
	"created":      "created_at",
}

func (r *emergencyContactRepository) List(ctx context.Context, p utils.Pagination, activeOnly bool) ([]models.EmergencyContact, int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	query := r.db.WithContext(ctx).Model(&models.EmergencyContact{})
	if activeOnly {
		query = query.Where("is_active = true")
	}
	if p.Search != "" {
		query = query.Where("name ILIKE ?", "%"+p.Search+"%")
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, utils.TranslateDBError(err, "")
	}

	var contacts []models.EmergencyContact
	err := query.
		Order(utils.SafeOrderBy(p.SortBy, p.SortDir, sortWhitelist, "sort_order")).
		Order("name ASC").
		Limit(p.PerPage).Offset(p.Offset()).
		Find(&contacts).Error
	return contacts, total, utils.TranslateDBError(err, "")
}

func (r *emergencyContactRepository) FindByID(ctx context.Context, id string, activeOnly bool) (*models.EmergencyContact, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	query := r.db.WithContext(ctx).Where("id = ?", id)
	if activeOnly {
		query = query.Where("is_active = true")
	}

	var contact models.EmergencyContact
	if err := query.First(&contact).Error; err != nil {
		// Sengaja tidak membedakan "tidak ada" vs "nonaktif" agar peran non-Admin
		// tidak dapat menyimpulkan keberadaan nomor yang sedang dinonaktifkan.
		return nil, utils.TranslateDBError(err, utils.CodeEmergencyContactNotFound)
	}
	return &contact, nil
}

func (r *emergencyContactRepository) Create(ctx context.Context, contact *models.EmergencyContact) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	return utils.TranslateDBError(r.db.WithContext(ctx).Create(contact).Error, "")
}

func (r *emergencyContactRepository) Update(ctx context.Context, contact *models.EmergencyContact) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).Model(&models.EmergencyContact{}).
		Where("id = ?", contact.ID).
		Updates(map[string]any{
			"name":         contact.Name,
			"phone":        contact.Phone,
			"description":  contact.Description,
			"service_type": contact.ServiceType,
			"is_24_hours":  contact.Is24Hours,
			"is_active":    contact.IsActive,
			"sort_order":   contact.SortOrder,
		}).Error
	return utils.TranslateDBError(err, "")
}

func (r *emergencyContactRepository) Delete(ctx context.Context, id string) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	res := r.db.WithContext(ctx).Where("id = ?", id).Delete(&models.EmergencyContact{})
	if res.Error != nil {
		return utils.TranslateDBError(res.Error, "")
	}
	if res.RowsAffected == 0 {
		return utils.NewError(utils.CodeEmergencyContactNotFound)
	}
	return nil
}
