// Package seeders adalah SATU-SATUNYA tempat data demo/referensi dibuat.
// Request-path API tidak boleh membuat data seperti ini (api-configuration-standards.md).
//
// Struktur file mengikuti domain yang diisi, satu berkas satu tanggung jawab:
//
//	seeder.go                   orkestrasi + helper bersama
//	reference_seeder.go         roles & program studi
//	user_seeder.go              akun seluruh peran
//	profiles.go                 profil kondisi mahasiswa demo (satu sumber angka)
//	privacy_seeder.go           tingkat berbagi & izin
//	daily_metric_seeder.go      check-in mood 90 hari
//	journal_seeder.go           jurnal + analisis emosi sungguhan
//	dass_seeder.go              hasil skrining DASS-21 (diskor ulang oleh service)
//	contact_request_seeder.go   status "minta dihubungi"
//	chat_seeder.go              percakapan Terapis AI (mock)
//	emergency_contact_seeder.go layanan bantuan darurat
//
// Seluruh seeder bersifat idempotent: aman dijalankan berulang kali.
package seeders

import (
	"context"
	"fmt"
	"log"

	"github.com/google/uuid"
	"gorm.io/gorm"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
)

type Seeder struct {
	db  *gorm.DB
	cfg *config.Config
}

func New(db *gorm.DB, cfg *config.Config) *Seeder { return &Seeder{db: db, cfg: cfg} }

// SeededUsers memudahkan seeder lain merujuk aktor yang sudah dibuat.
type SeededUsers struct {
	Admin     authmodels.User
	Kaprodi   authmodels.User
	Lecturer1 authmodels.User
	Lecturer2 authmodels.User
	// Students[0..6] dibimbing Lecturer1 (7 orang, memenuhi k-anonymity)
	// Students[7..9] dibimbing Lecturer2 (3 orang, DI BAWAH ambang)
	Students []authmodels.User
	// Profiles sejajar indeks dengan Students. Disimpan di sini supaya
	// seedStudentData tidak perlu memelihara daftar profil kedua yang harus
	// dijaga tetap sinkron secara manual.
	Profiles []conditionProfile
}

func (s *Seeder) Run(ctx context.Context) error {
	log.Println("[seed] start")

	roles, err := s.seedRoles(ctx)
	if err != nil {
		return fmt.Errorf("roles: %w", err)
	}

	program, err := s.seedStudyProgram(ctx)
	if err != nil {
		return fmt.Errorf("study program: %w", err)
	}

	users, err := s.seedUsers(ctx, roles, program)
	if err != nil {
		return fmt.Errorf("users: %w", err)
	}

	if err := s.linkProgramHead(ctx, program, users.Kaprodi); err != nil {
		return fmt.Errorf("link kaprodi: %w", err)
	}

	if err := s.seedStudentData(ctx, users); err != nil {
		return fmt.Errorf("student data: %w", err)
	}

	if err := s.seedEmergencyContacts(ctx); err != nil {
		return fmt.Errorf("emergency contacts: %w", err)
	}

	s.printSummary(users)
	log.Println("[seed] done")
	return nil
}

// seedStudentData mengisi seluruh data milik mahasiswa, satu domain per method
// agar kegagalan menunjuk langsung ke bagian yang salah.
func (s *Seeder) seedStudentData(ctx context.Context, users SeededUsers) error {
	for i, student := range users.Students {
		profile := users.Profiles[i]

		if err := s.seedPrivacySetting(ctx, student.ID, profile); err != nil {
			return fmt.Errorf("privacy %s: %w", student.Email, err)
		}
		if err := s.seedDailyMetrics(ctx, student.ID, profile); err != nil {
			return fmt.Errorf("daily metrics %s: %w", student.Email, err)
		}
		if err := s.seedJournals(ctx, student.ID, profile); err != nil {
			return fmt.Errorf("journals %s: %w", student.Email, err)
		}
		if err := s.seedDassResults(ctx, student.ID, profile); err != nil {
			return fmt.Errorf("dass %s: %w", student.Email, err)
		}
		if profile.ChatSample {
			if err := s.seedChatSample(ctx, student.ID); err != nil {
				return fmt.Errorf("chat %s: %w", student.Email, err)
			}
		}
		if profile.ContactRequest && student.AdvisorID != nil {
			if err := s.seedContactRequest(ctx, student, *student.AdvisorID); err != nil {
				return fmt.Errorf("contact request %s: %w", student.Email, err)
			}
		}
	}
	return nil
}

// deterministicID membuat UUID stabil dari kunci logis, sehingga menjalankan
// ulang seeder tidak menghasilkan duplikat baris.
func deterministicID(key string) string {
	return uuid.NewSHA1(uuid.NameSpaceURL, []byte("sanctuary:"+key)).String()
}

func (s *Seeder) printSummary(users SeededUsers) {
	log.Println("──────────────────────────────────────────────")
	log.Printf("Akun demo (password: %s)", s.cfg.Seeder.DefaultPassword)
	log.Println("  admin@sanctuary.ac.id      → Admin (2 tab)")
	log.Println("  kaprodi@sanctuary.ac.id    → Kaprodi (4 tab)")
	log.Println("  dosen1@sanctuary.ac.id     → Dosen, 7 bimbingan (k-anonymity TERPENUHI, sebaran EWS tampil)")
	log.Println("  dosen2@sanctuary.ac.id     → Dosen, 3 bimbingan (k-anonymity TIDAK terpenuhi)")
	log.Printf("  mahasiswa1..10@sanctuary.ac.id → %d Mahasiswa (4 tab + Terapis AI)", len(users.Students))
	log.Println("──────────────────────────────────────────────")
}

func strPtr(v string) *string { return &v }
func intPtr(v int) *int       { return &v }
