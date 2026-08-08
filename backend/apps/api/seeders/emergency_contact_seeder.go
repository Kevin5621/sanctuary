package seeders

import (
	"context"

	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/core/constants"
	supportmodels "github.com/gilabs/sanctuary/internal/support/data/models"
)

// seedEmergencyContacts mengisi daftar Layanan Bantuan Darurat.
//
// CATATAN OPERASIONAL: nomor bertanda [VERIFIKASI] adalah placeholder internal
// kampus dan WAJIB diganti/diverifikasi tim Admin sebelum rilis produksi.
// Menampilkan nomor krisis yang salah lebih berbahaya daripada tidak menampilkan.
func (s *Seeder) seedEmergencyContacts(ctx context.Context) error {
	contacts := []supportmodels.EmergencyContact{
		{
			Name:        "SEJIWA: Layanan Sehat Jiwa Kemenkes",
			Phone:       "119",
			Description: "Hubungi 119 lalu tekan ekstensi 8. Layanan konseling psikologis nasional.",
			ServiceType: constants.ServiceNationalHotline,
			Is24Hours:   true,
			IsActive:    true,
			SortOrder:   1,
		},
		{
			Name:        "Panggilan Darurat Nasional",
			Phone:       "112",
			Description: "Nomor darurat terpadu untuk situasi yang mengancam keselamatan jiwa.",
			ServiceType: constants.ServiceEmergency,
			Is24Hours:   true,
			IsActive:    true,
			SortOrder:   2,
		},
		{
			Name:        "Unit Konseling Mahasiswa (Kampus)",
			Phone:       "(021) 5550-0100",
			Description: "[VERIFIKASI] Konseling tatap muka & daring. Senin–Jumat, 08.00–16.00 WIB.",
			ServiceType: constants.ServiceCampusCounseling,
			Is24Hours:   false,
			IsActive:    true,
			SortOrder:   3,
		},
		{
			Name:        "Dosen Pembimbing Akademik",
			Phone:       "(021) 5550-0101",
			Description: "[VERIFIKASI] Konsultasi akademik dan rujukan awal ke unit konseling.",
			ServiceType: constants.ServiceAcademicAdvisor,
			Is24Hours:   false,
			IsActive:    true,
			SortOrder:   4,
		},
		{
			Name:        "Klinik Kesehatan Kampus",
			Phone:       "(021) 5550-0102",
			Description: "[VERIFIKASI] Pemeriksaan kesehatan umum dan rujukan psikiatri.",
			ServiceType: constants.ServiceCampusHealth,
			Is24Hours:   false,
			IsActive:    true,
			SortOrder:   5,
		},
		{
			Name:        "Hotline Sementara (nonaktif)",
			Phone:       "(021) 5550-0199",
			Description: "Contoh entri nonaktif, dipakai menguji filter is_active pada aplikasi mahasiswa.",
			ServiceType: constants.ServiceOther,
			Is24Hours:   false,
			IsActive:    false,
			SortOrder:   99,
		},
	}

	for i := range contacts {
		contacts[i].ID = deterministicID("emergency:" + contacts[i].Phone + ":" + contacts[i].Name)

		if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "id"}},
			DoUpdates: clause.AssignmentColumns([]string{
				"name", "phone", "description", "service_type",
				"is_24_hours", "is_active", "sort_order", "updated_at",
			}),
		}).Create(&contacts[i]).Error; err != nil {
			return err
		}
	}
	return nil
}
