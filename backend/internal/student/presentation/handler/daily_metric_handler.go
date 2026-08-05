package handler

import (
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

// WeeklySummary godoc: GET /api/v1/students/me/daily-metrics/weekly-summary
func (h *DailyMetricHandler) WeeklySummary(c *gin.Context) {
	summary, err := h.uc.WeeklySummary(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, summary)
}

// SaveMetric godoc: POST /api/v1/students/me/daily-metrics
func (h *DailyMetricHandler) SaveMetric(c *gin.Context) {
	var req dto.SaveDailyMetricRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, err)
		return
	}
	res, err := h.uc.SaveMetric(c.Request.Context(), middleware.MustUserID(c), req)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, res)
}

