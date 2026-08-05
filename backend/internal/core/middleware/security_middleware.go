package middleware

import (
	"log"
	"net/http"
	"runtime/debug"
	"slices"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// MaxRequestBodyBytes membatasi ukuran body (anti resource exhaustion).
const MaxRequestBodyBytes = 2 << 20 // 2 MB

// RequestID meng-inject correlation id ke context, log, dan response header.
func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		rid := c.GetHeader("X-Request-ID")
		if rid == "" {
			rid = uuid.NewString()
		}
		c.Set(utils.ContextRequestID, rid)
		c.Header("X-Request-ID", rid)
		c.Next()
	}
}

// Recovery memastikan panic tidak pernah mematikan proses (resilience standard).
func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if r := recover(); r != nil {
				log.Printf("[panic] request_id=%s path=%s err=%v\n%s",
					c.GetString(utils.ContextRequestID), c.FullPath(), r, debug.Stack())
				utils.Fail(c, utils.NewError(utils.CodeInternalServerError))
			}
		}()
		c.Next()
	}
}

// BodyLimit menerapkan batas ukuran body sebelum binding.
func BodyLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, MaxRequestBodyBytes)
		c.Next()
	}
}

// SecurityHeaders memasang header wajib (api-security-standards.md §8).
func SecurityHeaders(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		if cfg.App.IsProduction() {
			c.Header("Strict-Transport-Security", "max-age=63072000; includeSubDomains; preload")
		}
		c.Header("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none'; base-uri 'self'")
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Header("Permissions-Policy", "geolocation=(), camera=(), microphone=(), payment=(), usb=(), fullscreen=(self)")
		c.Next()
	}
}

// CORS membatasi origin sesuai ALLOW_ORIGINS dan mengizinkan kredensial cookie.
func CORS(cfg *config.Config) gin.HandlerFunc {
	allowed := cfg.Security.AllowOrigins
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if origin != "" && slices.Contains(allowed, origin) {
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Access-Control-Allow-Credentials", "true")
			c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-CSRF-Token, X-Request-ID, "+HeaderClientType)
			c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
			c.Header("Access-Control-Max-Age", "600")
			c.Header("Vary", "Origin")
		}
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}

// CSRF menerapkan double-submit cookie pattern untuk request mutasi.
// Request dengan Bearer token (klien native) dilewati karena tidak memakai
// ambient credentials sehingga tidak dapat menjadi target CSRF.
//
// exemptPaths mengecualikan endpoint yang secara sah belum memiliki sesi/
// cookie CSRF untuk dicocokkan — saat ini hanya /auth/login: endpoint ini
// justru YANG MENERBITKAN cookie csrf_token, sehingga tidak mungkin
// mensyaratkan token tersebut pada request yang sama. Endpoint mutasi
// lain (termasuk /auth/refresh, /auth/logout) tetap wajib menyertakannya
// karena cookie csrf_token sudah ada sejak login.
func CSRF(exemptPaths ...string) gin.HandlerFunc {
	safeMethods := []string{http.MethodGet, http.MethodHead, http.MethodOptions}

	return func(c *gin.Context) {
		if slices.Contains(safeMethods, c.Request.Method) ||
			UsesBearerAuth(c) ||
			slices.Contains(exemptPaths, c.FullPath()) {
			c.Next()
			return
		}

		cookie, err := c.Cookie(CookieCSRFToken)
		header := c.GetHeader("X-CSRF-Token")
		if err != nil || cookie == "" || header == "" || !utils.SecureCompare(cookie, header) {
			utils.Fail(c, utils.NewError(utils.CodeCSRFTokenInvalid))
			return
		}
		c.Next()
	}
}

// AccessLog mencatat request tanpa membocorkan data pribadi/klinis.
func AccessLog() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
		log.Printf("[http] request_id=%s method=%s path=%s status=%d user_id=%s role=%s",
			c.GetString(utils.ContextRequestID),
			c.Request.Method,
			sanitizePath(c.FullPath()),
			c.Writer.Status(),
			c.GetString(ContextUserID),
			c.GetString(ContextUserRole),
		)
	}
}

func sanitizePath(path string) string {
	if path == "" {
		return "unmatched"
	}
	return strings.TrimSpace(path)
}
