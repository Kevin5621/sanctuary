package usecase

import (
	"context"
	"log"

	"github.com/google/uuid"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/crisis"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/mapper"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

// ChatUsecase menangani Terapis AI — KONTEN PRIVAT (I-1) yang teksnya dikirim
// ke pihak ketiga (D-5).
//
// Dua pengaman yang tidak boleh dilepas dari usecase ini:
//
//  1. GATE CONSENT. Setiap method yang menyentuh isi percakapan memanggil
//     requireConsent lebih dulu. Gate ini berada di server — bukan di UI —
//     karena menyembunyikan tombol kirim tidak menghentikan siapa pun yang
//     memanggil endpoint langsung dengan token yang sah. D-5 menuntut
//     penolakan pada level API, dan di sinilah penolakan itu terjadi.
//
//  2. DETEKSI KRISIS IN-PROCESS. Setiap pesan mahasiswa diperiksa dengan
//     leksikon yang sama persis dengan jurnal (core/crisis) SEBELUM dan
//     TERLEPAS DARI panggilan ke model. Kartu bantuan darurat karena itu tetap
//     muncul walau Gemini timeout, diblokir filter, atau menjawab ngawur —
//     keselamatan tidak boleh bergantung pada layanan yang bisa mati.
type ChatUsecase interface {
	ConsentStatus(ctx context.Context, userID string) (dto.ConsentStatusResponse, error)
	SubmitConsent(ctx context.Context, userID string, req dto.ConsentDecisionRequest) (dto.ConsentStatusResponse, error)
	History(ctx context.Context, userID string) (dto.ChatHistoryResponse, error)
	Send(ctx context.Context, userID string, req dto.SendMessageRequest) (dto.SendMessageResponse, error)
}

// fallbackReply dipakai saat penyedia AI gagal menjawab.
//
// Kalimatnya sengaja tidak berpura-pura menjadi jawaban model: mahasiswa berhak
// tahu bahwa yang ia baca adalah pesan sistem. Ia juga tidak menampilkan detail
// teknis penyedia — itu hanya membingungkan dan membocorkan informasi internal.
const fallbackReply = "Maaf, aku sedang tidak bisa menjawab saat ini. Pesanmu tetap tersimpan. " +
	"coba kirim ulang sebentar lagi. Kalau kamu butuh bicara dengan orang sungguhan sekarang, " +
	"buka menu Layanan Bantuan Darurat."

// unavailableReply dipakai bila penyedia belum dikonfigurasi sama sekali.
const unavailableReply = "Terapis AI belum aktif di server ini. Kamu tetap bisa memakai " +
	"latihan napas dan grounding di menu Latihan Mandiri."

type chatUsecase struct {
	chats     repositories.ChatRepository
	consents  repositories.AIConsentRepository
	therapist service.AITherapist
	cfg       config.AIConfig
}

func NewChatUsecase(
	chats repositories.ChatRepository,
	consents repositories.AIConsentRepository,
	therapist service.AITherapist,
	cfg config.AIConfig,
) ChatUsecase {
	return &chatUsecase{chats: chats, consents: consents, therapist: therapist, cfg: cfg}
}

// ------------------------------------------------------------------
// Consent (M-AI-01)
// ------------------------------------------------------------------

func (u *chatUsecase) ConsentStatus(ctx context.Context, userID string) (dto.ConsentStatusResponse, error) {
	consent, err := u.consents.FindByUser(ctx, userID)
	if err != nil {
		return dto.ConsentStatusResponse{}, err
	}
	return mapper.ToConsentStatus(consent, consentNotice(), u.cfg.Enabled()), nil
}

func (u *chatUsecase) SubmitConsent(ctx context.Context, userID string, req dto.ConsentDecisionRequest) (dto.ConsentStatusResponse, error) {
	if req.Accepted == nil {
		return dto.ConsentStatusResponse{}, utils.NewError(utils.CodeValidationError)
	}

	// Klien hanya boleh merekam keputusan atas teks yang berlaku sekarang.
	// Tanpa pemeriksaan ini, aplikasi versi lama dapat menyimpan "setuju" atas
	// pemberitahuan yang isinya sudah berbeda dari praktik yang sebenarnya.
	if req.NoticeVersion != models.CurrentNoticeVersion {
		return dto.ConsentStatusResponse{}, utils.NewError(utils.CodeAIConsentVersionMismatch).
			WithDetails(map[string]any{"current_notice_version": models.CurrentNoticeVersion})
	}

	now := apptime.Now()
	consent := &models.AIChatConsent{
		UserID:        userID,
		Status:        models.ConsentStatusDenied,
		NoticeVersion: models.CurrentNoticeVersion,
		DecidedAt:     now,
	}
	if *req.Accepted {
		consent.Status = models.ConsentStatusGranted
		consent.ConsentedAt = &now
	}

	if err := u.consents.Upsert(ctx, consent); err != nil {
		return dto.ConsentStatusResponse{}, err
	}

	// Menarik persetujuan harus berarti sesuatu. Bila mahasiswa menolak setelah
	// sebelumnya pernah chat, riwayat percakapannya dihapus — membiarkannya
	// tersimpan sementara izin pemrosesannya dicabut adalah kontradiksi yang
	// tidak akan bisa dijelaskan pada tinjauan etik.
	if !*req.Accepted {
		if err := u.chats.DeleteAllForUser(ctx, userID); err != nil {
			return dto.ConsentStatusResponse{}, err
		}
	}

	return mapper.ToConsentStatus(consent, consentNotice(), u.cfg.Enabled()), nil
}

// requireConsent adalah SATU-SATUNYA gate yang mengizinkan akses isi chat.
// Dipanggil oleh History maupun Send.
func (u *chatUsecase) requireConsent(ctx context.Context, userID string) error {
	consent, err := u.consents.FindByUser(ctx, userID)
	if err != nil {
		return err
	}
	if !consent.AllowsProcessing() {
		// Kode yang sama dipakai untuk "belum pernah memutuskan", "menolak",
		// dan "setuju atas versi lama". Klien mendapat rinciannya lewat
		// endpoint status; response error tidak perlu menjelaskan lebih jauh.
		return utils.NewError(utils.CodeAIConsentRequired).
			WithDetails(map[string]any{"notice_version": models.CurrentNoticeVersion})
	}
	return nil
}

// ------------------------------------------------------------------
// Percakapan (M-AI-02, M-AI-03, M-AI-04)
// ------------------------------------------------------------------

func (u *chatUsecase) History(ctx context.Context, userID string) (dto.ChatHistoryResponse, error) {
	if err := u.requireConsent(ctx, userID); err != nil {
		return dto.ChatHistoryResponse{}, err
	}

	sessionID, err := u.chats.LatestSessionID(ctx, userID)
	if err != nil {
		return dto.ChatHistoryResponse{}, err
	}

	response := dto.ChatHistoryResponse{
		SessionID: sessionID,
		Messages:  []dto.ChatMessageResponse{},
		TurnLimit: u.cfg.MaxTurns,
	}
	if sessionID == "" {
		return response, nil
	}

	limit := u.messageLimit()
	messages, err := u.chats.ListRecentForUser(ctx, userID, sessionID, limit)
	if err != nil {
		return dto.ChatHistoryResponse{}, err
	}

	total, err := u.chats.CountForSession(ctx, userID, sessionID)
	if err != nil {
		return dto.ChatHistoryResponse{}, err
	}

	response.Messages = mapper.ToChatMessages(messages)
	response.IsTruncated = total > int64(len(messages))

	// Kartu bantuan harus tetap muncul saat layar dibuka ulang, bukan hanya
	// pada detik pesan krisis dikirim.
	for i := range messages {
		if messages[i].IsCrisisFlagged {
			response.CrisisMessage = crisis.Message()
			break
		}
	}
	return response, nil
}

func (u *chatUsecase) Send(ctx context.Context, userID string, req dto.SendMessageRequest) (dto.SendMessageResponse, error) {
	if err := u.requireConsent(ctx, userID); err != nil {
		return dto.SendMessageResponse{}, err
	}

	sessionID, err := u.chats.LatestSessionID(ctx, userID)
	if err != nil {
		return dto.SendMessageResponse{}, err
	}
	if sessionID == "" {
		sessionID = uuid.NewString()
	}

	// Deteksi krisis dijalankan lebih dulu, atas teks mentah mahasiswa, dan
	// hasilnya tidak pernah bergantung pada balasan model (M-AI-04).
	crisisResult := crisis.Detect(req.Text)

	userMessage := &models.StudentChatMessage{
		UserID:          userID,
		SessionID:       sessionID,
		Sender:          models.ChatSenderUser,
		Content:         req.Text,
		IsCrisisFlagged: crisisResult.IsFlagged,
	}

	// Riwayat untuk konteks model diambil SEBELUM pesan baru disimpan, lalu
	// pesan baru ditambahkan di ujung. Pemangkasan 100 giliran (M-AI-03)
	// terjadi di sini — di server — sehingga klien tidak dapat memperbesar
	// jumlah teks pribadi yang dikirim keluar dengan memanipulasi request.
	history, err := u.buildHistory(ctx, userID, sessionID, req.Text)
	if err != nil {
		return dto.SendMessageResponse{}, err
	}

	replyText, isFallback := u.generateReply(ctx, history)

	aiMessage := &models.StudentChatMessage{
		UserID:    userID,
		SessionID: sessionID,
		Sender:    models.ChatSenderAI,
		Content:   replyText,
		// Penanda krisis melekat pada pesan MAHASISWA, bukan pada balasan AI —
		// yang ditandai adalah apa yang mahasiswa ungkapkan, bukan jawabannya.
		IsCrisisFlagged: false,
	}

	if err := u.chats.AppendAll(ctx, []*models.StudentChatMessage{userMessage, aiMessage}); err != nil {
		return dto.SendMessageResponse{}, err
	}

	return dto.SendMessageResponse{
		UserMessage:     mapper.ToChatMessage(userMessage),
		AIMessage:       mapper.ToChatMessage(aiMessage),
		IsCrisisFlagged: crisisResult.IsFlagged,
		CrisisMessage:   crisisResult.Message,
		IsFallback:      isFallback,
	}, nil
}

// buildHistory menyusun konteks percakapan (lama → baru), dipangkas ke
// MaxTurns giliran, dengan pesan baru sebagai giliran terakhir.
func (u *chatUsecase) buildHistory(ctx context.Context, userID, sessionID, newText string) ([]service.ChatTurn, error) {
	limit := u.messageLimit()

	// Sisakan satu slot untuk pesan baru agar total tetap di bawah batas.
	stored, err := u.chats.ListRecentForUser(ctx, userID, sessionID, limit-1)
	if err != nil {
		return nil, err
	}

	turns := make([]service.ChatTurn, 0, len(stored)+1)
	for i := range stored {
		turns = append(turns, service.ChatTurn{
			FromStudent: stored[i].Sender == models.ChatSenderUser,
			Text:        stored[i].Content,
		})
	}
	turns = append(turns, service.ChatTurn{FromStudent: true, Text: newText})
	return turns, nil
}

// generateReply memanggil penyedia dan menerjemahkan kegagalan menjadi balasan
// fallback. Kegagalan penyedia TIDAK pernah dipropagasi sebagai error HTTP:
// pesan mahasiswa sudah ditulis dan harus tetap tersimpan (M-AI-02).
func (u *chatUsecase) generateReply(ctx context.Context, history []service.ChatTurn) (string, bool) {
	if !u.cfg.Enabled() || u.therapist == nil {
		return unavailableReply, true
	}

	reply, err := u.therapist.Reply(ctx, history)
	if err != nil {
		// Detail teknis hanya masuk log server. Isi percakapan TIDAK ikut
		// dicatat di sini — log bukan tempat konten privat mahasiswa.
		log.Printf("[chat] penyedia AI gagal menjawab: %v", err)
		return fallbackReply, true
	}
	return reply, false
}

// messageLimit menerjemahkan batas giliran menjadi batas baris pesan.
// Satu giliran = satu pesan mahasiswa + satu balasan AI.
func (u *chatUsecase) messageLimit() int {
	limit := u.cfg.MaxTurns * 2
	if limit < 2 {
		limit = 2
	}
	return limit
}

// consentNotice adalah teks pemberitahuan pihak ketiga (D-5).
//
// Disimpan di server supaya seluruh klien menampilkan kalimat yang sama, dan
// supaya perubahan kata-katanya selalu berpasangan dengan kenaikan
// CurrentNoticeVersion di satu berkas yang sama.
func consentNotice() dto.ConsentNoticeResponse {
	return dto.ConsentNoticeResponse{
		NoticeVersion: models.CurrentNoticeVersion,
		Title:         "Sebelum memakai Terapis AI",
		Summary: "Terapis AI dijalankan oleh Google Gemini, layanan di luar Sanctuary. " +
			"Isi percakapanmu akan dikirim ke sana untuk diproses.",
		Points: []string{
			"Teks yang kamu tulis di tab ini dikirim ke Google Gemini untuk dibuatkan balasan.",
			"Percakapanmu disimpan di akunmu dan hanya bisa dibaca olehmu. Dosen, kaprodi, maupun admin tidak punya akses.",
			"Terapis AI bukan psikolog dan tidak memberi diagnosis. Untuk keadaan darurat, gunakan menu Layanan Bantuan Darurat.",
			"Kamu boleh menolak. Tab ini tetap bisa kamu pakai untuk latihan napas dan grounding, tanpa mengirim apa pun keluar.",
			"Kamu bisa berubah pikiran kapan saja. Jika nanti kamu menolak, riwayat percakapanmu ikut dihapus.",
		},
		ProviderName: "Google Gemini",
		AcceptLabel:  "Saya mengerti dan setuju",
		DeclineLabel: "Tidak, cukup latihan mandiri",
	}
}
