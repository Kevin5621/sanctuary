package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/usecase"
)

type DailyMetricHandler struct {
	uc usecase.DailyMetricUsecase
}

func NewDailyMetricHandler(uc usecase.DailyMetricUsecase) *DailyMetricHandler {
	return &DailyMetricHandler{uc: uc}
}

// Options godoc: GET /api/v1/students/me/daily-metrics/options
func (h *DailyMetricHandler) Options(c *gin.Context) {
	utils.OK(c, h.uc.Options(c.Request.Context()))
}

// WeeklySummary godoc: GET /api/v1/students/me/daily-metrics/weekly-summary
func (h *DailyMetricHandler) WeeklySummary(c *gin.Context) {
	summary, err := h.uc.WeeklySummary(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, summary)
}

// Monthly godoc: GET /api/v1/students/me/daily-metrics/monthly?month=YYYY-MM
func (h *DailyMetricHandler) Monthly(c *gin.Context) {
	result, err := h.uc.Monthly(c.Request.Context(), middleware.MustUserID(c), c.Query("month"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, result)
}

// Stats godoc: GET /api/v1/students/me/daily-metrics/stats?period_days=30
func (h *DailyMetricHandler) Stats(c *gin.Context) {
	periodDays := 0
	if raw := c.Query("period_days"); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed <= 0 {
			utils.FailCode(c, utils.CodeInvalidQueryParam)
			return
		}
		periodDays = parsed
	}

	stats, err := h.uc.Stats(c.Request.Context(), middleware.MustUserID(c), periodDays)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, stats)
}

// SaveMetric godoc: POST /api/v1/students/me/daily-metrics
func (h *DailyMetricHandler) SaveMetric(c *gin.Context) {
	var req dto.SaveDailyMetricRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	res, err := h.uc.SaveMetric(c.Request.Context(), middleware.MustUserID(c), req)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, res)
}
