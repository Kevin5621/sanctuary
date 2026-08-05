package mapper

import (
	"strings"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/support/data/models"
	"github.com/gilabs/sanctuary/internal/support/domain/dto"
)

func ToEmergencyContactResponse(m *models.EmergencyContact) dto.EmergencyContactResponse {
	serviceType := constants.NormalizeServiceType(m.ServiceType.String())

	return dto.EmergencyContactResponse{
		ID:          m.ID,
		Name:        m.Name,
		Phone:       m.Phone,
		Description: m.Description,

		ServiceType:      serviceType.String(),
		ServiceTypeLabel: serviceType.Label(),

		Is24Hours: m.Is24Hours,
		IsActive:  m.IsActive,
		SortOrder: m.SortOrder,

		NeedsVerification: needsVerification(m.Description),

		UpdatedAt: apptime.FormatDateTime(m.UpdatedAt),
	}
}

func ToEmergencyContactResponses(items []models.EmergencyContact) []dto.EmergencyContactResponse {
	out := make([]dto.EmergencyContactResponse, 0, len(items))
	for i := range items {
		out = append(out, ToEmergencyContactResponse(&items[i]))
	}
	return out
}

// needsVerification mendeteksi penanda [VERIFIKASI] pada keterangan (A-BAN-04).
// Pencocokan case-insensitive agar Admin yang mengetik "[verifikasi]" tetap
// mendapat badge peringatan — gagal-aman ke arah "tandai", bukan "sembunyikan".
func needsVerification(description string) bool {
	return strings.Contains(
		strings.ToUpper(description),
		constants.VerificationMarker,
	)
}
