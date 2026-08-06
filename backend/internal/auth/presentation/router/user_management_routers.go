package router

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/auth/presentation/handler"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// RegisterUserManagementRoutes memasang kelola akun Admin (A-AKN-01..03).
// Seluruh grup dikunci untuk ADMIN; tidak ada satu pun endpoint baca di sini
// yang terbuka untuk peran lain.
func RegisterUserManagementRoutes(
	rg *gin.RouterGroup,
	h *handler.UserManagementHandler,
	jwtManager *utils.JWTManager,
) {
	g := rg.Group("/admin",
		middleware.Auth(jwtManager),
		middleware.RequireRoles(constants.RoleAdmin),
	)

	// Di luar grup "/users" agar tidak bersaing dengan wildcard "/:id".
	g.GET("/user-options", h.Options)

	users := g.Group("/users")
	users.GET("", h.List)
	users.POST("", h.Create)
	users.GET("/:id", h.Get)
	users.PUT("/:id", h.Update)
}
