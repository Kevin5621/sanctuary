package handler

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/usecase"
)

type JournalHandler struct {
	uc usecase.JournalUsecase
}

func NewJournalHandler(uc usecase.JournalUsecase) *JournalHandler { return &JournalHandler{uc: uc} }

// Create godoc: POST /api/v1/students/me/journals
func (h *JournalHandler) Create(c *gin.Context) {
	var req dto.CreateJournalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	journal, analysis, err := h.uc.Create(c.Request.Context(), middleware.MustUserID(c), req)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, gin.H{"journal": journal, "analysis": analysis})
}

// List godoc: GET /api/v1/students/me/journals?page=1&per_page=20
func (h *JournalHandler) List(c *gin.Context) {
	p := utils.ParsePagination(c)

	items, total, err := h.uc.List(c.Request.Context(), middleware.MustUserID(c), p)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OKWithMeta(c, items, utils.NewMeta(p.Page, p.PerPage, total))
}

// Detail godoc: GET /api/v1/students/me/journals/:id
func (h *JournalHandler) Detail(c *gin.Context) {
	journal, err := h.uc.Detail(c.Request.Context(), middleware.MustUserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, journal)
}

// Analyze godoc: POST /api/v1/students/me/journals/:id/analyze
func (h *JournalHandler) Analyze(c *gin.Context) {
	analysis, err := h.uc.Analyze(c.Request.Context(), middleware.MustUserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, analysis)
}

// EmotionHistory godoc: GET /api/v1/students/me/journals/emotion-history
func (h *JournalHandler) EmotionHistory(c *gin.Context) {
	history, err := h.uc.EmotionHistory(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, history)
}

// Delete godoc: DELETE /api/v1/students/me/journals/:id
func (h *JournalHandler) Delete(c *gin.Context) {
	if err := h.uc.Delete(c.Request.Context(), middleware.MustUserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, gin.H{"message": "Jurnal dihapus"})
}
