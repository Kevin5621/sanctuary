package utils

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// BaseModel di-embed seluruh model: UUID primary key + timestamps otomatis.
type BaseModel struct {
	ID        string    `gorm:"type:uuid;primaryKey" json:"id"`
	CreatedAt time.Time `gorm:"not null" json:"created_at"`
	UpdatedAt time.Time `gorm:"not null" json:"updated_at"`
}

// BeforeCreate mengisi UUID bila belum di-set (mis. oleh seeder).
func (b *BaseModel) BeforeCreate(_ *gorm.DB) error {
	if b.ID == "" {
		b.ID = uuid.NewString()
	}
	return nil
}

// SoftDelete di-embed pada model yang membutuhkan penghapusan lunak.
type SoftDelete struct {
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}
