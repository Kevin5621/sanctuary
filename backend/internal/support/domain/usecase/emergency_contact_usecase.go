package usecase

import (
	"context"

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
	Get(ctx context.Context, id string) (dto.EmergencyContactResponse, error)
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

func (u *emergencyContactUsecase) Get(ctx context.Context, id string) (dto.EmergencyContactResponse, error) {
	contact, err := u.repo.FindByID(ctx, id)
	if err != nil {
		return dto.EmergencyContactResponse{}, err
	}
	return mapper.ToEmergencyContactResponse(contact), nil
}

func (u *emergencyContactUsecase) Create(ctx context.Context, req dto.CreateEmergencyContactRequest) (dto.EmergencyContactResponse, error) {
	contact := &models.EmergencyContact{
		Name:        req.Name,
		Phone:       req.Phone,
		Description: req.Description,
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
	existing, err := u.repo.FindByID(ctx, id)
	if err != nil {
		return dto.EmergencyContactResponse{}, err
	}

	existing.Name = req.Name
	existing.Phone = req.Phone
	existing.Description = req.Description
	existing.Is24Hours = req.Is24Hours
	existing.IsActive = *req.IsActive
	existing.SortOrder = req.SortOrder

	if err := u.repo.Update(ctx, existing); err != nil {
		return dto.EmergencyContactResponse{}, err
	}
	return mapper.ToEmergencyContactResponse(existing), nil
}

func (u *emergencyContactUsecase) Delete(ctx context.Context, id string) error {
	return u.repo.Delete(ctx, id)
}
