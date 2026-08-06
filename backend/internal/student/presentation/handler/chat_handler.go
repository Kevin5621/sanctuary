package handler

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/usecase"
)

// ChatHandler melayani tab Terapis AI.
//
// Perhatikan bahwa TIDAK ADA satu pun handler di sini yang menerima student id
// dari klien: identitas selalu berasal dari klaim JWT lewat MustUserID. Pola
// ini identik dengan JournalHandler, dan itulah sebabnya tidak ada parameter
// yang bisa dimanipulasi untuk membaca percakapan orang lain.
type ChatHandler struct {
	uc usecase.ChatUsecase
}

func NewChatHandler(uc usecase.ChatUsecase) *ChatHandler { return &ChatHandler{uc: uc} }

// ConsentStatus godoc: GET /api/v1/students/me/chats/consent
//
// Endpoint ini sengaja TIDAK berada di balik gate consent — justru inilah yang
// memberi tahu klien apakah gate terbuka, dan membawa teks pemberitahuan yang
// harus ditampilkan bila belum.
func (h *ChatHandler) ConsentStatus(c *gin.Context) {
	status, err := h.uc.ConsentStatus(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, status)
}

// SubmitConsent godoc: POST /api/v1/students/me/chats/consent
func (h *ChatHandler) SubmitConsent(c *gin.Context) {
	var req dto.ConsentDecisionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	status, err := h.uc.SubmitConsent(c.Request.Context(), middleware.MustUserID(c), req)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, status)
}

// History godoc: GET /api/v1/students/me/chats
func (h *ChatHandler) History(c *gin.Context) {
	history, err := h.uc.History(c.Request.Context(), middleware.MustUserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, history)
}

// Send godoc: POST /api/v1/students/me/chats
func (h *ChatHandler) Send(c *gin.Context) {
	var req dto.SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.FailBinding(c, err)
		return
	}

	result, err := h.uc.Send(c.Request.Context(), middleware.MustUserID(c), req)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, result)
}
