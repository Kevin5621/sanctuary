package models

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/utils"
)

// StudentDailyMetric adalah check-in harian mahasiswa (satu baris per tanggal).
// Kolom di sini bersifat kuantitatif dan boleh diagregasi; catatan bebas
// tetap disimpan terpisah di student_journals sebagai konten privat.
type StudentDailyMetric struct {
	utils.BaseModel

	UserID     string    `gorm:"type:uuid;not null;uniqueIndex:idx_metric_user_date,priority:1" json:"user_id"`
	MetricDate time.Time `gorm:"type:date;not null;uniqueIndex:idx_metric_user_date,priority:2;index" json:"metric_date"`

	MoodScore   int     `gorm:"not null" json:"mood_score"`   // 1..5 (1 = sangat buruk)
	StressLevel int     `gorm:"not null" json:"stress_level"` // 1..5 (5 = sangat tertekan)
	SleepHours  float64 `gorm:"type:numeric(3,1);not null" json:"sleep_hours"`

	// AcademicTrigger: pemicu akademik (TUGAS, UJIAN, SKRIPSI, PRESENTASI, dll).
	AcademicTrigger string `gorm:"size:32;index" json:"academic_trigger,omitempty"`
	// EmotionLabel: emosi dominan yang dipilih mahasiswa saat check-in.
	EmotionLabel string `gorm:"size:24;index" json:"emotion_label,omitempty"`
}

func (StudentDailyMetric) TableName() string { return "student_daily_metrics" }
