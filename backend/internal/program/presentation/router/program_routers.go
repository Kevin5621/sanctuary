package router

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/program/presentation/handler"
)

// RegisterProgramRoutes memasang 3 tab data Kaprodi
// (tab Profil memakai /auth/me + endpoint ini).
func RegisterProgramRoutes(rg *gin.RouterGroup, h *handler.ProgramHandler) {
	g := rg.Group("", middleware.AggregateOnly())

	g.GET("/dashboard", h.Dashboard)
	g.GET("/advisors", h.Advisors)
	g.GET("/reports/cohorts", h.CohortReport)
}
