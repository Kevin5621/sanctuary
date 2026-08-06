package seeders

import (
	"context"
	"fmt"

	"gorm.io/gorm/clause"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// studentSpec mendeskripsikan identitas satu mahasiswa demo.
// Profil kondisinya (mood, jurnal, DASS) berada di profiles.go dan dipasangkan
// berdasarkan urutan — index ke-n di sini memakai demoProfiles[n].
type studentSpec struct {
	Email         string
	FullName      string
	StudentNumber string
	CohortYear    int
}

// studentSpecs: 5 mahasiswa angkatan 2022 dibimbing Dosen 1 (kelompok memenuhi
// k-anonymity), 3 mahasiswa angkatan 2023 dibimbing Dosen 2 (DI BAWAH ambang,
// sehingga tab Kondisi dosen 2 harus menampilkan "Data belum cukup").
var studentSpecs = []studentSpec{
	{"mahasiswa1@sanctuary.ac.id", "Alya Prameswari", "220001", 2022},
	{"mahasiswa2@sanctuary.ac.id", "Bagas Nugraha", "220002", 2022},
	{"mahasiswa3@sanctuary.ac.id", "Citra Larasati", "220003", 2022},
	{"mahasiswa4@sanctuary.ac.id", "Dimas Prasetyo", "220004", 2022},
	{"mahasiswa5@sanctuary.ac.id", "Erika Handayani", "220005", 2022},
	{"mahasiswa6@sanctuary.ac.id", "Fajar Ramadhan", "220006", 2022},
	{"mahasiswa7@sanctuary.ac.id", "Gita Anindya", "220007", 2022},
	{"mahasiswa8@sanctuary.ac.id", "Hendra Wijaya", "230008", 2023},
	{"mahasiswa9@sanctuary.ac.id", "Intan Maharani", "230009", 2023},
	{"mahasiswa10@sanctuary.ac.id", "Joko Setiawan", "230010", 2023},
}

// adviseeSplit adalah jumlah mahasiswa pertama yang dibimbing Dosen 1.
// Nilainya sengaja di atas ambang k-anonymity (5) supaya kelompok Dosen 1
// tetap lolos meski satu-dua mahasiswa menolak ikut statistik.
const adviseeSplit = 7

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

	// Dijaga di runtime, bukan lewat komentar: menambah mahasiswa tanpa
	// menambah profilnya akan langsung berhenti di sini, bukan diam-diam
	// membuat akun tanpa data.
	if len(demoProfiles) != len(studentSpecs) {
		return SeededUsers{}, fmt.Errorf(
			"jumlah profil (%d) tidak cocok dengan jumlah mahasiswa (%d)",
			len(demoProfiles), len(studentSpecs),
		)
	}

	students := make([]authmodels.User, 0, len(studentSpecs))
	for i, spec := range studentSpecs {
		advisor := lecturer1
		if i >= adviseeSplit {
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
	}

	return SeededUsers{
		Admin:     admin,
		Kaprodi:   kaprodi,
		Lecturer1: lecturer1,
		Lecturer2: lecturer2,
		Students:  students,
		Profiles:  demoProfiles,
	}, nil
}

func (s *Seeder) upsertUser(ctx context.Context, user authmodels.User, passwordHash string) (authmodels.User, error) {
	user.ID = deterministicID("user:" + user.Email)
	user.PasswordHash = passwordHash
	user.IsActive = true

	err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "id"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"role_id", "full_name", "password_hash", "phone", "student_number", "cohort_year",
			"advisor_id", "lecturer_number", "study_program_id", "is_active", "updated_at",
		}),
	}).Create(&user).Error
	return user, err
}
