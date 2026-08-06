package dto

type CreateJournalRequest struct {
	Title string `json:"title" binding:"omitempty,max=160"`
	// Content adalah konten privat; batas panjang mencegah abuse penyimpanan.
	Content string `json:"content" binding:"required,min=1,max=20000"`
	// JournalDate opsional (format YYYY-MM-DD); default hari ini.
	JournalDate string `json:"journal_date" binding:"omitempty,datetime=2006-01-02"`
	// AnalyzeNow memicu analisis emosi langsung setelah tersimpan.
	AnalyzeNow bool `json:"analyze_now"`
}

type JournalResponse struct {
	ID                string   `json:"id"`
	Title             string   `json:"title,omitempty"`
	Content           string   `json:"content"`
	JournalDate       string   `json:"journal_date"`
	EmotionLabel      string   `json:"emotion_label,omitempty"`
	EmotionConfidence *float64 `json:"emotion_confidence,omitempty"`
	SentimentScore    *float64 `json:"sentiment_score,omitempty"`
	IsCrisisFlagged   bool     `json:"is_crisis_flagged"`
	AnalyzedAt        *string  `json:"analyzed_at,omitempty"`
	CreatedAt         string   `json:"created_at"`
}

// JournalListItemResponse sengaja TIDAK memuat `content` agar payload daftar
// tetap ringan; konten hanya dikirim pada endpoint detail milik pemiliknya.
type JournalListItemResponse struct {
	ID               string  `json:"id"`
	Title            string  `json:"title,omitempty"`
	Preview          string  `json:"preview"`
	JournalDate      string  `json:"journal_date"`
	EmotionLabel     string  `json:"emotion_label,omitempty"`
	EmotionLabelText string  `json:"emotion_label_text,omitempty"`
	IsCrisisFlagged  bool    `json:"is_crisis_flagged"`
	AnalyzedAt       *string `json:"analyzed_at,omitempty"`
}

// AnalysisResponse adalah hasil trigger "Analisis Emosi".
type AnalysisResponse struct {
	JournalID         string   `json:"journal_id"`
	EmotionLabel      string   `json:"emotion_label"`
	EmotionLabelText  string   `json:"emotion_label_text"`
	EmotionConfidence float64  `json:"emotion_confidence"`
	SentimentScore    float64  `json:"sentiment_score"`
	IsCrisisFlagged   bool     `json:"is_crisis_flagged"`
	CopingSuggestions []string `json:"coping_suggestions"`
	CrisisMessage     string   `json:"crisis_message,omitempty"`
	AnalyzedAt        string   `json:"analyzed_at"`
	// ModelVersion menjaga transparansi (layar "Edukasi Model" di profil).
	ModelVersion string `json:"model_version"`
}

// ------------------------------------------------------------------
// Riwayat Analisis Emosi (menu di tab Profil).
//
// Yang ditampilkan adalah HASIL analisis, bukan tulisan lengkapnya —
// preview singkat disertakan hanya agar pemilik akun dapat mengenali
// catatan mana yang dimaksud.
// ------------------------------------------------------------------

type EmotionHistoryItemResponse struct {
	JournalID         string   `json:"journal_id"`
	Title             string   `json:"title,omitempty"`
	Preview           string   `json:"preview"`
	JournalDate       string   `json:"journal_date"`
	AnalyzedAt        string   `json:"analyzed_at"`
	EmotionLabel      string   `json:"emotion_label"`
	EmotionLabelText  string   `json:"emotion_label_text"`
	EmotionConfidence float64  `json:"emotion_confidence"`
	SentimentScore    float64  `json:"sentiment_score"`
	IsCrisisFlagged   bool     `json:"is_crisis_flagged"`
	CopingSuggestions []string `json:"coping_suggestions,omitempty"`
}

// ------------------------------------------------------------------
// Sebaran Emosi (M-MOOD-04) — tab Mood.
//
// Bentuk ini sengaja HANYA berisi angka. Tidak ada `content`, tidak ada
// `preview`, tidak ada judul jurnal: grafik sebaran tidak membutuhkannya, dan
// mengirim tulisan pribadi ke layar yang tidak menampilkannya hanya menambah
// permukaan kebocoran tanpa manfaat.
//
// D-3: seluruh angka di sini berasal dari analisis jurnal, BUKAN dari check-in
// mood manual — supaya EWS #2 (NEGATIVE_EMOTION_RATIO) tidak menghitung satu
// hari buruk dua kali.
// ------------------------------------------------------------------

type EmotionDistributionResponse struct {
	PeriodDays int    `json:"period_days"`
	From       string `json:"from"`
	To         string `json:"to"`

	Distribution []EmotionShareResponse `json:"distribution"`

	TotalAnalyzed       int     `json:"total_analyzed"`
	CrisisFlaggedCount  int     `json:"crisis_flagged_count"`
	DominantEmotion     string  `json:"dominant_emotion,omitempty"`
	DominantEmotionText string  `json:"dominant_emotion_text,omitempty"`
	NegativeRatio       float64 `json:"negative_ratio"`

	// ModelVersion menjaga transparansi: angka pada grafik adalah keluaran
	// model versi ini, dengan segala keterbatasannya.
	ModelVersion string `json:"model_version"`

	// IsEmpty membuat klien menampilkan empty state yang jujur ("belum ada
	// jurnal dianalisis") alih-alih menggambar grafik kosong yang terlihat
	// seperti "emosimu nol".
	IsEmpty bool   `json:"is_empty"`
	Message string `json:"message,omitempty"`
}

// EmotionTrendPointResponse adalah satu titik pada grafik perkembangan
// sentimen, diurutkan dari yang paling lama.
type EmotionTrendPointResponse struct {
	Date             string  `json:"date"`
	SentimentScore   float64 `json:"sentiment_score"`
	EmotionLabel     string  `json:"emotion_label"`
	EmotionLabelText string  `json:"emotion_label_text"`
}

type EmotionHistoryResponse struct {
	Items        []EmotionHistoryItemResponse `json:"items"`
	Distribution []EmotionShareResponse       `json:"distribution"`
	Trend        []EmotionTrendPointResponse  `json:"trend"`

	TotalAnalyzed       int     `json:"total_analyzed"`
	CrisisFlaggedCount  int     `json:"crisis_flagged_count"`
	DominantEmotion     string  `json:"dominant_emotion,omitempty"`
	DominantEmotionText string  `json:"dominant_emotion_text,omitempty"`
	NegativeRatio       float64 `json:"negative_ratio"`

	// ModelVersion & Accuracy ikut dikirim agar layar riwayat dapat menyatakan
	// batas ketelitian di tempat hasilnya dibaca, bukan hanya di layar edukasi.
	ModelVersion string `json:"model_version"`

	IsSufficient bool   `json:"is_sufficient"`
	Message      string `json:"message,omitempty"`
}
