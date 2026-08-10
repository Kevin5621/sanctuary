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

	// Dua arah alokasi untuk satu relasi yang sama: per-dosen (siapa saja
	// bimbingan dosen ini) dan per-mahasiswa (siapa saja pembimbing mahasiswa
	// ini). Yang kedua wajib ada — tanpa layar per-mahasiswa, memberi pembimbing
	// kedua berarti menebak-nebak lewat layar dosen satu per satu.
	g.PUT("/advisors/:advisorId/advisees", h.SetAdvisees)
	g.PUT("/students/:studentId/advisors", h.SetStudentAdvisors)

	g.GET("/reports/cohorts", h.CohortReport)
	g.GET("/profile", h.Profile)
}
