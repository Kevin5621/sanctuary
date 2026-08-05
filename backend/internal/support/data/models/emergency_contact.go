package models

import (
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// EmergencyContact adalah layanan nomor darurat/krisis yang dikelola Admin
// dan dibaca seluruh peran (khususnya layar Bantuan Darurat mahasiswa).
type EmergencyContact struct {
	utils.BaseModel
	utils.SoftDelete

	Name        string `gorm:"size:128;not null" json:"name"`
	Phone       string `gorm:"size:32;not null" json:"phone"`
	Description string `gorm:"size:500" json:"description,omitempty"`

	// ServiceType (A-BAN-01) ditambahkan lewat migrasi
	// 20260806120000_add_service_type_to_emergency_contacts.sql.
	// Default 'OTHER' agar baris lama tetap valid tanpa tebakan klasifikasi.
	ServiceType constants.ServiceType `gorm:"size:32;not null;default:'OTHER';index" json:"service_type"`

	// column:is_24_hours eksplisit — naming strategy default GORM menghasilkan
	// "is24_hours" (tanpa underscore sebelum angka), berbeda dari migrasi SQL
	// manual (migrations/*.sql) yang memakai "is_24_hours". Tag ini menjaga
	// AutoMigrate (dev) dan Atlas SQL (staging/prod) tetap satu skema.
	Is24Hours bool `gorm:"column:is_24_hours;not null;default:false" json:"is_24_hours"`
	// Tanpa tag "default:" secara sengaja — lihat catatan pada User.IsActive
	// (internal/auth/data/models/user.go) untuk alasannya.
	IsActive  bool `gorm:"not null;index" json:"is_active"`
	SortOrder int  `gorm:"not null;default:0;index" json:"sort_order"`
}

func (EmergencyContact) TableName() string { return "emergency_contacts" }
