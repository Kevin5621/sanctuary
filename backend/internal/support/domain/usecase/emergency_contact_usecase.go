package usecase

import (
	"context"

	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/support/data/models"
	"github.com/gilabs/sanctuary/internal/support/data/repositories"
	"github.com/gilabs/sanctuary/internal/support/domain/dto"
	"github.com/gilabs/sanctuary/internal/support/domain/mapper"
)

// EmergencyContactUsecase — CRUD layanan bantuan darurat.
// Admin mengelola seluruh data; peran lain hanya membaca yang aktif.
type EmergencyContactUsecase interface {
	List(ctx context.Context, p utils.Pagination, activeOnly bool) ([]dto.EmergencyContactResponse, int64, error)
	Get(ctx context.Context, id string, activeOnly bool) (dto.EmergencyContactResponse, error)
	Create(ctx context.Context, req dto.CreateEmergencyContactRequest) (dto.EmergencyContactResponse, error)
	Update(ctx context.Context, id string, req dto.UpdateEmergencyContactRequest) (dto.EmergencyContactResponse, error)
	Delete(ctx context.Context, id string) error
}

type emergencyContactUsecase struct {
	repo repositories.EmergencyContactRepository
}

func NewEmergencyContactUsecase(repo repositories.EmergencyContactRepository) EmergencyContactUsecase {
	return &emergencyContactUsecase{repo: repo}
}

func (u *emergencyContactUsecase) List(ctx context.Context, p utils.Pagination, activeOnly bool) ([]dto.EmergencyContactResponse, int64, error) {
	contacts, total, err := u.repo.List(ctx, p, activeOnly)
	if err != nil {
		return nil, 0, err
	}
	return mapper.ToEmergencyContactResponses(contacts), total, nil
}

func (u *emergencyContactUsecase) Get(ctx context.Context, id string, activeOnly bool) (dto.EmergencyContactResponse, error) {
	contact, err := u.repo.FindByID(ctx, id, activeOnly)
	if err != nil {
		return dto.EmergencyContactResponse{}, err
	}
	return mapper.ToEmergencyContactResponse(contact), nil
}

func (u *emergencyContactUsecase) Create(ctx context.Context, req dto.CreateEmergencyContactRequest) (dto.EmergencyContactResponse, error) {
	serviceType, err := parseServiceType(req.ServiceType)
	if err != nil {
		return dto.EmergencyContactResponse{}, err
	}

	contact := &models.EmergencyContact{
		Name:        req.Name,
		Phone:       req.Phone,
		Description: req.Description,
		ServiceType: serviceType,
		Is24Hours:   req.Is24Hours,
		IsActive:    *req.IsActive,
		SortOrder:   req.SortOrder,
	}
	if err := u.repo.Create(ctx, contact); err != nil {
		return dto.EmergencyContactResponse{}, err
	}
	return mapper.ToEmergencyContactResponse(contact), nil
}

func (u *emergencyContactUsecase) Update(ctx context.Context, id string, req dto.UpdateEmergencyContactRequest) (dto.EmergencyContactResponse, error) {
	serviceType, err := parseServiceType(req.ServiceType)
	if err != nil {
		return dto.EmergencyContactResponse{}, err
	}

	// Admin adalah satu-satunya pemanggil Update, sehingga baris nonaktif
	// tetap dapat diambil untuk diedit/diaktifkan kembali.
	existing, err := u.repo.FindByID(ctx, id, false)
	if err != nil {
		return dto.EmergencyContactResponse{}, err
	}

	existing.Name = req.Name
	existing.Phone = req.Phone
	existing.Description = req.Description
	existing.ServiceType = serviceType
	existing.Is24Hours = req.Is24Hours
	existing.IsActive = *req.IsActive
	existing.SortOrder = req.SortOrder

	if err := u.repo.Update(ctx, existing); err != nil {
		return dto.EmergencyContactResponse{}, err
	}
	return mapper.ToEmergencyContactResponse(existing), nil
}

// parseServiceType menolak nilai di luar enum. Sengaja TIDAK jatuh diam-diam ke
// OTHER: salah klasifikasi pada nomor krisis harus terlihat oleh Admin saat
// menyimpan, bukan ditemukan mahasiswa saat butuh bantuan.
func parseServiceType(value string) (constants.ServiceType, error) {
	t := constants.ServiceType(value)
	if !t.IsValid() {
		return "", utils.NewError(utils.CodeInvalidEnum).WithDetails(map[string]any{
			"field":   "service_type",
			"allowed": constants.AllServiceTypes,
		})
	}
	return t, nil
}

func (u *emergencyContactUsecase) Delete(ctx context.Context, id string) error {
	return u.repo.Delete(ctx, id)
}
