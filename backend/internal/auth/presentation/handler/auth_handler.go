package handler

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/auth/domain/dto"
	"github.com/gilabs/sanctuary/internal/auth/domain/usecase"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

type AuthHandler struct {
	uc  usecase.AuthUsecase
	cfg *config.Config
}

func NewAuthHandler(uc usecase.AuthUsecase, cfg *config.Config) *AuthHandler {
	return &AuthHandler{uc: uc, cfg: cfg}
}

// Login godoc: POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	result, err := h.uc.Login(c.Request.Context(), req, h.metaFrom(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}

	h.writeSession(c, &result)
	utils.OK(c, result.Session)
}

// Register godoc: POST /api/v1/auth/register
//
// Pendaftaran mandiri mahasiswa. Berhasil mendaftar berarti langsung punya
// sesi — memaksa pengguna mengetik ulang kredensial yang baru saja dibuatnya
// tidak menambah keamanan apa pun.
func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterStudentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	result, err := h.uc.Register(c.Request.Context(), req, h.metaFrom(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}

	h.writeSession(c, &result)
	utils.Created(c, result.Session)
}

// StudyPrograms godoc: GET /api/v1/auth/study-programs
// Publik: formulir pendaftaran membutuhkannya sebelum ada sesi.
func (h *AuthHandler) StudyPrograms(c *gin.Context) {
	programs, err := h.uc.StudyPrograms(c.Request.Context())
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, programs)
}

// Refresh godoc: POST /api/v1/auth/refresh
func (h *AuthHandler) Refresh(c *gin.Context) {
	var req dto.RefreshRequest
	_ = c.ShouldBindJSON(&req) // body opsional untuk klien web (pakai cookie)

	token := req.RefreshToken
	if token == "" {
		token, _ = c.Cookie(middleware.CookieRefreshToken)
	}

	result, err := h.uc.Refresh(c.Request.Context(), token, h.metaFrom(c))
	if err != nil {
		h.clearSession(c)
		utils.Fail(c, err)
		return
	}

	h.writeSession(c, &result)
	utils.OK(c, result.Session)
}

// Logout godoc: POST /api/v1/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	token, _ := c.Cookie(middleware.CookieRefreshToken)
	if token == "" {
		var req dto.RefreshRequest
		_ = c.ShouldBindJSON(&req)
		token = req.RefreshToken
	}

	if err := h.uc.Logout(c.Request.Context(), token, middleware.MustUserID(c), h.metaFrom(c)); err != nil {
		utils.Fail(c, err)
		return
	}

	h.clearSession(c)
	utils.OK(c, gin.H{"message": "Berhasil keluar"})
}

// Me godoc: GET /api/v1/auth/me
func (h *AuthHandler) Me(c *gin.Context) {
	user, err := h.uc.Me(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, user)
}

// ------------------------------------------------------------------
// Session transport
//
// Default (web): token dikirim via cookie HttpOnly+Secure+SameSite=Strict
// sesuai api-security-standards.md §1.1.
//
// Pengecualian (klien native Flutter): header `X-Client-Type: mobile`.
// Aplikasi mobile tidak memiliki cookie jar browser dan tidak terpapar CSRF,
// sehingga token dikembalikan di body untuk disimpan pada secure storage OS
// (Keychain / EncryptedSharedPreferences).
// ------------------------------------------------------------------
func (h *AuthHandler) writeSession(c *gin.Context, result *usecase.SessionResult) {
	c.SetSameSite(http.SameSiteStrictMode)
	secure := h.cfg.Security.CookieSecure
	domain := h.cfg.Security.CookieDomain

	c.SetCookie(middleware.CookieAccessToken, result.Tokens.AccessToken,
		int(h.cfg.Security.AccessTTL.Seconds()), "/", domain, secure, true)
	c.SetCookie(middleware.CookieRefreshToken, result.Tokens.RefreshToken,
		int(h.cfg.Security.RefreshTTL.Seconds()), "/api/v1/auth", domain, secure, true)
	// csrf_token sengaja non-HttpOnly (double-submit cookie pattern).
	c.SetCookie(middleware.CookieCSRFToken, result.CSRF,
		int(h.cfg.Security.RefreshTTL.Seconds()), "/", domain, secure, false)

	if isNativeClient(c) {
		result.Session.AccessToken = result.Tokens.AccessToken
		result.Session.RefreshToken = result.Tokens.RefreshToken
	}
	result.Session.CSRFToken = result.CSRF
}

func (h *AuthHandler) clearSession(c *gin.Context) {
	c.SetSameSite(http.SameSiteStrictMode)
	secure := h.cfg.Security.CookieSecure
	domain := h.cfg.Security.CookieDomain

	c.SetCookie(middleware.CookieAccessToken, "", -1, "/", domain, secure, true)
	c.SetCookie(middleware.CookieRefreshToken, "", -1, "/api/v1/auth", domain, secure, true)
	c.SetCookie(middleware.CookieCSRFToken, "", -1, "/", domain, secure, false)
}

func (h *AuthHandler) metaFrom(c *gin.Context) usecase.LoginMeta {
	return usecase.LoginMeta{
		IPAddress: c.ClientIP(),
		UserAgent: c.Request.UserAgent(),
		RequestID: c.GetString(utils.ContextRequestID),
	}
}

func isNativeClient(c *gin.Context) bool {
	return strings.EqualFold(c.GetHeader(middleware.HeaderClientType), middleware.ClientTypeMobile)
}
