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
	ID              string  `json:"id"`
	Title           string  `json:"title,omitempty"`
	Preview         string  `json:"preview"`
	JournalDate     string  `json:"journal_date"`
	EmotionLabel    string  `json:"emotion_label,omitempty"`
	IsCrisisFlagged bool    `json:"is_crisis_flagged"`
	AnalyzedAt      *string `json:"analyzed_at,omitempty"`
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
