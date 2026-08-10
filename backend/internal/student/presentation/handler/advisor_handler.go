package handler

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/domain/usecase"
)

type AdvisorHandler struct {
	uc usecase.AdvisorUsecase
}

func NewAdvisorHandler(uc usecase.AdvisorUsecase) *AdvisorHandler {
	return &AdvisorHandler{uc: uc}
}

// List godoc: GET /api/v1/students/me/advisors
//
// Identitas mahasiswa berasal dari token, sehingga endpoint ini tidak dapat
// dipakai mengintip pembimbing orang lain.
func (h *AdvisorHandler) List(c *gin.Context) {
	res, err := h.uc.ListMine(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, res)
}
