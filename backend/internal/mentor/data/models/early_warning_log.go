package models

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"gorm.io/datatypes"
)

// EarlyWarningLog adalah snapshot hasil kalkulasi EWS oleh server.
// Disimpan agar: (1) daftar bimbingan dapat di-sort cepat tanpa hitung ulang,
// (2) ada jejak historis perubahan level, (3) tidak ada teks jurnal tersimpan.
type EarlyWarningLog struct {
	utils.BaseModel

	StudentID string `gorm:"type:uuid;not null;index:idx_ews_student_evaluated,priority:1" json:"student_id"`
	// AdvisorID adalah snapshot pembimbing saat evaluasi dijalankan.
	AdvisorID *string `gorm:"type:uuid;index" json:"advisor_id,omitempty"`

	Score int                `gorm:"not null" json:"score"` // 0..4
	Level constants.EWSLevel `gorm:"size:24;not null;index" json:"level"`

	// Indicators berisi rincian per indikator (kode, terpicu, nilai terukur).
	// TIDAK BOLEH memuat teks jurnal/chat.
	Indicators datatypes.JSON `gorm:"type:jsonb" json:"indicators"`

	IsSufficient bool `gorm:"not null;default:false" json:"is_sufficient"`
	DataPoints   int  `gorm:"not null;default:0" json:"data_points"`

	// DassSevere menandai pemicu langsung level INTERVENTION.
	DassSevere bool `gorm:"not null;default:false" json:"dass_severe"`

	EvaluatedAt time.Time `gorm:"not null;index:idx_ews_student_evaluated,priority:2,sort:desc" json:"evaluated_at"`
}

func (EarlyWarningLog) TableName() string { return "early_warning_logs" }
