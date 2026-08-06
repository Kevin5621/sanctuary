package models

import (
	"github.com/gilabs/sanctuary/internal/core/utils"
	"gorm.io/datatypes"
)

// AuditLog mencatat aksi sensitif — terutama setiap kali Dosen/Kaprodi membuka
// indikator kondisi mahasiswa. Payload TIDAK BOLEH memuat teks jurnal/chat.
type AuditLog struct {
	utils.BaseModel

	ActorID    string `gorm:"type:uuid;index;not null" json:"actor_id"`
	ActorRole  string `gorm:"size:32;index;not null" json:"actor_role"`
	Action     string `gorm:"size:64;index;not null" json:"action"`
	Resource   string `gorm:"size:64;index;not null" json:"resource"`
	ResourceID string `gorm:"type:uuid;index" json:"resource_id,omitempty"`

	Metadata  datatypes.JSON `gorm:"type:jsonb" json:"metadata,omitempty"`
	IPAddress string         `gorm:"size:64" json:"ip_address,omitempty"`
	RequestID string         `gorm:"size:64;index" json:"request_id,omitempty"`
}

func (AuditLog) TableName() string { return "audit_logs" }

// Aksi audit yang dipakai domain.
const (
	ActionViewStudentIndicator = "VIEW_STUDENT_INDICATOR"
	ActionViewAggregate        = "VIEW_AGGREGATE"
	ActionUpdatePrivacy        = "UPDATE_PRIVACY_SETTING"
	ActionLogin                = "LOGIN"
	ActionLogout               = "LOGOUT"
	ActionRegister             = "REGISTER"
	ActionCreateUser           = "CREATE_USER"
	ActionUpdateUser           = "UPDATE_USER"
)
