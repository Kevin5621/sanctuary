package models

import "github.com/gilabs/sanctuary/internal/core/utils"

// StudentChatMessage adalah KONTEN PRIVAT (Terapis AI).
// Tahap ini hanya UI mock: respons AI dihasilkan mock service di backend,
// belum ada integrasi LLM. Aturan akses sama ketatnya dengan jurnal.
type StudentChatMessage struct {
	utils.BaseModel

	UserID    string `gorm:"type:uuid;not null;index:idx_chat_user_session,priority:1" json:"user_id"`
	SessionID string `gorm:"type:uuid;not null;index:idx_chat_user_session,priority:2" json:"session_id"`

	// Sender: USER | AI
	Sender  string `gorm:"size:8;not null" json:"sender"`
	Content string `gorm:"type:text;not null" json:"content"` // PRIVAT — owner only

	IsCrisisFlagged bool `gorm:"not null;default:false" json:"is_crisis_flagged"`
}

func (StudentChatMessage) TableName() string { return "student_chat_messages" }

const (
	ChatSenderUser = "USER"
	ChatSenderAI   = "AI"
)
