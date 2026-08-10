package repositories

import (
	"context"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// AdvisorBrief adalah identitas seorang pembimbing sebatas yang boleh
// ditampilkan ke mahasiswa bimbingannya dan ke kaprodi: nama dan nomor induk.
//
// Tidak memuat satu pun atribut kondisi — relasi bimbingan adalah data
// administratif.
type AdvisorBrief struct {
	AdvisorID      string `gorm:"column:advisor_id"`
	FullName       string `gorm:"column:full_name"`
	LecturerNumber string `gorm:"column:lecturer_number"`
	Email          string `gorm:"column:email"`
}

// StudentAdvisorRepository membaca pasangan mahasiswa–pembimbing.
//
// Penulisannya TIDAK ada di sini melainkan di program repository, karena setiap
// perubahan alokasi hanya sah dalam cakupan program studi kaprodi yang
// melakukannya.
type StudentAdvisorRepository interface {
	// ListForStudent mengembalikan pembimbing aktif seorang mahasiswa,
	// terurut sesuai urutan penugasan.
	ListForStudent(ctx context.Context, studentID string) ([]AdvisorBrief, error)
	// ListForStudents adalah versi batch untuk daftar (menghindari N+1).
	ListForStudents(ctx context.Context, studentIDs []string) (map[string][]AdvisorBrief, error)
	// AdviseeIDs adalah id seluruh mahasiswa bimbingan seorang dosen.
	AdviseeIDs(ctx context.Context, advisorID string) ([]string, error)
	CountAdvisees(ctx context.Context, advisorID string) (int64, error)
	// IsAdvisorOf dipakai gerbang akses dosen ke satu mahasiswa.
	IsAdvisorOf(ctx context.Context, advisorID, studentID string) (bool, error)
}

type studentAdvisorRepository struct{ db *gorm.DB }

func NewStudentAdvisorRepository(db *gorm.DB) StudentAdvisorRepository {
	return &studentAdvisorRepository{db: db}
}

// advisorBriefSelect dipakai bersama agar bentuk proyeksinya identik di semua
// jalur baca.
const advisorBriefSelect = `student_advisors.advisor_id       AS advisor_id,
	                        advisors.full_name                AS full_name,
	                        COALESCE(advisors.lecturer_number, '') AS lecturer_number,
	                        advisors.email                    AS email`

func (r *studentAdvisorRepository) ListForStudent(ctx context.Context, studentID string) ([]AdvisorBrief, error) {
	rows, err := r.ListForStudents(ctx, []string{studentID})
	if err != nil {
		return nil, err
	}
	if advisors, ok := rows[studentID]; ok {
		return advisors, nil
	}
	return []AdvisorBrief{}, nil
}

func (r *studentAdvisorRepository) ListForStudents(
	ctx context.Context,
	studentIDs []string,
) (map[string][]AdvisorBrief, error) {
	out := map[string][]AdvisorBrief{}
	if len(studentIDs) == 0 {
		return out, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	type row struct {
		StudentID string `gorm:"column:student_id"`
		AdvisorBrief
	}

	var rows []row
	err := r.db.WithContext(ctx).Model(&models.StudentAdvisor{}).
		Select("student_advisors.student_id AS student_id, " + advisorBriefSelect).
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

func (r *studentAdvisorRepository) AdviseeIDs(ctx context.Context, advisorID string) ([]string, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var ids []string
	err := r.db.WithContext(ctx).Model(&models.StudentAdvisor{}).
		Joins("JOIN users ON users.id = student_advisors.student_id").
		Where("student_advisors.advisor_id = ?", advisorID).
		Where("users.is_active = true AND users.deleted_at IS NULL").
		Pluck("student_advisors.student_id", &ids).Error
	return ids, utils.TranslateDBError(err, "")
}

func (r *studentAdvisorRepository) CountAdvisees(ctx context.Context, advisorID string) (int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var total int64
	err := r.db.WithContext(ctx).Model(&models.StudentAdvisor{}).
		Joins("JOIN users ON users.id = student_advisors.student_id").
		Where("student_advisors.advisor_id = ?", advisorID).
		Where("users.is_active = true AND users.deleted_at IS NULL").
		Count(&total).Error
	return total, utils.TranslateDBError(err, "")
}

func (r *studentAdvisorRepository) IsAdvisorOf(ctx context.Context, advisorID, studentID string) (bool, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var total int64
	err := r.db.WithContext(ctx).Model(&models.StudentAdvisor{}).
		Where("advisor_id = ? AND student_id = ?", advisorID, studentID).
		Limit(1).Count(&total).Error
	return total > 0, utils.TranslateDBError(err, "")
}
