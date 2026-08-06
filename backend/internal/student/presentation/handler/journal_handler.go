package handler

import (
	"strconv"
	"strings"

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

// EmotionDistribution godoc: GET /api/v1/students/me/journals/emotion-distribution?range=30d
//
// Menerima dua bentuk parameter rentang:
//   - range=30d      — bentuk yang dipakai kontrak M-MOOD-04
//   - period_days=30 — konvensi yang sudah dipakai endpoint statistik mood
//
// Keduanya diterima supaya endpoint bertetangga di tab yang sama tidak memaksa
// klien mengingat dua gaya penulisan yang berbeda.
func (h *JournalHandler) EmotionDistribution(c *gin.Context) {
	periodDays, err := parseRangeDays(c.Query("range"), c.Query("period_days"))
	if err != nil {
		utils.Fail(c, err)
		return
	}

	distribution, err := h.uc.EmotionDistribution(c.Request.Context(), middleware.MustUserID(c), periodDays)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, distribution)
}

// parseRangeDays menerjemahkan "30d" / "30" menjadi jumlah hari.
// Nilai kosong berarti "pakai default server", bukan error.
func parseRangeDays(rangeParam, periodParam string) (int, error) {
	raw := strings.TrimSpace(rangeParam)
	if raw == "" {
		raw = strings.TrimSpace(periodParam)
	}
	if raw == "" {
		return 0, nil
	}

	raw = strings.TrimSuffix(strings.ToLower(raw), "d")
	days, err := strconv.Atoi(raw)
	if err != nil || days <= 0 {
		return 0, utils.NewError(utils.CodeInvalidQueryParam).WithDetails(map[string]any{
			"param":    "range",
			"expected": "jumlah hari, mis. 30 atau 30d",
		})
	}
	return days, nil
}

// Delete godoc: DELETE /api/v1/students/me/journals/:id
func (h *JournalHandler) Delete(c *gin.Context) {
	if err := h.uc.Delete(c.Request.Context(), middleware.MustUserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, gin.H{"message": "Jurnal dihapus"})
}
