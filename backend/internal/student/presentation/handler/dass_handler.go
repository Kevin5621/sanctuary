package handler

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/usecase"
)

type DassHandler struct {
	uc usecase.DassUsecase
}

func NewDassHandler(uc usecase.DassUsecase) *DassHandler { return &DassHandler{uc: uc} }

// Questionnaire godoc: GET /api/v1/students/me/dass21/questions
func (h *DassHandler) Questionnaire(c *gin.Context) {
	utils.OK(c, h.uc.Questionnaire(c.Request.Context()))
}

// Submit godoc: POST /api/v1/students/me/dass21
func (h *DassHandler) Submit(c *gin.Context) {
	var req dto.SubmitDassRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	result, err := h.uc.Submit(c.Request.Context(), middleware.MustUserID(c), req)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, result)
}

// History godoc: GET /api/v1/students/me/dass21
func (h *DassHandler) History(c *gin.Context) {
	history, err := h.uc.History(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, history)
}
