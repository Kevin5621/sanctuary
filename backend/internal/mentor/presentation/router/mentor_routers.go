package router

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/mentor/presentation/handler"
)

// RegisterMentorRoutes memasang 2 tab data Dosen Pembimbing
// (tab Profil memakai /auth/me).
//
// Seluruh route ditandai AggregateOnly: hanya indikator/agregat yang boleh
// mengalir, tidak pernah konten privat mahasiswa.
func RegisterMentorRoutes(rg *gin.RouterGroup, h *handler.MentorHandler) {
	g := rg.Group("", middleware.AggregateOnly())

	g.GET("/students", h.ListAdvisees)
	g.GET("/students/:id", h.StudentIndicator)
	g.GET("/condition", h.GroupCondition)
}
