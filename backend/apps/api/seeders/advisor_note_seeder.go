package seeders

import (
	"context"

	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	mentormodels "github.com/gilabs/sanctuary/internal/mentor/data/models"
)

func (s *Seeder) seedAdvisorNotes(ctx context.Context, users SeededUsers) error {
	if len(users.Students) == 0 || users.Lecturer1.ID == "" {
		return nil
	}

	lecturerID := users.Lecturer1.ID
	student1 := users.Students[0]
	student2 := users.Students[1]

	now := apptime.Now()

	notes := []mentormodels.AdvisorNote{
		{
			MentorID:        lecturerID,
			StudentID:       student1.ID,
			InteractionDate: now.AddDate(0, 0, -2),
			Channel:         "TATAP_MUKA",
			Status:          "KONSULTASI",
			Note:            "Bimbingan tatap muka di ruang dosen. Diskusi progress revisi Bab 4 dan kendala istirahat.",
		},
		{
			MentorID:        lecturerID,
			StudentID:       student1.ID,
			InteractionDate: now.AddDate(0, 0, -5),
			Channel:         "WHATSAPP",
			Status:          "DISAPA",
			Note:            "Telah disapa via WhatsApp untuk menanyakan kabar tugas akhir.",
		},
		{
			MentorID:        lecturerID,
			StudentID:       student2.ID,
			InteractionDate: now.AddDate(0, 0, -3),
			Channel:         "TELEPON",
			Status:          "DIRUJUK",
			Note:            "Menyarankan mahasiswa untuk berkonsultasi ke Layanan Konseling Kampus.",
		},
	}

	for _, n := range notes {
		n.ID = deterministicID("advisor-note:" + n.MentorID + ":" + n.StudentID + ":" + n.Note)
		if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "id"}},
			DoNothing: true,
		}).Create(&n).Error; err != nil {
			return err
		}
	}
	return nil
}
