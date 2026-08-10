package repositories

import (
	"context"
	"slices"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// AdvisorLoad adalah beban bimbingan seorang dosen (tab Pembimbing).
type AdvisorLoad struct {
	AdvisorID      string `gorm:"column:advisor_id" json:"advisor_id"`
	FullName       string `gorm:"column:full_name" json:"full_name"`
	LecturerNumber string `gorm:"column:lecturer_number" json:"lecturer_number"`
	Email          string `gorm:"column:email" json:"email"`
	AdviseeCount   int    `gorm:"column:advisee_count" json:"advisee_count"`
}

// CohortCount dipakai laporan evaluasi per angkatan.
type CohortCount struct {
	CohortYear   int `gorm:"column:cohort_year" json:"cohort_year"`
	StudentCount int `gorm:"column:student_count" json:"student_count"`
}

// AdviseeInfo membawa data mahasiswa pembimbing (administratif).
//
// Pembimbingnya TIDAK di sini: seorang mahasiswa dapat punya lebih dari satu,
// jadi daftarnya diambil terpisah lewat AdvisorsForStudents agar tidak ada baris
// mahasiswa yang terduplikasi hanya karena jumlah pembimbingnya.
type AdviseeInfo struct {
	ID            string `gorm:"column:id" json:"id"`
	FullName      string `gorm:"column:full_name" json:"full_name"`
	StudentNumber string `gorm:"column:student_number" json:"student_number"`
	Email         string `gorm:"column:email" json:"email"`
}

type ProgramRepository interface {
	// ConsentedStudentIDs mengembalikan mahasiswa prodi yang MENGIZINKAN
	// datanya ikut statistik prodi (allow_program_statistic = true).
	// Mahasiswa tanpa baris privasi otomatis tidak ikut (default privacy-first).
	ConsentedStudentIDs(ctx context.Context, programID string, cohortYear *int) ([]string, error)
	// TotalStudents adalah populasi prodi (dipakai layar Profil kaprodi).
	TotalStudents(ctx context.Context, programID string) (int, error)
	// ProgramName dipakai judul layar Profil kaprodi.
	ProgramName(ctx context.Context, programID string) (string, error)
	AdvisorLoads(ctx context.Context, programID string) ([]AdvisorLoad, error)
	AdviseesByAdvisor(ctx context.Context, advisorID string) ([]AdviseeInfo, error)
	StudentsInProgram(ctx context.Context, programID string) ([]AdviseeInfo, error)
	// AdvisorsForStudents memetakan id mahasiswa → pembimbingnya (bisa lebih
	// dari satu), dipakai daftar mahasiswa prodi.
	AdvisorsForStudents(ctx context.Context, studentIDs []string) (map[string][]authrepo.AdvisorBrief, error)
	// SetAdviseesForAdvisor menyetel PERSIS daftar bimbingan seorang dosen.
	// Pasangan dengan dosen LAIN tidak tersentuh — melepas satu dosen tidak
	// boleh diam-diam melepas pembimbing kedua mahasiswa itu.
	SetAdviseesForAdvisor(ctx context.Context, programID, advisorID string, studentIDs []string, actorID string) error
	// SetAdvisorsForStudent menyetel persis daftar pembimbing seorang mahasiswa.
	SetAdvisorsForStudent(ctx context.Context, programID, studentID string, advisorIDs []string, actorID string) error
	CohortCounts(ctx context.Context, programID string) ([]CohortCount, error)
}

type programRepository struct{ db *gorm.DB }

func NewProgramRepository(db *gorm.DB) ProgramRepository { return &programRepository{db: db} }

func (r *programRepository) ConsentedStudentIDs(ctx context.Context, programID string, cohortYear *int) ([]string, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	query := r.db.WithContext(ctx).Model(&authmodels.User{}).
		Joins("JOIN roles ON roles.id = users.role_id").
		Joins("JOIN student_privacy_settings sps ON sps.user_id = users.id").
		Where("users.study_program_id = ?", programID).
		Where("users.is_active = true AND users.deleted_at IS NULL").
		Where("roles.code = ?", constants.RoleStudent).
		Where("sps.allow_program_statistic = true")

	if cohortYear != nil {
		query = query.Where("users.cohort_year = ?", *cohortYear)
	}

	var ids []string
	err := query.Pluck("users.id", &ids).Error
	return ids, utils.TranslateDBError(err, "")
}

func (r *programRepository) TotalStudents(ctx context.Context, programID string) (int, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var count int64
	err := r.db.WithContext(ctx).Model(&authmodels.User{}).
		Joins("JOIN roles ON roles.id = users.role_id").
		Where("users.study_program_id = ? AND users.is_active = true", programID).
		Where("roles.code = ?", constants.RoleStudent).
		Count(&count).Error
	return int(count), utils.TranslateDBError(err, "")
}

func (r *programRepository) ProgramName(ctx context.Context, programID string) (string, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var name string
	err := r.db.WithContext(ctx).Model(&authmodels.StudyProgram{}).
		Where("id = ?", programID).
		Limit(1).
		Pluck("name", &name).Error
	return name, utils.TranslateDBError(err, "")
}

func (r *programRepository) AdvisorLoads(ctx context.Context, programID string) ([]AdvisorLoad, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var loads []AdvisorLoad
	err := r.db.WithContext(ctx).Model(&authmodels.User{}).
		Select(`users.id AS advisor_id,
		        users.full_name,
		        COALESCE(users.lecturer_number, '') AS lecturer_number,
		        users.email,
		        COUNT(advisees.id) AS advisee_count`).
		Joins("JOIN roles ON roles.id = users.role_id").
		Joins("LEFT JOIN student_advisors ON student_advisors.advisor_id = users.id").
		Joins(`LEFT JOIN users AS advisees
		       ON advisees.id = student_advisors.student_id
		       AND advisees.is_active = true
		       AND advisees.deleted_at IS NULL`).
		Where("users.study_program_id = ? AND users.is_active = true", programID).
		Where("roles.code = ?", constants.RoleLecturer).
		Group("users.id, users.full_name, users.lecturer_number, users.email").
		Order("advisee_count DESC").
		Scan(&loads).Error
	return loads, utils.TranslateDBError(err, "")
}

func (r *programRepository) AdviseesByAdvisor(ctx context.Context, advisorID string) ([]AdviseeInfo, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var students []AdviseeInfo
	err := r.db.WithContext(ctx).Model(&authmodels.User{}).
		Select(`users.id,
		        users.full_name,
		        COALESCE(users.student_number, '') AS student_number,
		        users.email`).
		Joins("JOIN roles ON roles.id = users.role_id").
		Joins("JOIN student_advisors ON student_advisors.student_id = users.id").
		Where("student_advisors.advisor_id = ?", advisorID).
		Where("users.is_active = true AND users.deleted_at IS NULL").
		Where("roles.code = ?", constants.RoleStudent).
		Order("users.full_name ASC").
		Scan(&students).Error

	return students, utils.TranslateDBError(err, "")
}

func (r *programRepository) StudentsInProgram(ctx context.Context, programID string) ([]AdviseeInfo, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var students []AdviseeInfo
	err := r.db.WithContext(ctx).Model(&authmodels.User{}).
		Select(`users.id,
		        users.full_name,
		        COALESCE(users.student_number, '') AS student_number,
		        users.email`).
		Joins("JOIN roles ON roles.id = users.role_id").
		Where("users.study_program_id = ? AND users.is_active = true AND users.deleted_at IS NULL", programID).
		Where("roles.code = ?", constants.RoleStudent).
		Order("users.full_name ASC").
		Scan(&students).Error

	return students, utils.TranslateDBError(err, "")
}

func (r *programRepository) AdvisorsForStudents(
	ctx context.Context,
	studentIDs []string,
) (map[string][]authrepo.AdvisorBrief, error) {
	out := map[string][]authrepo.AdvisorBrief{}
	if len(studentIDs) == 0 {
		return out, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	type row struct {
		StudentID string `gorm:"column:student_id"`
		authrepo.AdvisorBrief
	}

	var rows []row
	err := r.db.WithContext(ctx).Model(&authmodels.StudentAdvisor{}).
		Select(`student_advisors.student_id       AS student_id,
		        student_advisors.advisor_id       AS advisor_id,
		        advisors.full_name                AS full_name,
		        COALESCE(advisors.lecturer_number, '') AS lecturer_number,
		        advisors.email                    AS email`).
		Joins("JOIN users AS advisors ON advisors.id = student_advisors.advisor_id").
		Where("student_advisors.student_id IN ?", studentIDs).
		Where("advisors.is_active = true AND advisors.deleted_at IS NULL").
		Order("student_advisors.assigned_at ASC, advisors.full_name ASC").
		Scan(&rows).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, "")
	}

	for _, item := range rows {
		out[item.StudentID] = append(out[item.StudentID], item.AdvisorBrief)
	}
	return out, nil
}

func (r *programRepository) SetAdviseesForAdvisor(
	ctx context.Context,
	programID, advisorID string,
	studentIDs []string,
	actorID string,
) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	if err := r.assertLecturerInProgram(ctx, programID, advisorID); err != nil {
		return err
	}
	valid, err := r.filterStudentsInProgram(ctx, programID, studentIDs)
	if err != nil {
		return err
	}

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Hanya pasangan milik dosen ini yang dihapus. Mahasiswa yang juga
		// dibimbing dosen lain tetap memegang pembimbing keduanya.
		del := tx.Where("advisor_id = ?", advisorID)
		if len(valid) > 0 {
			del = del.Where("student_id NOT IN ?", valid)
		}
		if err := del.Delete(&authmodels.StudentAdvisor{}).Error; err != nil {
			return err
		}

		pairs := make([]authmodels.StudentAdvisor, 0, len(valid))
		for _, studentID := range valid {
			pairs = append(pairs, newPair(studentID, advisorID, actorID))
		}
		return insertPairs(tx, pairs)
	})
}

func (r *programRepository) SetAdvisorsForStudent(
	ctx context.Context,
	programID, studentID string,
	advisorIDs []string,
	actorID string,
) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	students, err := r.filterStudentsInProgram(ctx, programID, []string{studentID})
	if err != nil {
		return err
	}
	if len(students) == 0 {
		return utils.NewError(utils.CodeInvalidQueryParam).WithDetails(map[string]any{
			"reason": "mahasiswa tidak ditemukan di program studi ini",
		})
	}
	for _, advisorID := range advisorIDs {
		if err := r.assertLecturerInProgram(ctx, programID, advisorID); err != nil {
			return err
		}
	}

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		del := tx.Where("student_id = ?", studentID)
		if len(advisorIDs) > 0 {
			del = del.Where("advisor_id NOT IN ?", advisorIDs)
		}
		if err := del.Delete(&authmodels.StudentAdvisor{}).Error; err != nil {
			return err
		}

		pairs := make([]authmodels.StudentAdvisor, 0, len(advisorIDs))
		for _, advisorID := range advisorIDs {
			pairs = append(pairs, newPair(studentID, advisorID, actorID))
		}
		return insertPairs(tx, pairs)
	})
}

// assertLecturerInProgram menolak alokasi ke dosen di luar prodi kaprodi —
// tanpa ini, id dosen mana pun dari klien akan diterima apa adanya.
func (r *programRepository) assertLecturerInProgram(ctx context.Context, programID, advisorID string) error {
	var count int64
	err := r.db.WithContext(ctx).Model(&authmodels.User{}).
		Joins("JOIN roles ON roles.id = users.role_id").
		Where("users.id = ? AND users.study_program_id = ? AND users.is_active = true", advisorID, programID).
		Where("roles.code = ?", constants.RoleLecturer).
		Count(&count).Error
	if err != nil {
		return utils.TranslateDBError(err, "")
	}
	if count == 0 {
		return utils.NewError(utils.CodeInvalidQueryParam).WithDetails(map[string]any{
			"reason": "dosen pembimbing tidak ditemukan di program studi ini",
		})
	}
	return nil
}

// filterStudentsInProgram membuang id yang bukan mahasiswa aktif prodi ini,
// sekaligus menghilangkan duplikat dari klien.
func (r *programRepository) filterStudentsInProgram(
	ctx context.Context,
	programID string,
	studentIDs []string,
) ([]string, error) {
	if len(studentIDs) == 0 {
		return nil, nil
	}

	var valid []string
	err := r.db.WithContext(ctx).Model(&authmodels.User{}).
		Joins("JOIN roles ON roles.id = users.role_id").
		Where("users.id IN ? AND users.study_program_id = ?", studentIDs, programID).
		Where("users.is_active = true AND users.deleted_at IS NULL").
		Where("roles.code = ?", constants.RoleStudent).
		Pluck("users.id", &valid).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, "")
	}

	slices.Sort(valid)
	return slices.Compact(valid), nil
}

func newPair(studentID, advisorID, actorID string) authmodels.StudentAdvisor {
	pair := authmodels.StudentAdvisor{
		StudentID:  studentID,
		AdvisorID:  advisorID,
		AssignedAt: apptime.Now(),
	}
	if actorID != "" {
		pair.AssignedBy = &actorID
	}
	return pair
}

// insertPairs memakai DoNothing pada konflik: menyimpan ulang alokasi yang sama
// adalah operasi wajar dari UI (centang ulang), bukan galat.
func insertPairs(tx *gorm.DB, pairs []authmodels.StudentAdvisor) error {
	if len(pairs) == 0 {
		return nil
	}
	return tx.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "student_id"}, {Name: "advisor_id"}},
		DoNothing: true,
	}).Create(&pairs).Error
}

func (r *programRepository) CohortCounts(ctx context.Context, programID string) ([]CohortCount, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var counts []CohortCount
	err := r.db.WithContext(ctx).Model(&authmodels.User{}).
		Select("users.cohort_year, COUNT(*) AS student_count").
		Joins("JOIN roles ON roles.id = users.role_id").
		Where("users.study_program_id = ? AND users.is_active = true", programID).
		Where("roles.code = ? AND users.cohort_year IS NOT NULL", constants.RoleStudent).
		Group("users.cohort_year").
		Order("users.cohort_year DESC").
		Scan(&counts).Error
	return counts, utils.TranslateDBError(err, "")
}
