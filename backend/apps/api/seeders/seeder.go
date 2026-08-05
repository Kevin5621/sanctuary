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
	"gorm.io/gorm/clause"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
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
		profile := demoProfiles[i]

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

// studentSpec mendeskripsikan satu mahasiswa demo beserta profil kondisinya.
type studentSpec struct {
	Email         string
	FullName      string
	StudentNumber string
	CohortYear    int
	// Advisor2 menandai mahasiswa bimbingan Dosen 2. Ditulis eksplisit per
	// baris — bukan disimpulkan dari indeks — agar menambah/menggeser
	// mahasiswa tidak diam-diam memindahkan bimbingan orang lain.
	Advisor2 bool
	Profile  conditionProfile
}

func (s *Seeder) seedUsers(
	ctx context.Context,
	roles map[constants.Role]authmodels.Role,
	program authmodels.StudyProgram,
) (SeededUsers, error) {
	passwordHash, err := utils.HashPassword(s.cfg.Seeder.DefaultPassword)
	if err != nil {
		return SeededUsers{}, err
	}

	admin, err := s.upsertUser(ctx, authmodels.User{
		RoleID:   roles[constants.RoleAdmin].ID,
		FullName: "Rani Administrator",
		Email:    "admin@sanctuary.ac.id",
		Phone:    "081100000001",
	}, passwordHash)
	if err != nil {
		return SeededUsers{}, err
	}

	kaprodi, err := s.upsertUser(ctx, authmodels.User{
		RoleID:         roles[constants.RoleHeadOfProgram].ID,
		FullName:       "Dr. Bayu Kaprodi",
		Email:          "kaprodi@sanctuary.ac.id",
		Phone:          "081100000002",
		LecturerNumber: strPtr("0011224401"),
		StudyProgramID: &program.ID,
	}, passwordHash)
	if err != nil {
		return SeededUsers{}, err
	}

	lecturer1, err := s.upsertUser(ctx, authmodels.User{
		RoleID:         roles[constants.RoleLecturer].ID,
		FullName:       "Dr. Sinta Pembimbing",
		Email:          "dosen1@sanctuary.ac.id",
		Phone:          "081100000003",
		LecturerNumber: strPtr("0011224402"),
		StudyProgramID: &program.ID,
	}, passwordHash)
	if err != nil {
		return SeededUsers{}, err
	}

	lecturer2, err := s.upsertUser(ctx, authmodels.User{
		RoleID:         roles[constants.RoleLecturer].ID,
		FullName:       "Ahmad Pembimbing, M.Psi.",
		Email:          "dosen2@sanctuary.ac.id",
		Phone:          "081100000004",
		LecturerNumber: strPtr("0011224403"),
		StudyProgramID: &program.ID,
	}, passwordHash)
	if err != nil {
		return SeededUsers{}, err
	}

	// Komposisi kelompok sengaja dirancang agar SETIAP cabang k-anonymity punya
	// kasus uji nyata:
	//
	//   Dosen 1 — 7 bimbingan angkatan 2022
	//     · 7 berbagi indikator            -> tab Kondisi TAMPIL (k >= 5)
	//     · 6 mengizinkan peringatan dini  -> sebaran tingkat perhatian TAMPIL
	//     · 1 berbagi tapi menolak EWS     -> menguji jalur "peringatan dini off"
	//
	//   Dosen 2 — 3 bimbingan angkatan 2023
	//     · hanya 2 berbagi indikator      -> tab Kondisi "Data belum cukup"
	//     · 1 Tertutup + 1 minta dihubungi -> menguji D-7 dan L-BIM-05
	//
	//   Kaprodi — 8 peserta statistik prodi -> dashboard TAMPIL
	//     · angkatan 2022: 7 peserta       -> laporan angkatan TAMPIL
	//     · angkatan 2023: 1 peserta       -> laporan angkatan "Data belum cukup"
	//
	// Mahasiswa 9 & 10 ada khusus untuk kasus kedua: tanpa keduanya hanya 4
	// bimbingan Dosen 1 yang mengizinkan peringatan dini, sehingga sebaran
	// tingkat perhatian (L-KON-02) tidak pernah lolos ambang dan fitur itu
	// mustahil diverifikasi dengan data demo.
	specs := []studentSpec{
		{"mahasiswa1@sanctuary.ac.id", "Alya Prameswari", "220001", 2022, false, profileIntervention},
		{"mahasiswa2@sanctuary.ac.id", "Bagas Nugraha", "220002", 2022, false, profileRisk},
		{"mahasiswa3@sanctuary.ac.id", "Citra Larasati", "220003", 2022, false, profileWatch},
		{"mahasiswa4@sanctuary.ac.id", "Dimas Prasetyo", "220004", 2022, false, profileNormal},
		{"mahasiswa5@sanctuary.ac.id", "Erika Handayani", "220005", 2022, false, profileNormalSummaryOnly},
		{"mahasiswa9@sanctuary.ac.id", "Indah Puspita", "220009", 2022, false, profileNormalAlerting},
		{"mahasiswa10@sanctuary.ac.id", "Joko Santoso", "220010", 2022, false, profileWatchAlerting},
		{"mahasiswa6@sanctuary.ac.id", "Fajar Ramadhan", "230006", 2023, true, profileClosed},
		{"mahasiswa7@sanctuary.ac.id", "Gita Anindya", "230007", 2023, true, profileWatchWithRequest},
		{"mahasiswa8@sanctuary.ac.id", "Hendra Wijaya", "230008", 2023, true, profileInsufficient},
	}

	students := make([]authmodels.User, 0, len(specs))
	profiles := make([]conditionProfile, 0, len(specs))
	for i, spec := range specs {
		advisor := lecturer1
		if spec.Advisor2 {
			advisor = lecturer2
		}

		student, err := s.upsertUser(ctx, authmodels.User{
			RoleID:         roles[constants.RoleStudent].ID,
			FullName:       spec.FullName,
			Email:          spec.Email,
			Phone:          fmt.Sprintf("08120000%04d", i+1),
			StudentNumber:  strPtr(spec.StudentNumber),
			CohortYear:     intPtr(spec.CohortYear),
			AdvisorID:      &advisor.ID,
			StudyProgramID: &program.ID,
		}, passwordHash)
		if err != nil {
			return SeededUsers{}, err
		}
		students = append(students, student)
		profiles = append(profiles, spec.Profile)
	}

	return SeededUsers{
		Admin:     admin,
		Kaprodi:   kaprodi,
		Lecturer1: lecturer1,
		Lecturer2: lecturer2,
		Students:  students,
		Profiles:  profiles,
	}, nil
}

func (s *Seeder) upsertUser(ctx context.Context, user authmodels.User, passwordHash string) (authmodels.User, error) {
	user.ID = deterministicID("user:" + user.Email)
	user.PasswordHash = passwordHash
	user.IsActive = true

	err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "id"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"role_id", "full_name", "phone", "student_number", "cohort_year",
			"advisor_id", "lecturer_number", "study_program_id", "is_active", "updated_at",
		}),
	}).Create(&user).Error
	return user, err
}

func (s *Seeder) linkProgramHead(ctx context.Context, program authmodels.StudyProgram, kaprodi authmodels.User) error {
	return s.db.WithContext(ctx).Model(&authmodels.StudyProgram{}).
		Where("id = ?", program.ID).
		Update("head_user_id", kaprodi.ID).Error
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
