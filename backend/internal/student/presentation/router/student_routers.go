package router

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/student/presentation/handler"
)

// RegisterPrivacyRoutes — pengaturan privasi milik mahasiswa sendiri.
func RegisterPrivacyRoutes(rg *gin.RouterGroup, h *handler.PrivacyHandler) {
	g := rg.Group("/privacy-settings")
	g.GET("", h.Get)
	g.GET("/options", h.Options)
	g.PUT("", h.Update)
}

// RegisterJournalRoutes — seluruh route berada di bawah PrivateContentGuard,
// sehingga tidak ada peran selain STUDENT yang bisa menyentuhnya.
func RegisterJournalRoutes(rg *gin.RouterGroup, h *handler.JournalHandler) {
	g := rg.Group("/journals", middleware.PrivateContentGuard())
	g.POST("", h.Create)
	g.GET("", h.List)
	g.GET("/:id", h.Detail)
	g.POST("/:id/analyze", h.Analyze)
	g.DELETE("/:id", h.Delete)
}

// RegisterDailyMetricRoutes — ringkasan check-in mood milik mahasiswa sendiri
// (kuantitatif saja), dipakai kartu ringkasan & kalender mood di Beranda.
func RegisterDailyMetricRoutes(rg *gin.RouterGroup, h *handler.DailyMetricHandler) {
	g := rg.Group("/daily-metrics")
	g.GET("/weekly-summary", h.WeeklySummary)
	g.POST("", h.SaveMetric)
}

