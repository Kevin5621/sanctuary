package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/utils"
)

// Nama cookie auth. Sesuai api-security-standards.md token disimpan pada
// cookie HttpOnly+Secure+SameSite=Strict.
const (
	CookieAccessToken  = "access_token"
	CookieRefreshToken = "refresh_token"
	CookieCSRFToken    = "csrf_token"

	// HeaderClientType dipakai klien native (Flutter mobile) yang tidak punya
	// cookie jar browser. Lihat catatan di Auth().
	HeaderClientType = "X-Client-Type"
	ClientTypeMobile = "mobile"
)

// Auth memverifikasi access token lalu meng-inject identitas ke context.
//
// Urutan pembacaan token:
//  1. Cookie `access_token` (browser/web — sesuai standar keamanan).
//  2. Header `Authorization: Bearer <token>` (khusus klien native Flutter,
//     yang tidak rentan CSRF karena tidak mengirim kredensial ambient).
func Auth(jwtManager *utils.JWTManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := extractAccessToken(c)
		if token == "" {
			utils.Fail(c, utils.NewError(utils.CodeTokenMissing))
			return
		}

		claims, err := jwtManager.Parse(token, utils.TokenTypeAccess)
		if err != nil {
			utils.Fail(c, err)
			return
		}

		c.Set(ContextUserID, claims.UserID)
		c.Set(ContextUserRole, claims.Role)
		c.Set(ContextProgramID, claims.ProgramID)
		c.Set(ContextTokenID, claims.ID)
		c.Next()
	}
}

func extractAccessToken(c *gin.Context) string {
	if cookie, err := c.Cookie(CookieAccessToken); err == nil && cookie != "" {
		return cookie
	}
	authHeader := c.GetHeader("Authorization")
	if after, found := strings.CutPrefix(authHeader, "Bearer "); found {
		return strings.TrimSpace(after)
	}
	return ""
}

// UsesBearerAuth true bila request memakai header Bearer tanpa cookie sesi.
// Dipakai CSRF middleware: tanpa ambient credentials, CSRF tidak berlaku.
func UsesBearerAuth(c *gin.Context) bool {
	if cookie, err := c.Cookie(CookieAccessToken); err == nil && cookie != "" {
		return false
	}
	return strings.HasPrefix(c.GetHeader("Authorization"), "Bearer ")
}
