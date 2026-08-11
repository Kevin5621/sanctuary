package usecase

import (
	"context"
	"errors"
	"time"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// ------------------------------------------------------------------
// Repository palsu untuk pengujian usecase auth.
//
// Seluruhnya di memori: yang diuji di sini adalah aturan yang menjaga siapa
// boleh menjadi apa (peran pendaftar, keunikan identitas, batas kelola akun),
// bukan SQL-nya.
// ------------------------------------------------------------------

type fakeUserRepo struct {
	created     []*models.User
	updated     map[string]any
	byID        map[string]*models.User
	emailTaken  bool
	numberTaken bool
	createErr   error
}

func newFakeUserRepo() *fakeUserRepo {
	return &fakeUserRepo{byID: map[string]*models.User{}}
}

func (f *fakeUserRepo) FindByEmail(context.Context, string) (*models.User, error) {
	return nil, utils.NewError(utils.CodeUserNotFound)
}

func (f *fakeUserRepo) FindByID(_ context.Context, id string) (*models.User, error) {
	if user, ok := f.byID[id]; ok {
		return user, nil
	}
	return nil, utils.NewError(utils.CodeUserNotFound)
}

func (f *fakeUserRepo) TouchLastLogin(context.Context, *gorm.DB, string) error { return nil }

func (f *fakeUserRepo) Create(_ context.Context, user *models.User) error {
	if f.createErr != nil {
		return f.createErr
	}
	if user.ID == "" {
		user.ID = "generated-id"
	}
	f.created = append(f.created, user)
	f.byID[user.ID] = user
	return nil
}

func (f *fakeUserRepo) Update(_ context.Context, user *models.User, fields map[string]any) error {
	f.updated = fields
	if stored, ok := f.byID[user.ID]; ok {
		if active, exists := fields["is_active"].(bool); exists {
			stored.IsActive = active
		}
	}
	return nil
}

func (f *fakeUserRepo) List(context.Context, utils.Pagination, repositories.UserFilter) ([]models.User, int64, error) {
	return nil, 0, nil
}

func (f *fakeUserRepo) EmailTaken(context.Context, string, string) (bool, error) {
	return f.emailTaken, nil
}

func (f *fakeUserRepo) StudentNumberTaken(context.Context, string, string) (bool, error) {
	return f.numberTaken, nil
}

func (f *fakeUserRepo) LecturerNumberTaken(context.Context, string, string) (bool, error) {
	return f.numberTaken, nil
}

// ------------------------------------------------------------------

type fakeRoleRepo struct{ err error }

func (f *fakeRoleRepo) FindByCode(_ context.Context, code constants.Role) (*models.Role, error) {
	if f.err != nil {
		return nil, f.err
	}
	role := &models.Role{Code: code.String(), Name: code.DisplayName()}
	role.ID = "role-" + code.String()
	return role, nil
}

// ------------------------------------------------------------------

type fakeProgramRepo struct{ missing bool }

func (f *fakeProgramRepo) List(context.Context) ([]models.StudyProgram, error) {
	program := models.StudyProgram{Code: "TI", Name: "Teknik Informatika"}
	program.ID = testProgramID
	return []models.StudyProgram{program}, nil
}

func (f *fakeProgramRepo) FindByID(_ context.Context, id string) (*models.StudyProgram, error) {
	if f.missing {
		return nil, utils.NewError(utils.CodeStudyProgramNotFound)
	}
	program := &models.StudyProgram{Code: "TI", Name: "Teknik Informatika"}
	program.ID = id
	return program, nil
}

// ------------------------------------------------------------------

type fakeTokenRepo struct{ revokedFor []string }

func (f *fakeTokenRepo) Create(context.Context, *gorm.DB, *models.RefreshToken) error { return nil }

func (f *fakeTokenRepo) LockByHash(context.Context, *gorm.DB, string) (*models.RefreshToken, error) {
	return nil, utils.NewError(utils.CodeRefreshTokenInvalid)
}

func (f *fakeTokenRepo) Revoke(context.Context, *gorm.DB, string, *string, time.Time) error {
	return nil
}

func (f *fakeTokenRepo) RevokeAllForUser(_ context.Context, _ *gorm.DB, userID string, _ time.Time) error {
	f.revokedFor = append(f.revokedFor, userID)
	return nil
}

func (f *fakeTokenRepo) DeleteExpired(context.Context, time.Time) (int64, error) { return 0, nil }

// ------------------------------------------------------------------

type fakeAuditRepo struct{ entries []repositories.AuditEntry }

func (f *fakeAuditRepo) Record(_ context.Context, entry repositories.AuditEntry) error {
	f.entries = append(f.entries, entry)
	return nil
}

// ------------------------------------------------------------------

// allowAllLimiter menjaga pengujian tetap tentang aturan domain, bukan tentang
// rate limit — kasus limit tercapai diuji terpisah lewat blockingLimiter.
type allowAllLimiter struct{}

func (allowAllLimiter) Allow(context.Context, string, string, int) (bool, error) {
	return true, nil
}

type blockingLimiter struct{}

func (blockingLimiter) Allow(context.Context, string, string, int) (bool, error) {
	return false, nil
}

// ------------------------------------------------------------------

const testProgramID = "11111111-1111-4111-8111-111111111111"

func testConfig() *config.Config {
	cfg := &config.Config{}
	cfg.RateLimit.LoginPerMinute = 10
	return cfg
}

func testJWT() *utils.JWTManager {
	return utils.NewJWTManager("test-secret-value", "sanctuary-test", time.Minute, time.Hour)
}

func errorCode(err error) string {
	var appErr *utils.AppError
	if errors.As(err, &appErr) {
		return appErr.Code
	}
	return ""
}
