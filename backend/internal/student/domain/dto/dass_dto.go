package dto

// ------------------------------------------------------------------
// DASS-21 — kuesioner, hasil, dan riwayat.
//
// Seluruh endpoint berada di bawah /students/me sehingga hasil skrining hanya
// dapat dibaca pemiliknya. Yang mengalir ke dosen bukan DTO ini, melainkan
// indikator EWS yang sudah diringkas (lihat domain mentor).
// ------------------------------------------------------------------

// DassQuestionResponse adalah satu item kuesioner beserta subskalanya.
// Subskala ikut dikirim agar klien dapat menampilkan pengelompokan tanpa
// menduplikasi pemetaan item — sumber kebenarannya tetap di server.
type DassQuestionResponse struct {
	Number        int    `json:"number"`
	Text          string `json:"text"`
	Subscale      string `json:"subscale"`
	SubscaleLabel string `json:"subscale_label"`
}

type DassAnswerOptionResponse struct {
	Value int    `json:"value"`
	Label string `json:"label"`
}

// DassQuestionnaireResponse dipakai layar pengisian.
type DassQuestionnaireResponse struct {
	Version     string                     `json:"version"`
	Instruction string                     `json:"instruction"`
	Disclaimer  string                     `json:"disclaimer"`
	Questions   []DassQuestionResponse     `json:"questions"`
	Options     []DassAnswerOptionResponse `json:"options"`
}

// SubmitDassRequest memuat 21 jawaban berurutan sesuai nomor soal.
// Panjang dan rentang divalidasi di usecase agar pesan errornya spesifik
// (binding tag hanya bisa mengecek panjang, bukan isi tiap elemen).
type SubmitDassRequest struct {
	Answers []int `json:"answers" binding:"required"`
}

// DassSubscaleResponse adalah hasil satu subskala.
type DassSubscaleResponse struct {
	Subscale      string `json:"subscale"`
	Label         string `json:"label"`
	Score         int    `json:"score"`
	MaxScore      int    `json:"max_score"`
	Severity      string `json:"severity"`
	SeverityLabel string `json:"severity_label"`
	IsSevere      bool   `json:"is_severe"`
}

// DassResultResponse adalah hasil lengkap satu pengisian.
type DassResultResponse struct {
	ID         string               `json:"id"`
	TakenAt    string               `json:"taken_at"`
	TakenDate  string               `json:"taken_date"`
	Depression DassSubscaleResponse `json:"depression"`
	Anxiety    DassSubscaleResponse `json:"anxiety"`
	Stress     DassSubscaleResponse `json:"stress"`
	TotalScore int                  `json:"total_score"`
	// HasSevere memicu tampilan kartu bantuan pada klien.
	HasSevere bool `json:"has_severe"`
	// Disclaimer selalu ikut dikirim agar klien tidak menyimpan sendiri
	// teks yang bisa tertinggal versinya.
	Disclaimer string `json:"disclaimer"`
	// CopingSuggestions disusun dari severity tertinggi.
	CopingSuggestions []string `json:"coping_suggestions,omitempty"`
}

// DassTrendPoint adalah satu titik pada grafik tren riwayat skrining.
type DassTrendPoint struct {
	TakenDate       string `json:"taken_date"`
	DepressionScore int    `json:"depression_score"`
	AnxietyScore    int    `json:"anxiety_score"`
	StressScore     int    `json:"stress_score"`
	TotalScore      int    `json:"total_score"`
}

// DassHistoryResponse dipakai menu "Skrining DASS-21" di tab Profil.
type DassHistoryResponse struct {
	Latest  *DassResultResponse  `json:"latest"`
	Results []DassResultResponse `json:"results"`
	// Trend diurutkan dari yang paling lama agar klien dapat langsung
	// menggambar grafik tanpa membalik daftar.
	Trend []DassTrendPoint `json:"trend"`
	// TotalDelta membandingkan dua skrining terakhir (positif = memburuk).
	// nil bila belum ada dua hasil untuk dibandingkan.
	TotalDelta *int `json:"total_delta"`
	// ChangeLabel adalah pembacaan TotalDelta dalam bahasa manusia.
	ChangeLabel string `json:"change_label"`
	Count       int    `json:"count"`
}
