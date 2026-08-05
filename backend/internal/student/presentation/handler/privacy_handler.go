package handler

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/usecase"
)

type PrivacyHandler struct {
	uc usecase.PrivacyUsecase
}

func NewPrivacyHandler(uc usecase.PrivacyUsecase) *PrivacyHandler { return &PrivacyHandler{uc: uc} }

// Get godoc: GET /api/v1/students/me/privacy-settings
func (h *PrivacyHandler) Get(c *gin.Context) {
	setting, err := h.uc.Get(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, setting)
}

// Update godoc: PUT /api/v1/students/me/privacy-settings
func (h *PrivacyHandler) Update(c *gin.Context) {
	var req dto.UpdatePrivacySettingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	setting, err := h.uc.Update(
		c.Request.Context(),
		middleware.MustUserID(c),
		req,
		c.GetString(utils.ContextRequestID),
	)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, setting)
}

// Options godoc: GET /api/v1/students/me/privacy-settings/options
func (h *PrivacyHandler) Options(c *gin.Context) {
	utils.OK(c, h.uc.Options(c.Request.Context()))
}
