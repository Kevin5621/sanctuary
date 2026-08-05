package models

import "github.com/gilabs/sanctuary/internal/core/utils"

// Role adalah master peran (STUDENT, LECTURER, HEAD_OF_PROGRAM, ADMIN).
type Role struct {
	utils.BaseModel
	Code        string `gorm:"size:32;uniqueIndex;not null" json:"code"`
	Name        string `gorm:"size:64;not null" json:"name"`
	Description string `gorm:"size:255" json:"description"`
}

func (Role) TableName() string { return "roles" }
