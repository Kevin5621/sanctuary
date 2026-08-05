package dto

import "github.com/gilabs/sanctuary/internal/core/constants"

type CreateEmergencyContactRequest struct {
	Name        string `json:"name" binding:"required,min=3,max=128"`
	Phone       string `json:"phone" binding:"required,min=3,max=32"`
	Description string `json:"description" binding:"omitempty,max=500"`
	// ServiceType wajib dipilih Admin dari daftar tertutup (A-BAN-01).
	ServiceType string `json:"service_type" binding:"required"`
	Is24Hours   bool   `json:"is_24_hours"`
	IsActive    *bool  `json:"is_active" binding:"required"`
	SortOrder   int    `json:"sort_order" binding:"gte=0,lte=999"`
}

type UpdateEmergencyContactRequest struct {
	Name        string `json:"name" binding:"required,min=3,max=128"`
	Phone       string `json:"phone" binding:"required,min=3,max=32"`
	Description string `json:"description" binding:"omitempty,max=500"`
	ServiceType string `json:"service_type" binding:"required"`
	Is24Hours   bool   `json:"is_24_hours"`
	IsActive    *bool  `json:"is_active" binding:"required"`
	SortOrder   int    `json:"sort_order" binding:"gte=0,lte=999"`
}

type EmergencyContactResponse struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Phone       string `json:"phone"`
	Description string `json:"description,omitempty"`

	ServiceType      string `json:"service_type"`
	ServiceTypeLabel string `json:"service_type_label"`

	Is24Hours bool `json:"is_24_hours"`
	IsActive  bool `json:"is_active"`
	SortOrder int  `json:"sort_order"`

	// NeedsVerification diturunkan dari penanda [VERIFIKASI] pada keterangan
	// (A-BAN-04). Diangkat menjadi boolean supaya klien memberi badge
	// peringatan tanpa harus mem-parsing teks — nomor krisis yang belum
	// terverifikasi tidak boleh tampil seolah-olah sudah pasti benar.
	NeedsVerification bool `json:"needs_verification"`

	UpdatedAt string `json:"updated_at"`
}

// ServiceTypeOptionResponse mengisi dropdown "jenis layanan" pada form Admin,
// sehingga daftar pilihan berasal dari server (satu sumber kebenaran) alih-alih
// ditulis ulang di klien.
type ServiceTypeOptionResponse struct {
	Value string `json:"value"`
	Label string `json:"label"`
}

func ServiceTypeOptions() []ServiceTypeOptionResponse {
	out := make([]ServiceTypeOptionResponse, 0, len(constants.AllServiceTypes))
	for _, t := range constants.AllServiceTypes {
		out = append(out, ServiceTypeOptionResponse{Value: t.String(), Label: t.Label()})
	}
	return out
}
