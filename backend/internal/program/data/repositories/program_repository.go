package repositories

import (
	"context"

	"gorm.io/gorm"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
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

type ProgramRepository interface {
	// ConsentedStudentIDs mengembalikan mahasiswa prodi yang MENGIZINKAN
	// datanya ikut statistik prodi (allow_program_statistic = true).
	// Mahasiswa tanpa baris privasi otomatis tidak ikut (default privacy-first).
	ConsentedStudentIDs(ctx context.Context, programID string, cohortYear *int) ([]string, error)
	// TotalStudents adalah populasi prodi (dipakai layar Profil kaprodi).
	TotalStudents(ctx context.Context, programID string) (int, error)
	AdvisorLoads(ctx context.Context, programID string) ([]AdvisorLoad, error)
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
		Joins(`LEFT JOIN users AS advisees
		       ON advisees.advisor_id = users.id
		       AND advisees.is_active = true
		       AND advisees.deleted_at IS NULL`).
		Where("users.study_program_id = ? AND users.is_active = true", programID).
		Where("roles.code = ?", constants.RoleLecturer).
		Group("users.id, users.full_name, users.lecturer_number, users.email").
		Order("advisee_count DESC").
		Scan(&loads).Error
	return loads, utils.TranslateDBError(err, "")
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
