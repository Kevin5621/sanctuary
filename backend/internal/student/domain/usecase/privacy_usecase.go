package usecase

import (
	"context"
	"log"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/mapper"
)

// PrivacyUsecase mengelola kontrol privasi mahasiswa.
// userID SELALU berasal dari klaim JWT — tidak pernah dari body/query.
type PrivacyUsecase interface {
	Get(ctx context.Context, userID string) (dto.PrivacySettingResponse, error)
	Update(ctx context.Context, userID string, req dto.UpdatePrivacySettingRequest, requestID string) (dto.PrivacySettingResponse, error)
	Options(ctx context.Context) []dto.PrivacyOptionResponse
}

type privacyUsecase struct {
	repo   repositories.PrivacyRepository
	audits authrepo.AuditRepository
}

func NewPrivacyUsecase(repo repositories.PrivacyRepository, audits authrepo.AuditRepository) PrivacyUsecase {
	return &privacyUsecase{repo: repo, audits: audits}
}

func (u *privacyUsecase) Get(ctx context.Context, userID string) (dto.PrivacySettingResponse, error) {
	setting, err := u.repo.GetOrDefault(ctx, userID)
	if err != nil {
		return dto.PrivacySettingResponse{}, err
	}
	return mapper.ToPrivacySettingResponse(setting), nil
}

func (u *privacyUsecase) Update(ctx context.Context, userID string, req dto.UpdatePrivacySettingRequest, requestID string) (dto.PrivacySettingResponse, error) {
	level := constants.ShareLevel(req.ShareLevel)
	if !level.IsValid() {
		return dto.PrivacySettingResponse{}, utils.NewError(utils.CodeInvalidEnum).WithDetails(map[string]any{
			"field":   "share_level",
			"allowed": constants.AllShareLevels,
		})
	}

	current, err := u.repo.GetOrDefault(ctx, userID)
	if err != nil {
		return dto.PrivacySettingResponse{}, err
	}

	current.UserID = userID
	current.ShareLevel = level
	current.AllowEarlyWarning = *req.AllowEarlyWarning
	current.AllowProgramStatistic = *req.AllowProgramStatistic

	// Aturan konsistensi: pada level Tertutup, tidak ada indikator yang boleh
	// mengalir ke pembimbing — peringatan dini otomatis ikut dimatikan.
	if level == constants.ShareLevelClosed {
		current.AllowEarlyWarning = false
	}

	if err := u.repo.Upsert(ctx, current); err != nil {
		return dto.PrivacySettingResponse{}, err
	}

	// Perubahan kontrol privasi adalah aksi sensitif — wajib terekam.
	if auditErr := u.audits.Record(ctx, authrepo.AuditEntry{
		ActorID:    userID,
		ActorRole:  constants.RoleStudent.String(),
		Action:     authmodels.ActionUpdatePrivacy,
		Resource:   "student_privacy_setting",
		ResourceID: userID,
		Metadata: map[string]any{
			"share_level":             current.ShareLevel,
			"allow_early_warning":     current.AllowEarlyWarning,
			"allow_program_statistic": current.AllowProgramStatistic,
		},
		RequestID: requestID,
	}); auditErr != nil {
		log.Printf("[audit] failed privacy update user=%s err=%v", userID, auditErr)
	}

	return mapper.ToPrivacySettingResponse(current), nil
}

func (u *privacyUsecase) Options(_ context.Context) []dto.PrivacyOptionResponse {
	return mapper.ShareLevelOptions()
}
