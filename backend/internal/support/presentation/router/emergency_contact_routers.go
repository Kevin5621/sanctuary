package router

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/support/presentation/handler"
)

// RegisterEmergencyContactRoutes:
//   - Baca: seluruh peran terautentikasi (mahasiswa membutuhkannya pada
//     layar Layanan Bantuan Darurat dan pada penanganan deteksi krisis).
//   - Tulis: hanya ADMIN.
func RegisterEmergencyContactRoutes(rg *gin.RouterGroup, h *handler.EmergencyContactHandler) {
	g := rg.Group("/emergency-contacts")

	g.GET("", h.List)
	g.GET("/:id", h.Get)

	adminOnly := g.Group("", middleware.RequireRoles(constants.RoleAdmin))
	adminOnly.POST("", h.Create)
	adminOnly.PUT("/:id", h.Update)
	adminOnly.DELETE("/:id", h.Delete)
}
