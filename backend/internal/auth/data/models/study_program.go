package models

import "github.com/gilabs/sanctuary/internal/core/utils"

// StudyProgram (Program Studi) adalah unit agregasi untuk dashboard Kaprodi.
// Seluruh statistik prodi tunduk pada ambang k-anonymity.
type StudyProgram struct {
	utils.BaseModel
	Code       string  `gorm:"size:32;uniqueIndex;not null" json:"code"`
	Name       string  `gorm:"size:128;not null" json:"name"`
	Faculty    string  `gorm:"size:128" json:"faculty"`
	HeadUserID *string `gorm:"type:uuid;index" json:"head_user_id,omitempty"` // Kaprodi
}

func (StudyProgram) TableName() string { return "study_programs" }
