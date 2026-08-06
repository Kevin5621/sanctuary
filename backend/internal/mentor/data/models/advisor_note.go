package models

import (
	"time"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/core/utils"
)

// AdvisorNote merepresentasikan catatan pendampingan privat dosen.
type AdvisorNote struct {
	utils.BaseModel

	MentorID        string         `gorm:"type:uuid;not null;index:idx_advisor_notes_mentor_student" json:"mentor_id"`
	StudentID       string         `gorm:"type:uuid;not null;index:idx_advisor_notes_mentor_student" json:"student_id"`
	InteractionDate time.Time      `gorm:"not null;default:now()" json:"interaction_date"`
	Channel         string         `gorm:"size:32;not null;default:'TATAP_MUKA'" json:"channel"`
	Status          string         `gorm:"size:32;not null;default:'DISAPA'" json:"status"`
	Note            string         `gorm:"type:text;not null" json:"note"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}

func (AdvisorNote) TableName() string { return "advisor_notes" }
