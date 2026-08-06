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
//
// Catatan urutan: "emotion-history" didaftarkan sebelum "/:id" agar Gin tidak
// memperlakukannya sebagai id jurnal.
func RegisterJournalRoutes(rg *gin.RouterGroup, h *handler.JournalHandler) {
	g := rg.Group("/journals", middleware.PrivateContentGuard())
	g.POST("", h.Create)
	g.GET("", h.List)
	g.GET("/emotion-history", h.EmotionHistory)
	g.GET("/emotion-distribution", h.EmotionDistribution)
	g.GET("/:id", h.Detail)
	g.POST("/:id/analyze", h.Analyze)
	g.DELETE("/:id", h.Delete)
}

// RegisterChatRoutes — Terapis AI (M-AI).
//
// PrivateContentGuard dipasang pada GRUP, sama persis seperti jurnal, sehingga
// route baru yang ditambahkan ke grup ini ikut terjaga tanpa ada yang perlu
// mengingat untuk memasangnya satu per satu (M-AI-05 / I-1).
//
// Catatan urutan: route consent didaftarkan lebih dulu dan tidak memakai
// parameter path, jadi tidak ada bentrokan dengan route percakapan.
func RegisterChatRoutes(rg *gin.RouterGroup, h *handler.ChatHandler) {
	g := rg.Group("/chats", middleware.PrivateContentGuard())
	g.GET("/consent", h.ConsentStatus)
	g.POST("/consent", h.SubmitConsent)
	g.GET("", h.History)
	g.POST("", h.Send)
}

// RegisterDailyMetricRoutes — check-in mood harian dan riwayatnya
// (kuantitatif saja), dipakai Beranda dan tab Mood.
func RegisterDailyMetricRoutes(rg *gin.RouterGroup, h *handler.DailyMetricHandler) {
	g := rg.Group("/daily-metrics")
	g.GET("/options", h.Options)
	g.GET("/weekly-summary", h.WeeklySummary)
	g.GET("/monthly", h.Monthly)
	g.GET("/stats", h.Stats)
	g.POST("", h.SaveMetric)
}

// RegisterDassRoutes — skrining DASS-21 milik mahasiswa sendiri.
// Skoring dilakukan server; klien hanya mengirim jawaban mentah.
func RegisterDassRoutes(rg *gin.RouterGroup, h *handler.DassHandler) {
	g := rg.Group("/dass21")
	g.GET("/questions", h.Questionnaire)
	g.GET("", h.History)
	g.POST("", h.Submit)
}

// RegisterContactRequestRoutes — tombol "minta dihubungi".
func RegisterContactRequestRoutes(rg *gin.RouterGroup, h *handler.ContactRequestHandler) {
	g := rg.Group("/contact-requests")
	g.GET("", h.State)
	g.POST("", h.Create)
	g.DELETE("", h.Cancel)
}
