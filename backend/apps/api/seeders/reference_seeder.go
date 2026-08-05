package seeders

import (
	"context"

	"gorm.io/gorm/clause"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/constants"
)

// Data referensi: peran dan program studi. Keduanya bukan data demo melainkan
// prasyarat aplikasi — tanpa baris ini tidak ada akun yang bisa dibuat.

func (s *Seeder) seedRoles(ctx context.Context) (map[constants.Role]authmodels.Role, error) {
	descriptions := map[constants.Role]string{
		constants.RoleStudent:       "Mahasiswa — pemilik data mood, jurnal, dan chat AI",
		constants.RoleLecturer:      "Dosen Pembimbing — hanya melihat indikator sesuai izin mahasiswa",
		constants.RoleHeadOfProgram: "Kaprodi — hanya melihat agregat prodi dengan ambang k-anonymity",
		constants.RoleAdmin:         "Admin — mengelola layanan bantuan darurat",
	}

	result := make(map[constants.Role]authmodels.Role, len(constants.AllRoles))
	for _, code := range constants.AllRoles {
		role := authmodels.Role{
			Code:        code.String(),
			Name:        code.DisplayName(),
			Description: descriptions[code],
		}
		role.ID = deterministicID("role:" + code.String())

		if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "code"}},
			DoUpdates: clause.AssignmentColumns([]string{"name", "description", "updated_at"}),
		}).Create(&role).Error; err != nil {
			return nil, err
		}
		result[code] = role
	}
	return result, nil
}

func (s *Seeder) seedStudyProgram(ctx context.Context) (authmodels.StudyProgram, error) {
	program := authmodels.StudyProgram{
		Code:    "TI",
		Name:    "Teknik Informatika",
		Faculty: "Fakultas Teknologi Informasi",
	}
	program.ID = deterministicID("program:TI")

	err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "code"}},
		DoUpdates: clause.AssignmentColumns([]string{"name", "faculty", "updated_at"}),
	}).Create(&program).Error
	return program, err
}

func (s *Seeder) linkProgramHead(ctx context.Context, program authmodels.StudyProgram, kaprodi authmodels.User) error {
	return s.db.WithContext(ctx).Model(&authmodels.StudyProgram{}).
		Where("id = ?", program.ID).
		Update("head_user_id", kaprodi.ID).Error
}
