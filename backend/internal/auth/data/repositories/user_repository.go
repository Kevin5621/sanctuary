package repositories

import (
	"context"
	"strings"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// UserFilter menyaring daftar pengguna pada halaman kelola akun Admin.
// RoleCodes kosong berarti seluruh peran.
type UserFilter struct {
	RoleCodes []string
	Search    string
	// ActiveOnly nil berarti aktif maupun nonaktif ikut ditampilkan — Admin
	// perlu melihat akun yang ia nonaktifkan, bukan kehilangan jejaknya.
	ActiveOnly *bool
}

type UserRepository interface {
	FindByEmail(ctx context.Context, email string) (*models.User, error)
	FindByID(ctx context.Context, id string) (*models.User, error)
	TouchLastLogin(ctx context.Context, tx *gorm.DB, userID string) error
	CountAdvisees(ctx context.Context, advisorID string) (int64, error)

	Create(ctx context.Context, user *models.User) error
	Update(ctx context.Context, user *models.User, fields map[string]any) error
	List(ctx context.Context, p utils.Pagination, filter UserFilter) ([]models.User, int64, error)

	// EmailTaken / StudentNumberTaken / LecturerNumberTaken dipakai untuk
	// memberi pesan per-field sebelum menabrak unique index. Index database
	// tetap penjaga terakhir terhadap race antara dua pendaftaran bersamaan.
	EmailTaken(ctx context.Context, email string, exceptUserID string) (bool, error)
	StudentNumberTaken(ctx context.Context, number string, exceptUserID string) (bool, error)
	LecturerNumberTaken(ctx context.Context, number string, exceptUserID string) (bool, error)
}

type userRepository struct{ db *gorm.DB }

func NewUserRepository(db *gorm.DB) UserRepository { return &userRepository{db: db} }

func (r *userRepository) FindByEmail(ctx context.Context, email string) (*models.User, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var user models.User
	err := r.db.WithContext(ctx).
		Preload("Role").
		Preload("StudyProgram").
		Where("lower(email) = ?", strings.ToLower(strings.TrimSpace(email))).
		First(&user).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, utils.CodeUserNotFound)
	}
	return &user, nil
}

func (r *userRepository) FindByID(ctx context.Context, id string) (*models.User, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var user models.User
	err := r.db.WithContext(ctx).
		Preload("Role").
		Preload("StudyProgram").
		Where("id = ?", id).
		First(&user).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, utils.CodeUserNotFound)
	}
	return &user, nil
}

func (r *userRepository) TouchLastLogin(ctx context.Context, tx *gorm.DB, userID string) error {
	db := r.db
	if tx != nil {
		db = tx
	}
	err := db.WithContext(ctx).Model(&models.User{}).
		Where("id = ?", userID).
		UpdateColumn("last_login_at", gorm.Expr("now()")).Error
	return utils.TranslateDBError(err, "")
}

func (r *userRepository) CountAdvisees(ctx context.Context, advisorID string) (int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var total int64
	err := r.db.WithContext(ctx).Model(&models.User{}).
		Where("advisor_id = ? AND is_active = true", advisorID).
		Count(&total).Error
	return total, utils.TranslateDBError(err, "")
}

func (r *userRepository) Create(ctx context.Context, user *models.User) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	return utils.TranslateDBError(r.db.WithContext(ctx).Create(user).Error, "")
}

// Update memakai map kolom, bukan struct, karena sebagian field yang boleh
// diubah bernilai zero-value yang sah (is_active=false, cohort_year kosong)
// dan akan dibuang GORM bila dikirim sebagai struct.
func (r *userRepository) Update(ctx context.Context, user *models.User, fields map[string]any) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	res := r.db.WithContext(ctx).Model(&models.User{}).
		Where("id = ?", user.ID).
		Updates(fields)
	if res.Error != nil {
		return utils.TranslateDBError(res.Error, "")
	}
	if res.RowsAffected == 0 {
		return utils.NewError(utils.CodeUserNotFound)
	}
	return nil
}

var userSortWhitelist = map[string]string{
	"name":    "users.full_name",
	"email":   "users.email",
	"created": "users.created_at",
	"status":  "users.is_active",
}

func (r *userRepository) List(ctx context.Context, p utils.Pagination, filter UserFilter) ([]models.User, int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	query := r.db.WithContext(ctx).Model(&models.User{}).
		Joins("JOIN roles ON roles.id = users.role_id")

	if len(filter.RoleCodes) > 0 {
		query = query.Where("roles.code IN ?", filter.RoleCodes)
	}
	if filter.ActiveOnly != nil {
		query = query.Where("users.is_active = ?", *filter.ActiveOnly)
	}
	if search := strings.TrimSpace(filter.Search); search != "" {
		pattern := "%" + search + "%"
		query = query.Where(
			"users.full_name ILIKE ? OR users.email ILIKE ? OR users.lecturer_number ILIKE ?",
			pattern, pattern, pattern,
		)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, utils.TranslateDBError(err, "")
	}

	var users []models.User
	err := query.
		Preload("Role").
		Preload("StudyProgram").
		Order(utils.SafeOrderBy(p.SortBy, p.SortDir, userSortWhitelist, "users.full_name")).
		Limit(p.PerPage).Offset(p.Offset()).
		Find(&users).Error
	return users, total, utils.TranslateDBError(err, "")
}

func (r *userRepository) EmailTaken(ctx context.Context, email, exceptUserID string) (bool, error) {
	return r.exists(ctx, "lower(email) = ?", strings.ToLower(strings.TrimSpace(email)), exceptUserID)
}

func (r *userRepository) StudentNumberTaken(ctx context.Context, number, exceptUserID string) (bool, error) {
	return r.exists(ctx, "student_number = ?", strings.TrimSpace(number), exceptUserID)
}

func (r *userRepository) LecturerNumberTaken(ctx context.Context, number, exceptUserID string) (bool, error) {
	return r.exists(ctx, "lecturer_number = ?", strings.TrimSpace(number), exceptUserID)
}

func (r *userRepository) exists(ctx context.Context, condition string, value any, exceptUserID string) (bool, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	query := r.db.WithContext(ctx).Model(&models.User{}).Where(condition, value)
	if exceptUserID != "" {
		query = query.Where("id <> ?", exceptUserID)
	}

	var total int64
	err := query.Limit(1).Count(&total).Error
	return total > 0, utils.TranslateDBError(err, "")
}
