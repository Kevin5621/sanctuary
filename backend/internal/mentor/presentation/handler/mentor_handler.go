package handler

import (
	"slices"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/mentor/domain/usecase"
)

// allowedPeriodDays sesuai tab Kondisi: 30 / 90 / 120 hari.
var allowedPeriodDays = []int{30, 90, 120}

type MentorHandler struct {
	uc usecase.MentorUsecase
}

func NewMentorHandler(uc usecase.MentorUsecase) *MentorHandler { return &MentorHandler{uc: uc} }

// ListAdvisees godoc: GET /api/v1/mentors/me/students
// Terurut: permintaan dihubungi → level EWS → nama.
func (h *MentorHandler) ListAdvisees(c *gin.Context) {
	p := utils.ParsePagination(c)

	items, total, err := h.uc.ListAdvisees(c.Request.Context(), h.accessFrom(c), p)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OKWithMeta(c, items, utils.NewMeta(p.Page, p.PerPage, total))
}

// StudentIndicator godoc: GET /api/v1/mentors/me/students/:id
// Mengembalikan indikator kondisi sesuai tingkat privasi mahasiswa.
// Tidak ada endpoint apa pun yang mengembalikan jurnal atau chat mahasiswa.
func (h *MentorHandler) StudentIndicator(c *gin.Context) {
	studentID := c.Param("id")
	if studentID == "" {
		utils.FailCode(c, utils.CodeInvalidPathParam)
		return
	}

	res, err := h.uc.StudentIndicator(c.Request.Context(), h.accessFrom(c), studentID)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, res)
}

// GroupCondition godoc: GET /api/v1/mentors/me/condition?period_days=30
func (h *MentorHandler) GroupCondition(c *gin.Context) {
	periodDays, err := strconv.Atoi(c.DefaultQuery("period_days", "30"))
	if err != nil || !slices.Contains(allowedPeriodDays, periodDays) {
		utils.Fail(c, utils.NewError(utils.CodeInvalidQueryParam).WithDetails(map[string]any{
			"field":   "period_days",
			"allowed": allowedPeriodDays,
		}))
		return
	}

	res, ucErr := h.uc.GroupCondition(c.Request.Context(), h.accessFrom(c), periodDays)
	if ucErr != nil {
		utils.Fail(c, ucErr)
		return
	}
	utils.OK(c, res)
}

// ListContactRequests godoc: GET /api/v1/mentors/me/contact-requests
//
// Response memuat nama mahasiswa + waktu permintaan SAJA.
// SENGAJA TIDAK DISERTAKAN: kolom `student_contact_requests.note` (alasan) —
// lihat D-6. Juga tidak ada indikator kondisi maupun EWS pada endpoint ini.
func (h *MentorHandler) ListContactRequests(c *gin.Context) {
	items, err := h.uc.ListContactRequests(c.Request.Context(), h.accessFrom(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, items)
}

// Profile godoc: GET /api/v1/mentors/me/profile
// Jumlah bimbingan + daftar batas akses (L-PRO-02..03). Tanpa data kondisi.
func (h *MentorHandler) Profile(c *gin.Context) {
	res, err := h.uc.Profile(c.Request.Context(), h.accessFrom(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, res)
}

func (h *MentorHandler) accessFrom(c *gin.Context) usecase.AccessContext {
	return usecase.AccessContext{
		AdvisorID: middleware.MustUserID(c),
		RequestID: c.GetString(utils.ContextRequestID),
		IPAddress: c.ClientIP(),
	}
}
