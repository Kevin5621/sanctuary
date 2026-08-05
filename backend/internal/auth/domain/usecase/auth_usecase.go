package usecase

import (
	"context"
	"log"
	"strings"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/auth/domain/dto"
	"github.com/gilabs/sanctuary/internal/auth/domain/mapper"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// RateLimiter di-abstraksi agar usecase tidak bergantung pada layer HTTP.
type RateLimiter interface {
	Allow(ctx context.Context, scope, key string, limit int) (bool, error)
}

// LoginMeta membawa konteks request untuk audit & pengikatan sesi.
type LoginMeta struct {
	IPAddress string
	UserAgent string
	RequestID string
}

// SessionResult adalah hasil login/refresh: payload API + token mentah
// yang akan dipasang handler sebagai cookie.
type SessionResult struct {
	Session dto.SessionResponse
	Tokens  utils.TokenPair
	CSRF    string
}

type AuthUsecase interface {
	Login(ctx context.Context, req dto.LoginRequest, meta LoginMeta) (SessionResult, error)
	Refresh(ctx context.Context, refreshToken string, meta LoginMeta) (SessionResult, error)
	Logout(ctx context.Context, refreshToken, userID string, meta LoginMeta) error
	Me(ctx context.Context, userID string) (dto.UserResponse, error)
}

type authUsecase struct {
	db        *gorm.DB
	users     repositories.UserRepository
	tokens    repositories.RefreshTokenRepository
	audits    repositories.AuditRepository
	jwt       *utils.JWTManager
	limiter   RateLimiter
	loginRate int
}

func NewAuthUsecase(
	db *gorm.DB,
	users repositories.UserRepository,
	tokens repositories.RefreshTokenRepository,
	audits repositories.AuditRepository,
	jwt *utils.JWTManager,
	limiter RateLimiter,
	cfg *config.Config,
) AuthUsecase {
	return &authUsecase{
		db:        db,
		users:     users,
		tokens:    tokens,
		audits:    audits,
		jwt:       jwt,
		limiter:   limiter,
		loginRate: cfg.RateLimit.LoginPerMinute,
	}
}

func (u *authUsecase) Login(ctx context.Context, req dto.LoginRequest, meta LoginMeta) (SessionResult, error) {
	email := strings.ToLower(strings.TrimSpace(req.Email))

	// Limit per-email: mencegah brute-force terarah pada satu akun,
	// terpisah dari limit per-IP yang dipasang di middleware.
	allowed, err := u.limiter.Allow(ctx, "login_email", utils.HashToken(email), u.loginRate)
	if err != nil && !allowed {
		return SessionResult{}, utils.NewError(utils.CodeServiceUnavailable).WithCause(err)
	}
	if !allowed {
		return SessionResult{}, utils.NewError(utils.CodeRateLimitExceeded)
	}

	user, err := u.users.FindByEmail(ctx, email)
	if err != nil {
		// Jangan bedakan "email tidak ada" vs "password salah" (user enumeration).
		return SessionResult{}, utils.NewError(utils.CodeInvalidCredentials)
	}
	if !utils.VerifyPassword(user.PasswordHash, req.Password) {
		return SessionResult{}, utils.NewError(utils.CodeInvalidCredentials)
	}
	if !user.IsActive {
		return SessionResult{}, utils.NewError(utils.CodeAccountDisabled)
	}

	result, err := u.issueSession(ctx, user, meta, nil)
	if err != nil {
		return SessionResult{}, err
	}

	u.recordAudit(ctx, repositories.AuditEntry{
		ActorID:   user.ID,
		ActorRole: user.RoleCode(),
		Action:    models.ActionLogin,
		Resource:  "session",
		IPAddress: meta.IPAddress,
		RequestID: meta.RequestID,
	})
	return result, nil
}

// Refresh melakukan rotasi token: token lama langsung dicabut, token baru dibuat.
// Seluruhnya dalam satu transaksi dengan row-level lock.
func (u *authUsecase) Refresh(ctx context.Context, refreshToken string, meta LoginMeta) (SessionResult, error) {
	if refreshToken == "" {
		return SessionResult{}, utils.NewError(utils.CodeRefreshTokenInvalid)
	}

	claims, err := u.jwt.Parse(refreshToken, utils.TokenTypeRefresh)
	if err != nil {
		return SessionResult{}, err
	}

	user, err := u.users.FindByID(ctx, claims.UserID)
	if err != nil {
		return SessionResult{}, utils.NewError(utils.CodeRefreshTokenInvalid)
	}
	if !user.IsActive {
		return SessionResult{}, utils.NewError(utils.CodeAccountDisabled)
	}

	var result SessionResult
	txErr := u.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		stored, err := u.tokens.LockByHash(ctx, tx, utils.HashToken(refreshToken))
		if err != nil {
			return err
		}

		now := apptime.Now()
		if !stored.IsUsable(now) {
			// Token sudah dicabut namun dipakai lagi = indikasi kebocoran token.
			// Cabut seluruh sesi user sebagai tindakan pengamanan.
			if stored.RevokedAt != nil {
				if revokeErr := u.tokens.RevokeAllForUser(ctx, tx, stored.UserID, now); revokeErr != nil {
					return revokeErr
				}
				log.Printf("[security] refresh token reuse detected user_id=%s request_id=%s", stored.UserID, meta.RequestID)
			}
			return utils.NewError(utils.CodeRefreshTokenExpired)
		}

		issued, err := u.issueSession(ctx, user, meta, tx)
		if err != nil {
			return err
		}
		if err := u.tokens.Revoke(ctx, tx, stored.ID, &issued.Tokens.RefreshTokenID, now); err != nil {
			return err
		}
		result = issued
		return nil
	})
	if txErr != nil {
		return SessionResult{}, txErr
	}
	return result, nil
}

func (u *authUsecase) Logout(ctx context.Context, refreshToken, userID string, meta LoginMeta) error {
	now := apptime.Now()

	err := u.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if refreshToken != "" {
			if stored, err := u.tokens.LockByHash(ctx, tx, utils.HashToken(refreshToken)); err == nil {
				return u.tokens.Revoke(ctx, tx, stored.ID, nil, now)
			}
		}
		// Fallback: cabut seluruh sesi aktif milik user.
		return u.tokens.RevokeAllForUser(ctx, tx, userID, now)
	})
	if err != nil {
		return err
	}

	u.recordAudit(ctx, repositories.AuditEntry{
		ActorID:   userID,
		Action:    models.ActionLogout,
		Resource:  "session",
		IPAddress: meta.IPAddress,
		RequestID: meta.RequestID,
	})
	return nil
}

func (u *authUsecase) Me(ctx context.Context, userID string) (dto.UserResponse, error) {
	user, err := u.users.FindByID(ctx, userID)
	if err != nil {
		return dto.UserResponse{}, err
	}
	return mapper.ToUserResponse(user), nil
}

// issueSession membuat pasangan token baru dan menyimpan hash refresh token.
func (u *authUsecase) issueSession(ctx context.Context, user *models.User, meta LoginMeta, tx *gorm.DB) (SessionResult, error) {
	programID := ""
	if user.StudyProgramID != nil {
		programID = *user.StudyProgramID
	}

	pair, err := u.jwt.GenerateTokenPair(user.ID, user.RoleCode(), programID)
	if err != nil {
		return SessionResult{}, utils.WrapInternal(err)
	}

	stored := &models.RefreshToken{
		UserID:    user.ID,
		TokenHash: utils.HashToken(pair.RefreshToken),
		ExpiresAt: pair.RefreshExpiresAt,
		UserAgent: truncate(meta.UserAgent, 255),
		IPAddress: truncate(meta.IPAddress, 64),
	}
	stored.ID = pair.RefreshTokenID

	if err := u.tokens.Create(ctx, tx, stored); err != nil {
		return SessionResult{}, err
	}
	if err := u.users.TouchLastLogin(ctx, tx, user.ID); err != nil {
		return SessionResult{}, err
	}

	csrf, err := utils.RandomToken(32)
	if err != nil {
		return SessionResult{}, utils.WrapInternal(err)
	}

	return SessionResult{
		Session: dto.SessionResponse{
			User:             mapper.ToUserResponse(user),
			AccessExpiresAt:  apptime.FormatDateTime(pair.AccessExpiresAt),
			RefreshExpiresAt: apptime.FormatDateTime(pair.RefreshExpiresAt),
		},
		Tokens: pair,
		CSRF:   csrf,
	}, nil
}

// recordAudit sengaja tidak mengembalikan error: kegagalan audit tidak boleh
// menggagalkan request, tetapi wajib terlihat di log.
func (u *authUsecase) recordAudit(ctx context.Context, entry repositories.AuditEntry) {
	if err := u.audits.Record(ctx, entry); err != nil {
		log.Printf("[audit] failed action=%s actor=%s err=%v", entry.Action, entry.ActorID, err)
	}
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max]
}
