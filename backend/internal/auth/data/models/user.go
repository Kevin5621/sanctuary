package models

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/utils"
)

// User adalah satu tabel untuk seluruh peran; atribut spesifik peran bersifat nullable.
//
// Relasi kunci privasi:
//   - AdvisorID: dosen pembimbing seorang mahasiswa. Semua endpoint dosen
//     memfilter berdasarkan kolom ini (dosen hanya melihat bimbingannya sendiri).
//   - StudyProgramID: cakupan agregasi Kaprodi.
type User struct {
	utils.BaseModel
	utils.SoftDelete

	RoleID string `gorm:"type:uuid;index;not null" json:"role_id"`
	Role   *Role  `gorm:"foreignKey:RoleID" json:"role,omitempty"`

	FullName     string `gorm:"size:128;not null" json:"full_name"`
	Email        string `gorm:"size:160;uniqueIndex;not null" json:"email"`
	PasswordHash string `gorm:"size:255;not null" json:"-"`
	Phone        string `gorm:"size:32" json:"phone,omitempty"`
	AvatarURL    string `gorm:"size:255" json:"avatar_url,omitempty"`

	// Atribut mahasiswa
	StudentNumber *string `gorm:"size:32;uniqueIndex" json:"student_number,omitempty"` // NIM
	CohortYear    *int    `gorm:"index" json:"cohort_year,omitempty"`                  // Angkatan
	AdvisorID     *string `gorm:"type:uuid;index" json:"advisor_id,omitempty"`
	Advisor       *User   `gorm:"foreignKey:AdvisorID" json:"advisor,omitempty"`

	// Atribut dosen / kaprodi
	LecturerNumber *string `gorm:"size:32;uniqueIndex" json:"lecturer_number,omitempty"` // NIDN

	StudyProgramID *string       `gorm:"type:uuid;index" json:"study_program_id,omitempty"`
	StudyProgram   *StudyProgram `gorm:"foreignKey:StudyProgramID" json:"study_program,omitempty"`

	// Tanpa tag "default:" secara sengaja: GORM membuang field bool bernilai
	// false (zero-value Go) dari INSERT saat ada tag default pada Create()
	// berbasis struct, sehingga false diam-diam tertulis sebagai true.
	// Default true tetap berlaku di level SQL (lihat migrations/*.sql);
	// kode aplikasi selalu meng-set nilai ini eksplisit sebelum Create.
	IsActive    bool       `gorm:"not null;index" json:"is_active"`
	LastLoginAt *time.Time `json:"last_login_at,omitempty"`
}

func (User) TableName() string { return "users" }

// RoleCode aman dipanggil walau relasi Role belum di-preload.
func (u *User) RoleCode() string {
	if u.Role == nil {
		return ""
	}
	return u.Role.Code
}
