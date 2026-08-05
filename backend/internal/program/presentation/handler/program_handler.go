package handler

import (
	"slices"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/program/domain/usecase"
)

var allowedPeriodDays = []int{30, 90, 120}

type ProgramHandler struct {
	uc usecase.ProgramUsecase
}

func NewProgramHandler(uc usecase.ProgramUsecase) *ProgramHandler { return &ProgramHandler{uc: uc} }

// Dashboard godoc: GET /api/v1/programs/me/dashboard?period_days=30
func (h *ProgramHandler) Dashboard(c *gin.Context) {
	periodDays, ok := parsePeriodDays(c)
	if !ok {
		return
	}

	res, err := h.uc.Dashboard(c.Request.Context(), h.accessFrom(c), periodDays)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, res)
}

// Advisors godoc: GET /api/v1/programs/me/advisors
func (h *ProgramHandler) Advisors(c *gin.Context) {
	res, err := h.uc.Advisors(c.Request.Context(), h.accessFrom(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, res)
}

// CohortReport godoc: GET /api/v1/programs/me/reports/cohorts?period_days=90
func (h *ProgramHandler) CohortReport(c *gin.Context) {
	periodDays, ok := parsePeriodDays(c)
	if !ok {
		return
	}

	res, err := h.uc.CohortReport(c.Request.Context(), h.accessFrom(c), periodDays)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, res)
}

func (h *ProgramHandler) accessFrom(c *gin.Context) usecase.Access {
	user, _ := middleware.CurrentUser(c)
	return usecase.Access{
		UserID:    user.ID,
		ProgramID: user.ProgramID,
		RequestID: c.GetString(utils.ContextRequestID),
		IPAddress: c.ClientIP(),
	}
}

func parsePeriodDays(c *gin.Context) (int, bool) {
	periodDays, err := strconv.Atoi(c.DefaultQuery("period_days", "30"))
	if err != nil || !slices.Contains(allowedPeriodDays, periodDays) {
		utils.Fail(c, utils.NewError(utils.CodeInvalidQueryParam).WithDetails(map[string]any{
			"field":   "period_days",
			"allowed": allowedPeriodDays,
		}))
		return 0, false
	}
	return periodDays, true
}
