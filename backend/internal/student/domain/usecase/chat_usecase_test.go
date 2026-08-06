package usecase

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/crisis"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

// ------------------------------------------------------------------
// Gate consent (D-5 / M-AI-01).
//
// Yang diuji di sini bukan sekadar "endpoint mengembalikan error", melainkan
// klaim yang sesungguhnya penting: TANPA CONSENT, TEKS MAHASISWA TIDAK PERNAH
// SAMPAI KE PIHAK KETIGA. Karena itu tiap test memeriksa fakeTherapist.calls,
// bukan hanya kode error yang keluar.
// ------------------------------------------------------------------

func newChatUsecaseForTest(consent *models.AIChatConsent) (ChatUsecase, *fakeChatRepo, *fakeConsentRepo, *fakeTherapist) {
	chats := &fakeChatRepo{}
	consents := &fakeConsentRepo{consent: consent}
	therapist := &fakeTherapist{reply: "Terima kasih sudah bercerita."}
	cfg := config.AIConfig{
		APIKey:   "test-key", // membuat cfg.Enabled() bernilai true
		Model:    "gemini-2.5-flash",
		MaxTurns: 100,
	}
	return NewChatUsecase(chats, consents, therapist, cfg), chats, consents, therapist
}

func grantedConsent() *models.AIChatConsent {
	now := apptime.Now()
	return &models.AIChatConsent{
		UserID:        "student-1",
		Status:        models.ConsentStatusGranted,
		NoticeVersion: models.CurrentNoticeVersion,
		ConsentedAt:   &now,
		DecidedAt:     now,
	}
}

func assertConsentRequired(t *testing.T, err error) {
	t.Helper()

	if err == nil {
		t.Fatal("request tanpa consent harus ditolak")
	}
	var appErr *utils.AppError
	if !errors.As(err, &appErr) {
		t.Fatalf("error harus *utils.AppError, dapat %T", err)
	}
	if appErr.Code != utils.CodeAIConsentRequired {
		t.Errorf("kode error = %q, harusnya %q", appErr.Code, utils.CodeAIConsentRequired)
	}
}

func TestSendRejectedWhenConsentNeverGiven(t *testing.T) {
	uc, chats, _, therapist := newChatUsecaseForTest(nil)

	_, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{Text: "Halo"})

	assertConsentRequired(t, err)
	if len(therapist.calls) != 0 {
		t.Error("D-5 DILANGGAR: penyedia pihak ketiga dipanggil tanpa consent")
	}
	if len(chats.messages) != 0 {
		t.Error("pesan tidak boleh tersimpan bila consent belum ada")
	}
}

func TestSendRejectedWhenConsentDenied(t *testing.T) {
	denied := &models.AIChatConsent{
		UserID:        "student-1",
		Status:        models.ConsentStatusDenied,
		NoticeVersion: models.CurrentNoticeVersion,
		DecidedAt:     apptime.Now(),
	}
	uc, _, _, therapist := newChatUsecaseForTest(denied)

	_, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{Text: "Halo"})

	assertConsentRequired(t, err)
	if len(therapist.calls) != 0 {
		t.Error("D-5 DILANGGAR: mahasiswa yang menolak tetap dikirim ke pihak ketiga")
	}
}

// TestSendRejectedWhenConsentIsForOldNoticeVersion mengunci aturan yang paling
// mudah terlewat: persetujuan atas teks pemberitahuan LAMA bukan persetujuan
// atas praktik yang berlaku sekarang.
func TestSendRejectedWhenConsentIsForOldNoticeVersion(t *testing.T) {
	now := apptime.Now()
	stale := &models.AIChatConsent{
		UserID:        "student-1",
		Status:        models.ConsentStatusGranted,
		NoticeVersion: "v0-versi-lama",
		ConsentedAt:   &now,
		DecidedAt:     now,
	}
	uc, _, _, therapist := newChatUsecaseForTest(stale)

	_, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{Text: "Halo"})

	assertConsentRequired(t, err)
	if len(therapist.calls) != 0 {
		t.Error("consent atas pemberitahuan versi lama tidak boleh mengizinkan pengiriman")
	}
}

// TestHistoryRejectedWithoutConsent menjaga agar gate tidak hanya menutup jalur
// tulis. Membaca ulang percakapan lama juga menyentuh isi chat.
func TestHistoryRejectedWithoutConsent(t *testing.T) {
	uc, _, _, _ := newChatUsecaseForTest(nil)

	_, err := uc.History(context.Background(), "student-1")

	assertConsentRequired(t, err)
}

func TestSendSucceedsWithValidConsent(t *testing.T) {
	uc, chats, _, therapist := newChatUsecaseForTest(grantedConsent())

	result, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{
		Text: "Aku sulit fokus belajar.",
	})
	if err != nil {
		t.Fatalf("consent sah harus diterima: %v", err)
	}

	if len(therapist.calls) != 1 {
		t.Fatalf("penyedia harus dipanggil sekali, dapat %d", len(therapist.calls))
	}
	if result.AIMessage.Text != "Terima kasih sudah bercerita." {
		t.Errorf("balasan model tidak diteruskan, dapat %q", result.AIMessage.Text)
	}
	if result.IsFallback {
		t.Error("IsFallback harus false saat penyedia berhasil menjawab")
	}
	if len(chats.messages) != 2 {
		t.Fatalf("pesan mahasiswa dan balasan AI harus tersimpan keduanya, dapat %d", len(chats.messages))
	}
	if chats.messages[0].Sender != models.ChatSenderUser || chats.messages[1].Sender != models.ChatSenderAI {
		t.Error("urutan penyimpanan harus USER lalu AI")
	}
}

// ------------------------------------------------------------------
// Keputusan consent (M-AI-01)
// ------------------------------------------------------------------

func TestSubmitConsentRejectsMismatchedNoticeVersion(t *testing.T) {
	uc, _, consents, _ := newChatUsecaseForTest(nil)
	accepted := true

	_, err := uc.SubmitConsent(context.Background(), "student-1", dto.ConsentDecisionRequest{
		Accepted:      &accepted,
		NoticeVersion: "v0-versi-lama",
	})

	var appErr *utils.AppError
	if !errors.As(err, &appErr) || appErr.Code != utils.CodeAIConsentVersionMismatch {
		t.Fatalf("versi pemberitahuan usang harus ditolak, dapat %v", err)
	}
	if len(consents.saved) != 0 {
		t.Error("keputusan atas versi usang tidak boleh tersimpan")
	}
}

func TestSubmitConsentGrantedRecordsTimestamp(t *testing.T) {
	uc, _, consents, _ := newChatUsecaseForTest(nil)
	accepted := true

	status, err := uc.SubmitConsent(context.Background(), "student-1", dto.ConsentDecisionRequest{
		Accepted:      &accepted,
		NoticeVersion: models.CurrentNoticeVersion,
	})
	if err != nil {
		t.Fatalf("persetujuan sah harus diterima: %v", err)
	}

	if len(consents.saved) != 1 {
		t.Fatalf("keputusan harus tersimpan, dapat %d baris", len(consents.saved))
	}
	saved := consents.saved[0]
	if saved.Status != models.ConsentStatusGranted {
		t.Errorf("status = %q, harusnya GRANTED", saved.Status)
	}
	if saved.ConsentedAt == nil {
		t.Error("GRANTED wajib membawa consented_at — audit etik bergantung padanya")
	}
	if !status.CanChat {
		t.Error("can_chat harus true setelah menyetujui")
	}
}

// TestSubmitConsentDeniedDeletesExistingHistory mengunci konsekuensi yang
// dijanjikan pada teks consent: menarik persetujuan ikut menghapus percakapan.
func TestSubmitConsentDeniedDeletesExistingHistory(t *testing.T) {
	uc, chats, consents, _ := newChatUsecaseForTest(grantedConsent())
	chats.messages = []models.StudentChatMessage{
		{UserID: "student-1", Sender: models.ChatSenderUser, Content: "rahasia"},
	}
	declined := false

	status, err := uc.SubmitConsent(context.Background(), "student-1", dto.ConsentDecisionRequest{
		Accepted:      &declined,
		NoticeVersion: models.CurrentNoticeVersion,
	})
	if err != nil {
		t.Fatalf("penolakan harus diterima: %v", err)
	}

	if !chats.deleted {
		t.Error("menolak consent wajib menghapus riwayat percakapan yang sudah ada")
	}
	if consents.saved[0].ConsentedAt != nil {
		t.Error("DENIED tidak boleh menyimpan consented_at")
	}
	if status.CanChat {
		t.Error("can_chat harus false setelah menolak")
	}
	if status.Status != models.ConsentStatusDenied {
		t.Errorf("status = %q, harusnya DENIED", status.Status)
	}
}

// ------------------------------------------------------------------
// Deteksi krisis (M-AI-04)
// ------------------------------------------------------------------

// TestCrisisDetectionUsesSharedLexicon membuktikan chat memakai leksikon yang
// SAMA dengan jurnal — bukan salinan kedua yang bisa menyimpang.
func TestCrisisDetectionUsesSharedLexicon(t *testing.T) {
	for _, phrase := range crisis.Lexicon() {
		uc, chats, _, _ := newChatUsecaseForTest(grantedConsent())

		result, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{
			Text: "Akhir-akhir ini aku " + phrase + " terus.",
		})
		if err != nil {
			t.Fatalf("%q: %v", phrase, err)
		}

		if !result.IsCrisisFlagged {
			t.Errorf("frasa krisis %q tidak terdeteksi di chat, padahal terdeteksi di jurnal", phrase)
		}
		if result.CrisisMessage == "" {
			t.Errorf("frasa krisis %q harus disertai pesan bantuan", phrase)
		}
		if len(chats.messages) > 0 && !chats.messages[0].IsCrisisFlagged {
			t.Errorf("frasa krisis %q harus tersimpan dengan is_crisis_flagged", phrase)
		}
	}
}

// TestCrisisFlagSurvivesProviderFailure adalah inti M-AI-04: kartu bantuan
// tidak boleh bergantung pada layanan yang bisa mati.
func TestCrisisFlagSurvivesProviderFailure(t *testing.T) {
	uc, _, _, therapist := newChatUsecaseForTest(grantedConsent())
	therapist.err = errors.New("timeout")

	result, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{
		Text: "Aku ingin mati saja rasanya.",
	})
	if err != nil {
		t.Fatalf("kegagalan penyedia tidak boleh menggagalkan request: %v", err)
	}

	if !result.IsCrisisFlagged {
		t.Error("penanda krisis harus tetap muncul walau penyedia AI gagal")
	}
	if !result.IsFallback {
		t.Error("balasan fallback wajib ditandai agar mahasiswa tidak mengira itu jawaban model")
	}
	if result.AIMessage.Text == "" {
		t.Error("fallback tetap harus punya isi")
	}
}

// TestProviderFailureStillPersistsStudentMessage: tulisan mahasiswa tidak boleh
// hilang hanya karena layanan pihak ketiga sedang bermasalah.
func TestProviderFailureStillPersistsStudentMessage(t *testing.T) {
	uc, chats, _, therapist := newChatUsecaseForTest(grantedConsent())
	therapist.err = errors.New("503 dari penyedia")

	_, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{Text: "Halo"})
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}

	if len(chats.messages) != 2 {
		t.Fatalf("pesan mahasiswa + fallback harus tersimpan, dapat %d", len(chats.messages))
	}
	if chats.messages[0].Content != "Halo" {
		t.Error("tulisan mahasiswa harus tersimpan apa adanya")
	}
}

// TestFallbackMessageLeaksNoProviderDetail: pesan error penyedia tidak boleh
// bocor ke mahasiswa.
func TestFallbackMessageLeaksNoProviderDetail(t *testing.T) {
	uc, _, _, therapist := newChatUsecaseForTest(grantedConsent())
	therapist.err = errors.New("gemini: status 401 (UNAUTHENTICATED): API key invalid")

	result, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{Text: "Halo"})
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}

	for _, leaked := range []string{"gemini", "API key", "401", "UNAUTHENTICATED"} {
		if strings.Contains(strings.ToLower(result.AIMessage.Text), strings.ToLower(leaked)) {
			t.Errorf("balasan fallback membocorkan detail penyedia %q: %s", leaked, result.AIMessage.Text)
		}
	}
}

// ------------------------------------------------------------------
// Pemangkasan riwayat (M-AI-03)
// ------------------------------------------------------------------

// TestHistoryTrimmedToConfiguredTurnsOnServer membuktikan pemangkasan terjadi
// di server. Selain soal biaya token, ini membatasi berapa banyak teks pribadi
// yang keluar dari sistem pada setiap panggilan — klien tidak boleh punya cara
// untuk memperbesarnya.
func TestHistoryTrimmedToConfiguredTurnsOnServer(t *testing.T) {
	chats := &fakeChatRepo{}
	// 300 pesan = 150 giliran, jauh di atas batas.
	for i := 0; i < 300; i++ {
		sender := models.ChatSenderUser
		if i%2 == 1 {
			sender = models.ChatSenderAI
		}
		chats.messages = append(chats.messages, models.StudentChatMessage{
			UserID: "student-1", SessionID: "s1", Sender: sender, Content: "pesan",
		})
	}
	chats.sessionID = "s1"

	consents := &fakeConsentRepo{consent: grantedConsent()}
	therapist := &fakeTherapist{reply: "ok"}
	cfg := config.AIConfig{APIKey: "k", MaxTurns: 100}
	uc := NewChatUsecase(chats, consents, therapist, cfg)

	if _, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{Text: "baru"}); err != nil {
		t.Fatalf("send gagal: %v", err)
	}

	if len(therapist.calls) != 1 {
		t.Fatalf("penyedia harus dipanggil sekali, dapat %d", len(therapist.calls))
	}
	sent := therapist.calls[0]
	maxMessages := cfg.MaxTurns * 2
	if len(sent) > maxMessages {
		t.Errorf("riwayat yang dikirim ke pihak ketiga = %d pesan, melebihi batas %d",
			len(sent), maxMessages)
	}
	if sent[len(sent)-1].Text != "baru" {
		t.Error("pesan terbaru harus menjadi giliran terakhir yang dikirim")
	}
	if !sent[len(sent)-1].FromStudent {
		t.Error("giliran terakhir harus ditandai berasal dari mahasiswa")
	}
}

func TestHistoryReportsTruncationHonestly(t *testing.T) {
	chats := &fakeChatRepo{sessionID: "s1"}
	for i := 0; i < 250; i++ {
		chats.messages = append(chats.messages, models.StudentChatMessage{
			UserID: "student-1", SessionID: "s1", Sender: models.ChatSenderUser, Content: "x",
		})
	}
	uc := NewChatUsecase(chats, &fakeConsentRepo{consent: grantedConsent()},
		&fakeTherapist{}, config.AIConfig{APIKey: "k", MaxTurns: 100})

	history, err := uc.History(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("history gagal: %v", err)
	}

	if len(history.Messages) > 200 {
		t.Errorf("riwayat yang ditampilkan = %d, melebihi 100 giliran", len(history.Messages))
	}
	if !history.IsTruncated {
		t.Error("riwayat yang dipotong harus ditandai is_truncated, bukan hilang diam-diam")
	}
	if history.TurnLimit != 100 {
		t.Errorf("turn_limit = %d, harusnya 100", history.TurnLimit)
	}
}

// ------------------------------------------------------------------
// Penyedia tidak dikonfigurasi
// ------------------------------------------------------------------

// TestSendWithoutConfiguredProviderNeverCallsOut: bila GEMINI_API_KEY kosong,
// aplikasi tetap jalan dan TIDAK mengirim apa pun keluar.
func TestSendWithoutConfiguredProviderNeverCallsOut(t *testing.T) {
	chats := &fakeChatRepo{}
	therapist := &fakeTherapist{reply: "seharusnya tidak dipakai"}
	// APIKey kosong -> Enabled() == false.
	uc := NewChatUsecase(chats, &fakeConsentRepo{consent: grantedConsent()},
		therapist, config.AIConfig{MaxTurns: 100})

	result, err := uc.Send(context.Background(), "student-1", dto.SendMessageRequest{Text: "Halo"})
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}

	if len(therapist.calls) != 0 {
		t.Error("penyedia tidak boleh dipanggil saat API key belum dikonfigurasi")
	}
	if !result.IsFallback {
		t.Error("balasan tanpa penyedia harus ditandai fallback")
	}
}

func TestConsentStatusReportsServiceAvailability(t *testing.T) {
	uc := NewChatUsecase(&fakeChatRepo{}, &fakeConsentRepo{consent: grantedConsent()},
		nil, config.AIConfig{MaxTurns: 100})

	status, err := uc.ConsentStatus(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("status gagal: %v", err)
	}

	if status.ServiceAvailable {
		t.Error("service_available harus false saat API key kosong")
	}
	// Sudah setuju, tetapi layanan mati: UI harus bisa menjelaskan sebab yang benar.
	if status.CanChat {
		t.Error("can_chat harus false saat layanan tidak tersedia")
	}
	if status.Notice.NoticeVersion != models.CurrentNoticeVersion {
		t.Error("teks pemberitahuan harus ikut dikirim agar klien tidak perlu request kedua")
	}
}

func TestConsentStatusPendingWhenNeverDecided(t *testing.T) {
	uc := NewChatUsecase(&fakeChatRepo{}, &fakeConsentRepo{consent: nil},
		&fakeTherapist{}, config.AIConfig{APIKey: "k", MaxTurns: 100})

	status, err := uc.ConsentStatus(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("status gagal: %v", err)
	}

	// PENDING dan DENIED harus dapat dibedakan: yang satu memunculkan layar
	// consent, yang lain langsung menampilkan latihan mandiri.
	if status.Status != "PENDING" {
		t.Errorf("status = %q, harusnya PENDING", status.Status)
	}
	if status.CanChat {
		t.Error("can_chat harus false sebelum mahasiswa memutuskan")
	}
	if len(status.Notice.Points) == 0 {
		t.Error("pemberitahuan wajib memuat poin penjelasan")
	}
}
