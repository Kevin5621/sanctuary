package router

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/program/presentation/handler"
)

// RegisterProgramRoutes memasang 4 tab Kaprodi: Dashboard, Pembimbing,
// Laporan, dan Profil (identitas akun tetap dari /auth/me).
func RegisterProgramRoutes(rg *gin.RouterGroup, h *handler.ProgramHandler) {
	g := rg.Group("", middleware.AggregateOnly())

	g.GET("/dashboard", h.Dashboard)
	g.GET("/advisors", h.Advisors)
	g.GET("/students", h.Students)
	g.PUT("/advisors/assign", h.AssignAdvisor)
	g.GET("/reports/cohorts", h.CohortReport)
	g.GET("/profile", h.Profile)
}
