package middleware

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/constants"
)

// Kunci context yang diinject oleh Auth middleware.
const (
	ContextUserID    = "auth_user_id"
	ContextUserRole  = "auth_user_role"
	ContextProgramID = "auth_program_id"
	ContextTokenID   = "auth_token_id"
)

// AuthUser adalah identitas request yang sudah terverifikasi.
type AuthUser struct {
	ID        string
	Role      constants.Role
	ProgramID string
}

func (u AuthUser) IsStudent() bool  { return u.Role == constants.RoleStudent }
func (u AuthUser) IsLecturer() bool { return u.Role == constants.RoleLecturer }

// CurrentUser mengambil identitas terverifikasi dari context Gin.
// ok=false berarti route tidak melewati Auth middleware.
func CurrentUser(c *gin.Context) (AuthUser, bool) {
	id := c.GetString(ContextUserID)
	if id == "" {
		return AuthUser{}, false
	}
	return AuthUser{
		ID:        id,
		Role:      constants.Role(c.GetString(ContextUserRole)),
		ProgramID: c.GetString(ContextProgramID),
	}, true
}

// MustUserID dipakai di handler yang sudah pasti berada di balik Auth middleware.
func MustUserID(c *gin.Context) string { return c.GetString(ContextUserID) }
