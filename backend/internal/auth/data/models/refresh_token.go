package models

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/utils"
)

// RefreshToken menyimpan hash (bukan token mentah) untuk mendukung rotasi
// dan pencabutan. Rotasi memakai row-level locking (SELECT ... FOR UPDATE).
type RefreshToken struct {
	utils.BaseModel

	UserID    string `gorm:"type:uuid;index;not null" json:"user_id"`
	TokenHash string `gorm:"size:64;uniqueIndex;not null" json:"-"`

	ExpiresAt time.Time  `gorm:"index;not null" json:"expires_at"`
	RevokedAt *time.Time `gorm:"index" json:"revoked_at,omitempty"`
	// ReplacedByID menjaga jejak rantai rotasi (deteksi token reuse).
	ReplacedByID *string `gorm:"type:uuid" json:"replaced_by_id,omitempty"`

	UserAgent string `gorm:"size:255" json:"user_agent,omitempty"`
	IPAddress string `gorm:"size:64" json:"ip_address,omitempty"`
}

func (RefreshToken) TableName() string { return "refresh_tokens" }

func (t *RefreshToken) IsUsable(now time.Time) bool {
	return t.RevokedAt == nil && now.Before(t.ExpiresAt)
}
