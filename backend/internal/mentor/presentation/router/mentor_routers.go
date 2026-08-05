package router

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/mentor/presentation/handler"
)

// RegisterMentorRoutes memasang 3 tab Dosen Pembimbing:
// Bimbingan (students + contact-requests), Kondisi, dan Profil
// (identitas tetap dari /auth/me, angka & batas akses dari /profile).
//
// Seluruh route ditandai AggregateOnly: hanya indikator/agregat yang boleh
// mengalir, tidak pernah konten privat mahasiswa.
func RegisterMentorRoutes(rg *gin.RouterGroup, h *handler.MentorHandler) {
	g := rg.Group("", middleware.AggregateOnly())

	g.GET("/students", h.ListAdvisees)
	g.GET("/students/:id", h.StudentIndicator)
	g.GET("/contact-requests", h.ListContactRequests)
	g.GET("/condition", h.GroupCondition)
	g.GET("/profile", h.Profile)
}
