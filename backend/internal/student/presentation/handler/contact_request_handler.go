package handler

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/usecase"
)

type ContactRequestHandler struct {
	uc usecase.ContactRequestUsecase
}

func NewContactRequestHandler(uc usecase.ContactRequestUsecase) *ContactRequestHandler {
	return &ContactRequestHandler{uc: uc}
}

// State godoc: GET /api/v1/students/me/contact-requests
func (h *ContactRequestHandler) State(c *gin.Context) {
	state, err := h.uc.State(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, state)
}

// Create godoc: POST /api/v1/students/me/contact-requests
func (h *ContactRequestHandler) Create(c *gin.Context) {
	var req dto.CreateContactRequestRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	request, err := h.uc.Create(c.Request.Context(), middleware.MustUserID(c), req)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, request)
}

// Cancel godoc: DELETE /api/v1/students/me/contact-requests
func (h *ContactRequestHandler) Cancel(c *gin.Context) {
	if err := h.uc.Cancel(c.Request.Context(), middleware.MustUserID(c)); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, gin.H{"message": "Permintaan dibatalkan"})
}
