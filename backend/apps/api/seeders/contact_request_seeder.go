package seeders

import (
	"context"

	"gorm.io/gorm/clause"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
)

// seedContactRequest membuat satu permintaan "minta dihubungi" yang terbuka.
//
// Note diisi untuk memastikan kolomnya benar-benar terisi di basis data —
// justru supaya dapat dibuktikan bahwa jalur dosen tetap tidak menampilkannya
// (dosen hanya menerima nama dan waktu).
func (s *Seeder) seedContactRequest(ctx context.Context, student authmodels.User, advisorID string) error {
	request := studentmodels.StudentContactRequest{
		StudentID: student.ID,
		AdvisorID: advisorID,
		Status:    studentmodels.ContactRequestOpen,
		Note:      "Ingin berdiskusi soal beban tugas minggu ini.",
	}
	request.ID = deterministicID("contact-request:" + student.ID)

	return s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "id"}},
		DoNothing: true,
	}).Create(&request).Error
}
