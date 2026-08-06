package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/auth/domain/dto"
	"github.com/gilabs/sanctuary/internal/auth/domain/usecase"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// UserManagementHandler melayani halaman kelola akun Admin.
type UserManagementHandler struct {
	uc usecase.UserManagementUsecase
}

func NewUserManagementHandler(uc usecase.UserManagementUsecase) *UserManagementHandler {
	return &UserManagementHandler{uc: uc}
}

// List godoc: GET /api/v1/admin/users?role=&is_active=&q=&page=
func (h *UserManagementHandler) List(c *gin.Context) {
	p := utils.ParsePagination(c)

	var activeOnly *bool
	if raw := c.Query("is_active"); raw != "" {
		parsed, err := strconv.ParseBool(raw)
		if err != nil {
			utils.Fail(c, utils.NewError(utils.CodeInvalidQueryParam).WithDetails(map[string]any{
				"field": "is_active",
			}))
			return
		}
		activeOnly = &parsed
	}

	items, total, err := h.uc.List(c.Request.Context(), p, c.Query("role"), activeOnly)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OKWithMeta(c, items, utils.NewMeta(p.Page, p.PerPage, total))
}

// Options godoc: GET /api/v1/admin/user-options
// Peran yang boleh dibuat + daftar program studi, dalam satu panggilan supaya
// formulir Admin tidak perlu dua request untuk sekadar terbuka.
func (h *UserManagementHandler) Options(c *gin.Context) {
	programs, err := h.uc.StudyPrograms(c.Request.Context())
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, gin.H{
		"roles":          h.uc.RoleOptions(),
		"study_programs": programs,
	})
}

// Get godoc: GET /api/v1/admin/users/:id
func (h *UserManagementHandler) Get(c *gin.Context) {
	user, err := h.uc.Get(c.Request.Context(), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, user)
}

// Create godoc: POST /api/v1/admin/users
func (h *UserManagementHandler) Create(c *gin.Context) {
	var req dto.CreateStaffUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	user, err := h.uc.Create(c.Request.Context(), req, h.actorFrom(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, user)
}

// Update godoc: PUT /api/v1/admin/users/:id
func (h *UserManagementHandler) Update(c *gin.Context) {
	var req dto.UpdateStaffUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	user, err := h.uc.Update(c.Request.Context(), c.Param("id"), req, h.actorFrom(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, user)
}

func (h *UserManagementHandler) actorFrom(c *gin.Context) usecase.ActorMeta {
	return usecase.ActorMeta{
		ActorID:   middleware.MustUserID(c),
		IPAddress: c.ClientIP(),
		RequestID: c.GetString(utils.ContextRequestID),
	}
}
