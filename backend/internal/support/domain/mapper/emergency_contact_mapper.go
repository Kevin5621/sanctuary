package mapper

import (
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/support/data/models"
	"github.com/gilabs/sanctuary/internal/support/domain/dto"
)

func ToEmergencyContactResponse(m *models.EmergencyContact) dto.EmergencyContactResponse {
	return dto.EmergencyContactResponse{
		ID:          m.ID,
		Name:        m.Name,
		Phone:       m.Phone,
		Description: m.Description,
		Is24Hours:   m.Is24Hours,
		IsActive:    m.IsActive,
		SortOrder:   m.SortOrder,
		UpdatedAt:   apptime.FormatDateTime(m.UpdatedAt),
	}
}

func ToEmergencyContactResponses(items []models.EmergencyContact) []dto.EmergencyContactResponse {
	out := make([]dto.EmergencyContactResponse, 0, len(items))
	for i := range items {
		out = append(out, ToEmergencyContactResponse(&items[i]))
	}
	return out
}
