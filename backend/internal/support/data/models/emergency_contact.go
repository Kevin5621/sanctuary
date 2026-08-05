package models

import "github.com/gilabs/sanctuary/internal/core/utils"

// EmergencyContact adalah layanan nomor darurat/krisis yang dikelola Admin
// dan dibaca seluruh peran (khususnya layar Bantuan Darurat mahasiswa).
type EmergencyContact struct {
	utils.BaseModel
	utils.SoftDelete

	Name        string `gorm:"size:128;not null" json:"name"`
	Phone       string `gorm:"size:32;not null" json:"phone"`
	Description string `gorm:"size:500" json:"description,omitempty"`

	Is24Hours bool `gorm:"not null;default:false" json:"is_24_hours"`
	IsActive  bool `gorm:"not null;default:true;index" json:"is_active"`
	SortOrder int  `gorm:"not null;default:0;index" json:"sort_order"`
}

func (EmergencyContact) TableName() string { return "emergency_contacts" }
