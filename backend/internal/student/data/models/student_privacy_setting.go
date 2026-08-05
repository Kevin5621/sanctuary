package models

import (
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// StudentPrivacySetting adalah kontrol privasi granular milik mahasiswa.
// Satu baris per mahasiswa; menjadi gerbang seluruh akses dosen/kaprodi.
type StudentPrivacySetting struct {
	utils.BaseModel

	UserID string `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`

	// ShareLevel: CLOSED | SUMMARY | SUMMARY_TREND
	ShareLevel constants.ShareLevel `gorm:"size:24;not null;default:'CLOSED'" json:"share_level"`

	// Permission terpisah dari ShareLevel.
	AllowEarlyWarning     bool `gorm:"not null;default:false" json:"allow_early_warning"`     // Peringatan Dini ke Pembimbing
	AllowProgramStatistic bool `gorm:"not null;default:false" json:"allow_program_statistic"` // Ikut Statistik Prodi
}

func (StudentPrivacySetting) TableName() string { return "student_privacy_settings" }

// DefaultPrivacySetting: privacy-first — default paling tertutup.
func DefaultPrivacySetting(userID string) *StudentPrivacySetting {
	return &StudentPrivacySetting{
		UserID:                userID,
		ShareLevel:            constants.ShareLevelClosed,
		AllowEarlyWarning:     false,
		AllowProgramStatistic: false,
	}
}

// CanShareIndicator: gerbang utama sebelum indikator apa pun dikirim ke dosen.
func (s *StudentPrivacySetting) CanShareIndicator() bool {
	return s != nil && s.ShareLevel.AllowsIndicator()
}

func (s *StudentPrivacySetting) CanShareTrend() bool {
	return s != nil && s.ShareLevel.AllowsTrend()
}

// CanSendEarlyWarning: EWS hanya dikirim bila level berbagi memadai DAN
// mahasiswa mengizinkan peringatan dini secara eksplisit.
func (s *StudentPrivacySetting) CanSendEarlyWarning() bool {
	return s.CanShareIndicator() && s.AllowEarlyWarning
}
