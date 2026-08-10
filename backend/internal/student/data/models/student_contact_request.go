package models

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/utils"
)

// StudentContactRequest adalah status "minta dihubungi" yang dipicu mahasiswa.
// Ini satu-satunya kanal inisiatif mahasiswa yang tampil di layar dosen,
// dan tidak membawa konten jurnal apa pun.
//
// SENGAJA TANPA kolom advisor_id: tujuannya bukan satu dosen tertentu melainkan
// seluruh pembimbing mahasiswa itu, dan keanggotaannya dibaca dari
// student_advisors saat query. Membekukan satu tujuan akan menyembunyikan
// permintaan yang masih terbuka dari pembimbing yang baru ditambahkan.
type StudentContactRequest struct {
	utils.BaseModel

	StudentID string `gorm:"type:uuid;not null;index" json:"student_id"`

	// Status: OPEN | HANDLED | CANCELLED
	Status string `gorm:"size:16;not null;default:'OPEN';index" json:"status"`
	// Note bersifat opsional & singkat, ditulis sadar oleh mahasiswa untuk dosen.
	Note string `gorm:"size:280" json:"note,omitempty"`

	HandledAt *time.Time `json:"handled_at,omitempty"`
}

func (StudentContactRequest) TableName() string { return "student_contact_requests" }

const (
	ContactRequestOpen      = "OPEN"
	ContactRequestHandled   = "HANDLED"
	ContactRequestCancelled = "CANCELLED"
)
