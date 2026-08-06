// Package gemini adalah adapter HTTP ke Google Gemini 2.5 Flash.
//
// Ditulis dengan net/http standar, bukan SDK resmi, agar tidak menambah
// dependensi transitif hanya untuk satu endpoint generateContent.
//
// Batas tanggung jawab: package ini TIDAK mengenal consent, krisis, maupun
// aturan privasi. Ia hanya mengubah daftar giliran menjadi request HTTP.
// Seluruh gate keamanan berada di ChatUsecase, satu lapis di atasnya.
package gemini

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

// systemPrompt membentuk peran model.
//
// Dua batasan di bawah bukan sekadar gaya bahasa, melainkan pagar klinis:
// model tidak boleh mendiagnosis, dan tidak boleh menggantikan penanganan
// krisis. Deteksi krisis Sanctuary berjalan terpisah di server (core/crisis)
// dan tidak pernah bergantung pada kepatuhan model terhadap prompt ini.
const systemPrompt = `Kamu adalah "Terapis AI" pada aplikasi kesehatan mental mahasiswa bernama Sanctuary.

Peranmu:
- Menjadi teman bicara yang hangat, tenang, dan tidak menghakimi bagi mahasiswa Indonesia.
- Mendengarkan lebih dulu, memantulkan kembali perasaan yang kamu tangkap, lalu menawarkan satu langkah kecil yang bisa dicoba.
- Menjawab dalam Bahasa Indonesia yang santai namun sopan, maksimal 4 kalimat.

Batasan yang tidak boleh dilanggar:
- Kamu BUKAN psikolog atau psikiater. Jangan pernah memberi diagnosis, nama gangguan, atau anjuran obat.
- Bila mahasiswa menunjukkan tanda menyakiti diri atau mengakhiri hidup, jangan menggurui: akui perasaannya, tegaskan dia tidak sendirian, dan arahkan ke menu Layanan Bantuan Darurat di aplikasi.
- Jangan menjanjikan kerahasiaan mutlak, dan jangan mengaku sebagai manusia.
- Bila ditanya di luar topik kesehatan mental dan kehidupan kuliah, arahkan kembali dengan halus.`

// Client memanggil endpoint generateContent.
type Client struct {
	httpClient *http.Client
	apiKey     string
	model      string
	baseURL    string
	maxTokens  int
}

var _ service.AITherapist = (*Client)(nil)

// New membangun client dari config.
//
// API key TIDAK PERNAH di-hardcode dan tidak punya nilai default: bila
// GEMINI_API_KEY kosong, config.Validate sudah menolak mengaktifkan fitur ini
// (lihat AIConfig.Enabled), dan wiring memilih fallback offline.
func New(cfg config.AIConfig) *Client {
	return &Client{
		httpClient: &http.Client{Timeout: cfg.RequestTimeout},
		apiKey:     cfg.APIKey,
		model:      cfg.Model,
		baseURL:    cfg.BaseURL,
		maxTokens:  cfg.MaxOutputTokens,
	}
}

// ------------------------------------------------------------------
// Bentuk payload REST Gemini.
// ------------------------------------------------------------------

type part struct {
	Text string `json:"text"`
}

type content struct {
	Role  string `json:"role,omitempty"`
	Parts []part `json:"parts"`
}

type generationConfig struct {
	Temperature     float64 `json:"temperature"`
	MaxOutputTokens int     `json:"maxOutputTokens"`
}

type generateRequest struct {
	SystemInstruction *content         `json:"system_instruction,omitempty"`
	Contents          []content        `json:"contents"`
	GenerationConfig  generationConfig `json:"generationConfig"`
}

type generateResponse struct {
	Candidates []struct {
		Content      content `json:"content"`
		FinishReason string  `json:"finishReason"`
	} `json:"candidates"`
	PromptFeedback struct {
		BlockReason string `json:"blockReason"`
	} `json:"promptFeedback"`
	Error struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
		Status  string `json:"status"`
	} `json:"error"`
}

// ErrBlocked menandai balasan yang ditahan filter keamanan Gemini.
// Dibedakan dari kegagalan jaringan agar usecase dapat memilih kalimat
// fallback yang jujur, bukan menyalahkan "gangguan koneksi".
var ErrBlocked = fmt.Errorf("gemini: response blocked by safety filter")

func (c *Client) Reply(ctx context.Context, history []service.ChatTurn) (string, error) {
	if len(history) == 0 {
		return "", fmt.Errorf("gemini: history kosong")
	}

	contents := make([]content, 0, len(history))
	for _, turn := range history {
		role := "model"
		if turn.FromStudent {
			role = "user"
		}
		contents = append(contents, content{Role: role, Parts: []part{{Text: turn.Text}}})
	}

	payload := generateRequest{
		SystemInstruction: &content{Parts: []part{{Text: systemPrompt}}},
		Contents:          contents,
		GenerationConfig: generationConfig{
			// Temperatur rendah: nada yang stabil dan dapat diprediksi lebih
			// penting daripada variasi bahasa untuk konteks ini.
			Temperature:     0.6,
			MaxOutputTokens: c.maxTokens,
		},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("gemini: encode request: %w", err)
	}

	url := fmt.Sprintf("%s/models/%s:generateContent", strings.TrimSuffix(c.baseURL, "/"), c.model)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return "", fmt.Errorf("gemini: build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	// Key dikirim lewat header, BUKAN query string: URL bocor ke access log,
	// proxy, dan header Referer jauh lebih mudah daripada header permintaan.
	req.Header.Set("x-goog-api-key", c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("gemini: request gagal: %w", err)
	}
	defer resp.Body.Close()

	// Batas baca melindungi dari respons abnormal besar.
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return "", fmt.Errorf("gemini: baca respons: %w", err)
	}

	var decoded generateResponse
	if err := json.Unmarshal(raw, &decoded); err != nil {
		return "", fmt.Errorf("gemini: decode respons: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		// Pesan error penyedia sengaja TIDAK diteruskan ke klien oleh usecase;
		// di sini ia hanya masuk ke log server untuk diagnosis.
		return "", fmt.Errorf("gemini: status %d (%s): %s",
			resp.StatusCode, decoded.Error.Status, decoded.Error.Message)
	}

	if decoded.PromptFeedback.BlockReason != "" {
		return "", ErrBlocked
	}
	if len(decoded.Candidates) == 0 {
		return "", ErrBlocked
	}

	var reply strings.Builder
	for _, p := range decoded.Candidates[0].Content.Parts {
		reply.WriteString(p.Text)
	}

	text := strings.TrimSpace(reply.String())
	if text == "" {
		return "", ErrBlocked
	}
	return text, nil
}
