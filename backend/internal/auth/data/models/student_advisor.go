package models

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/utils"
)

// StudentAdvisor adalah pasangan mahasiswa–dosen pembimbing.
//
// Satu mahasiswa boleh punya lebih dari satu pembimbing, dan satu dosen tetap
// membimbing banyak mahasiswa. Relasi ini SATU-SATUNYA sumber kebenaran soal
// "siapa membimbing siapa": tidak ada lagi kolom users.advisor_id.
//
// Seluruh pembimbing pada satu mahasiswa setara — tidak ada pembimbing utama
// yang melihat lebih banyak. Membedakan haknya akan membuat janji privasi ke
// mahasiswa ("pembimbingmu melihat X") jadi mustahil dirumuskan dalam satu
// kalimat yang jujur.
type StudentAdvisor struct {
	utils.BaseModel

	StudentID string `gorm:"type:uuid;not null;uniqueIndex:idx_student_advisors_pair" json:"student_id"`
	AdvisorID string `gorm:"type:uuid;not null;uniqueIndex:idx_student_advisors_pair;index" json:"advisor_id"`

	// AssignedBy adalah kaprodi yang mengalokasikan; NULL untuk baris hasil
	// migrasi dari kolom lama.
	AssignedBy *string   `gorm:"type:uuid" json:"assigned_by,omitempty"`
	AssignedAt time.Time `gorm:"not null" json:"assigned_at"`

	Student *User `gorm:"foreignKey:StudentID" json:"-"`
	Advisor *User `gorm:"foreignKey:AdvisorID" json:"advisor,omitempty"`
}

func (StudentAdvisor) TableName() string { return "student_advisors" }
