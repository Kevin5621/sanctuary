package mapper

import (
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

func ToChatMessage(m *models.StudentChatMessage) dto.ChatMessageResponse {
	return dto.ChatMessageResponse{
		ID:              m.ID,
		Sender:          m.Sender,
		Text:            m.Content,
		IsCrisisFlagged: m.IsCrisisFlagged,
		CreatedAt:       apptime.FormatDateTime(m.CreatedAt),
	}
}

func ToChatMessages(items []models.StudentChatMessage) []dto.ChatMessageResponse {
	out := make([]dto.ChatMessageResponse, 0, len(items))
	for i := range items {
		out = append(out, ToChatMessage(&items[i]))
	}
	return out
}

// ToConsentStatus menyusun state gate yang dibaca klien.
//
// consent == nil berarti mahasiswa belum pernah memutuskan (PENDING).
// Perhatikan bahwa CanChat dihitung DI SINI dari model, bukan disusun ulang
// oleh klien: hanya ada satu definisi "boleh chat" di seluruh sistem, dan
// definisi itu sama dengan yang dipakai gate di usecase.
func ToConsentStatus(consent *models.AIChatConsent, notice dto.ConsentNoticeResponse, serviceAvailable bool) dto.ConsentStatusResponse {
	response := dto.ConsentStatusResponse{
		Status:           "PENDING",
		NoticeVersion:    models.CurrentNoticeVersion,
		Notice:           notice,
		ServiceAvailable: serviceAvailable,
	}

	if consent == nil {
		return response
	}

	response.Status = consent.Status
	response.DecidedAt = strPtr(apptime.FormatDateTime(consent.DecidedAt))
	response.ConsentedAt = apptime.FormatDateTimePtr(consent.ConsentedAt)

	// Persetujuan atas pemberitahuan versi lama tidak memberi izin baru.
	response.NeedsRenewal = consent.Status == models.ConsentStatusGranted &&
		consent.NoticeVersion != models.CurrentNoticeVersion

	response.CanChat = consent.AllowsProcessing() && serviceAvailable
	return response
}

func strPtr(v string) *string { return &v }
