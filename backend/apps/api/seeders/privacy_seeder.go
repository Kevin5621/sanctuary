package seeders

import (
	"context"

	"gorm.io/gorm/clause"

	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
)

// seedPrivacySetting menetapkan tingkat berbagi tiap mahasiswa demo.
//
// Nilai di sini sengaja berbeda-beda antar akun agar seluruh cabang aturan
// privasi punya akun yang mewakilinya: Tertutup, Ringkasan, Ringkasan + Tren,
// serta kombinasi izin peringatan dini dan statistik prodi yang dimatikan.
func (s *Seeder) seedPrivacySetting(ctx context.Context, studentID string, profile conditionProfile) error {
	setting := studentmodels.StudentPrivacySetting{
		UserID:                studentID,
		ShareLevel:            profile.ShareLevel,
		AllowEarlyWarning:     profile.AllowEarlyWarning,
		AllowProgramStatistic: profile.AllowProgramStatistic,
	}
	setting.ID = deterministicID("privacy:" + studentID)

	return s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "user_id"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"share_level", "allow_early_warning", "allow_program_statistic", "updated_at",
		}),
	}).Create(&setting).Error
}
