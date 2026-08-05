package models

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/utils"
)

// StudentJournal adalah KONTEN PRIVAT.
//
// Aturan keras: kolom Content tidak boleh keluar dari endpoint mana pun selain
// endpoint mahasiswa pemiliknya (/students/me/journals...). Repository jurnal
// SELALU memfilter user_id dari token dan tidak menyediakan query lintas user.
type StudentJournal struct {
	utils.BaseModel
	utils.SoftDelete

	UserID  string `gorm:"type:uuid;index:idx_journal_user_created,priority:1;not null" json:"user_id"`
	Title   string `gorm:"size:160" json:"title,omitempty"`
	Content string `gorm:"type:text;not null" json:"content"` // PRIVAT — owner only

	// Hasil analisis emosi (mock analyzer; nanti diganti model NLP).
	EmotionLabel      string     `gorm:"size:24;index" json:"emotion_label,omitempty"`
	EmotionConfidence *float64   `gorm:"type:numeric(4,3)" json:"emotion_confidence,omitempty"`
	SentimentScore    *float64   `gorm:"type:numeric(4,3)" json:"sentiment_score,omitempty"`
	IsCrisisFlagged   bool       `gorm:"not null;default:false;index" json:"is_crisis_flagged"`
	AnalyzedAt        *time.Time `json:"analyzed_at,omitempty"`

	JournalDate time.Time `gorm:"type:date;not null;index:idx_journal_user_created,priority:2" json:"journal_date"`
}

func (StudentJournal) TableName() string { return "student_journals" }
