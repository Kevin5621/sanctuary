package handler

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/support/domain/dto"
	"github.com/gilabs/sanctuary/internal/support/domain/usecase"
)

type EmergencyContactHandler struct {
	uc usecase.EmergencyContactUsecase
}

func NewEmergencyContactHandler(uc usecase.EmergencyContactUsecase) *EmergencyContactHandler {
	return &EmergencyContactHandler{uc: uc}
}

// List godoc: GET /api/v1/support/emergency-contacts
// Admin melihat seluruh data (termasuk nonaktif); peran lain hanya yang aktif.
func (h *EmergencyContactHandler) List(c *gin.Context) {
	p := utils.ParsePagination(c)

	user, _ := middleware.CurrentUser(c)
	activeOnly := user.Role != constants.RoleAdmin

	items, total, err := h.uc.List(c.Request.Context(), p, activeOnly)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OKWithMeta(c, items, utils.NewMeta(p.Page, p.PerPage, total))
}

// ServiceTypes godoc: GET /api/v1/support/service-types
// Sumber tunggal daftar jenis layanan untuk dropdown form Admin (A-BAN-01).
func (h *EmergencyContactHandler) ServiceTypes(c *gin.Context) {
	utils.OK(c, dto.ServiceTypeOptions())
}

// Get godoc: GET /api/v1/support/emergency-contacts/:id
func (h *EmergencyContactHandler) Get(c *gin.Context) {
	user, _ := middleware.CurrentUser(c)
	activeOnly := user.Role != constants.RoleAdmin

	contact, err := h.uc.Get(c.Request.Context(), c.Param("id"), activeOnly)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, contact)
}

// Create godoc: POST /api/v1/support/emergency-contacts (ADMIN)
func (h *EmergencyContactHandler) Create(c *gin.Context) {
	var req dto.CreateEmergencyContactRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	contact, err := h.uc.Create(c.Request.Context(), req)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, contact)
}

// Update godoc: PUT /api/v1/support/emergency-contacts/:id (ADMIN)
func (h *EmergencyContactHandler) Update(c *gin.Context) {
	var req dto.UpdateEmergencyContactRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	contact, err := h.uc.Update(c.Request.Context(), c.Param("id"), req)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, contact)
}

// Delete godoc: DELETE /api/v1/support/emergency-contacts/:id (ADMIN, soft delete)
func (h *EmergencyContactHandler) Delete(c *gin.Context) {
	if err := h.uc.Delete(c.Request.Context(), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, gin.H{"message": "Layanan bantuan dihapus"})
}
