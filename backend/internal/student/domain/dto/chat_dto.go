package dto

// ------------------------------------------------------------------
// Terapis AI (M-AI) — KONTEN PRIVAT.
//
// Seluruh struct di berkas ini hanya pernah dikirim ke pemilik akun. Tidak ada
// satu pun DTO peran lain yang boleh menyertakan tipe-tipe ini; test C-15
// (privacy_leak_test.go) menjaga aturan tersebut secara otomatis.
// ------------------------------------------------------------------

// ConsentNoticeResponse adalah isi layar consent (M-AI-01).
//
// Teksnya datang dari server, bukan ditulis di aplikasi, agar pemberitahuan
// yang dibaca mahasiswa tidak dapat berbeda antar versi klien — dan agar
// perbaikan kalimat tidak perlu menunggu rilis toko aplikasi.
type ConsentNoticeResponse struct {
	NoticeVersion string   `json:"notice_version"`
	Title         string   `json:"title"`
	Summary       string   `json:"summary"`
	Points        []string `json:"points"`
	ProviderName  string   `json:"provider_name"`
	AcceptLabel   string   `json:"accept_label"`
	DeclineLabel  string   `json:"decline_label"`
}

// ConsentStatusResponse adalah state gate yang dibaca klien saat membuka tab.
type ConsentStatusResponse struct {
	// Status: PENDING (belum pernah memutuskan) | GRANTED | DENIED.
	// PENDING dibedakan dari DENIED karena keduanya menghasilkan layar berbeda:
	// yang pertama menampilkan pemberitahuan, yang kedua langsung latihan mandiri.
	Status string `json:"status"`

	// CanChat adalah jawaban gate yang sudah dihitung server. Klien tidak perlu
	// (dan tidak boleh) menyimpulkannya sendiri dari kombinasi field lain.
	CanChat bool `json:"can_chat"`

	NoticeVersion string  `json:"notice_version"`
	DecidedAt     *string `json:"decided_at,omitempty"`
	ConsentedAt   *string `json:"consented_at,omitempty"`

	// NeedsRenewal bernilai true bila mahasiswa pernah setuju, tetapi atas teks
	// pemberitahuan versi lama — klien harus menampilkan ulang layar consent.
	NeedsRenewal bool `json:"needs_renewal"`

	// Notice ikut dikirim agar klien tidak perlu request kedua saat harus
	// menampilkan layar consent.
	Notice ConsentNoticeResponse `json:"notice"`

	// ServiceAvailable menyatakan apakah penyedia AI dikonfigurasi di server.
	// Dipisah dari CanChat supaya UI dapat menjelaskan sebab yang benar:
	// "kamu belum setuju" berbeda dari "layanan sedang tidak tersedia".
	ServiceAvailable bool `json:"service_available"`
}

// ConsentDecisionRequest adalah keputusan mahasiswa atas D-5.
type ConsentDecisionRequest struct {
	// Accepted wajib dikirim eksplisit. Tidak ada nilai default: persetujuan
	// tidak boleh terjadi karena field yang lupa diisi.
	Accepted *bool `json:"accepted" binding:"required"`

	// NoticeVersion adalah versi teks yang benar-benar ditampilkan klien.
	// Server menolak versi yang bukan versi berlaku, sehingga aplikasi lama
	// tidak dapat merekam persetujuan atas pemberitahuan yang sudah usang.
	NoticeVersion string `json:"notice_version" binding:"required,max=32"`
}

// ChatMessageResponse adalah satu pesan pada percakapan.
type ChatMessageResponse struct {
	ID     string `json:"id"`
	Sender string `json:"sender"` // USER | AI
	Text   string `json:"text"`
	// IsCrisisFlagged menandai pesan MAHASISWA yang memicu leksikon krisis.
	IsCrisisFlagged bool   `json:"is_crisis_flagged"`
	CreatedAt       string `json:"created_at"`
}

// ChatHistoryResponse adalah isi layar percakapan.
type ChatHistoryResponse struct {
	SessionID string                `json:"session_id"`
	Messages  []ChatMessageResponse `json:"messages"`

	// TurnLimit & IsTruncated membuat pemangkasan 100 giliran (M-AI-03) terlihat
	// jujur di UI, alih-alih membuat pesan lama hilang diam-diam.
	TurnLimit   int  `json:"turn_limit"`
	IsTruncated bool `json:"is_truncated"`

	// CrisisMessage terisi bila ada pesan berpenanda krisis pada riwayat yang
	// ditampilkan, sehingga kartu bantuan tetap muncul saat layar dibuka ulang.
	CrisisMessage string `json:"crisis_message,omitempty"`
}

// SendMessageRequest adalah pesan baru dari mahasiswa.
type SendMessageRequest struct {
	// Batas panjang menahan biaya token sekaligus membatasi banyaknya teks
	// pribadi yang keluar dari sistem dalam satu panggilan.
	Text string `json:"text" binding:"required,min=1,max=4000"`
}

// SendMessageResponse mengembalikan kedua pesan sekaligus, sehingga klien tidak
// perlu menebak bentuk pesannya sendiri lalu berisiko menyimpang dari yang
// tersimpan di server.
type SendMessageResponse struct {
	UserMessage ChatMessageResponse `json:"user_message"`
	AIMessage   ChatMessageResponse `json:"ai_message"`

	// IsCrisisFlagged menyalin penanda dari pesan mahasiswa agar klien cukup
	// memeriksa satu field untuk memutuskan menampilkan kartu bantuan darurat.
	IsCrisisFlagged bool   `json:"is_crisis_flagged"`
	CrisisMessage   string `json:"crisis_message,omitempty"`

	// IsFallback bernilai true bila balasan berasal dari server, bukan dari
	// model (penyedia gagal/timeout). Klien wajib menandainya agar mahasiswa
	// tidak mengira sedang membaca jawaban yang dipersonalisasi.
	IsFallback bool `json:"is_fallback"`
}
