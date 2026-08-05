package models

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// Dass21Result menyimpan hasil skrining DASS-21.
// Skor mentah tidak pernah dikirim ke dosen; yang dibagikan hanya arah
// perubahan (memburuk/membaik) dan severity sesuai tingkat privasi.
type Dass21Result struct {
	utils.BaseModel

	UserID string `gorm:"type:uuid;not null;index:idx_dass_user_taken,priority:1" json:"user_id"`

	DepressionScore int `gorm:"not null" json:"depression_score"`
	AnxietyScore    int `gorm:"not null" json:"anxiety_score"`
	StressScore     int `gorm:"not null" json:"stress_score"`

	DepressionSeverity constants.DassSeverity `gorm:"size:24;not null" json:"depression_severity"`
	AnxietySeverity    constants.DassSeverity `gorm:"size:24;not null" json:"anxiety_severity"`
	StressSeverity     constants.DassSeverity `gorm:"size:24;not null" json:"stress_severity"`

	TakenAt time.Time `gorm:"not null;index:idx_dass_user_taken,priority:2" json:"taken_at"`
}

func (Dass21Result) TableName() string { return "dass21_results" }

// TotalScore dipakai EWS untuk membandingkan dua skrining terakhir.
func (d *Dass21Result) TotalScore() int {
	return d.DepressionScore + d.AnxietyScore + d.StressScore
}

// HasSevere true bila salah satu subskala berada di Severe/Extremely Severe.
func (d *Dass21Result) HasSevere() bool {
	return d.DepressionSeverity.IsSevere() || d.AnxietySeverity.IsSevere() || d.StressSeverity.IsSevere()
}
