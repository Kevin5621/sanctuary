// Package dto memuat SELURUH bentuk data yang boleh keluar ke Dosen Pembimbing.
//
// ATURAN STRUKTURAL (D-6 / C-15) — dibaca sebelum menambah field apa pun:
//
// Tidak satu pun struct di file ini boleh memiliki field yang memuat teks yang
// ditulis mahasiswa: isi jurnal, percakapan Terapis AI, maupun
// student_contact_requests.note. Dosen berhak tahu SIAPA dan KAPAN, tidak
// pernah MENGAPA — alasan disampaikan langsung oleh mahasiswa di luar aplikasi.
//
// Aturan ini ditegakkan otomatis oleh mentor_dto_privacy_test.go, yang memindai
// struct di package ini lewat refleksi dan GAGAL bila field terlarang muncul
// kembali. Jika test itu gagal, perbaiki DTO-nya — bukan test-nya.
package dto

// IndicatorResponse adalah rincian satu indikator EWS.
type IndicatorResponse struct {
	Code      string  `json:"code"`
	Label     string  `json:"label"`
	Triggered bool    `json:"triggered"`
	Value     float64 `json:"value"`
	Threshold float64 `json:"threshold"`
	Detail    string  `json:"detail"`
}

// EWSSummaryResponse hanya dikirim bila mahasiswa mengizinkan peringatan dini.
type EWSSummaryResponse struct {
	Level        string              `json:"level"`
	LevelLabel   string              `json:"level_label"`
	Score        int                 `json:"score"`
	IsSufficient bool                `json:"is_sufficient"`
	DataPoints   int                 `json:"data_points"`
	WindowDays   int                 `json:"window_days"`
	EvaluatedAt  string              `json:"evaluated_at"`
	Indicators   []IndicatorResponse `json:"indicators"`
}

// AdviseeListItemResponse adalah satu baris pada tab Bimbingan.
// Field kondisi bernilai null bila mahasiswa memilih tingkat berbagi Tertutup.
type AdviseeListItemResponse struct {
	StudentID     string  `json:"student_id"`
	FullName      string  `json:"full_name"`
	StudentNumber *string `json:"student_number,omitempty"`
	CohortYear    *int    `json:"cohort_year,omitempty"`

	ShareLevel      string `json:"share_level"`
	ShareLevelLabel string `json:"share_level_label"`
	// PrivacyNotice menjelaskan ke dosen mengapa data tidak tampil.
	PrivacyNotice string `json:"privacy_notice,omitempty"`

	// Hanya FAKTA permintaan + waktunya. Alasan (kolom `note`) TIDAK PERNAH
	// disertakan — lihat catatan package di atas (D-6).
	HasOpenContactRequest bool    `json:"has_open_contact_request"`
	ContactRequestedAt    *string `json:"contact_requested_at,omitempty"`

	LastCheckinDate *string             `json:"last_checkin_date,omitempty"`
	EWS             *EWSSummaryResponse `json:"ews"`
}

// ContactRequestItemResponse adalah satu baris daftar "minta dihubungi"
// (L-BIM-03).
//
// SENGAJA TIDAK DISERTAKAN: `student_contact_requests.note`. Kolomnya tetap ada
// di basis data karena mahasiswa boleh menuliskannya untuk dirinya sendiri,
// tetapi tidak pernah dibaca — bahkan tidak di-SELECT oleh repository.
// Juga tidak disertakan: indikator kondisi & EWS. Permintaan dihubungi adalah
// persetujuan spesifik untuk dihubungi (D-7), bukan izin melihat data — mahasiswa
// dengan share_level CLOSED tetap muncul di sini dan tetap tanpa satu angka pun.
type ContactRequestItemResponse struct {
	RequestID     string  `json:"request_id"`
	StudentID     string  `json:"student_id"`
	FullName      string  `json:"full_name"`
	StudentNumber *string `json:"student_number,omitempty"`
	RequestedAt   string  `json:"requested_at"`
}

// WeeklyTrendPointResponse hanya terisi pada level Ringkasan + Tren.
type WeeklyTrendPointResponse struct {
	WeekStart string  `json:"week_start"`
	AvgMood   float64 `json:"avg_mood"`
	AvgStress float64 `json:"avg_stress"`
	AvgSleep  float64 `json:"avg_sleep"`
	Entries   int     `json:"entries"`
}

// ConditionSummaryResponse adalah indikator kondisi agregat milik satu mahasiswa.
// Tidak pernah memuat teks jurnal maupun percakapan AI.
type ConditionSummaryResponse struct {
	AvgMood       float64 `json:"avg_mood"`
	AvgStress     float64 `json:"avg_stress"`
	AvgSleepHours float64 `json:"avg_sleep_hours"`
	CheckinCount  int     `json:"checkin_count"`
	WindowDays    int     `json:"window_days"`
}

type StudentIndicatorResponse struct {
	StudentID       string  `json:"student_id"`
	FullName        string  `json:"full_name"`
	StudentNumber   *string `json:"student_number,omitempty"`
	ShareLevel      string  `json:"share_level"`
	ShareLevelLabel string  `json:"share_level_label"`
	PrivacyNotice   string  `json:"privacy_notice,omitempty"`

	Summary *ConditionSummaryResponse  `json:"summary"`
	Trend   []WeeklyTrendPointResponse `json:"trend"`
	EWS     *EWSSummaryResponse        `json:"ews"`

	// Sama seperti daftar: fakta + waktu, tanpa alasan (D-6).
	HasOpenContactRequest bool    `json:"has_open_contact_request"`
	ContactRequestedAt    *string `json:"contact_requested_at,omitempty"`
}

// MentorProfileResponse mengisi tab Profil dosen (L-PRO-02..03).
// Hanya angka administratif — tidak ada data kondisi mahasiswa di sini.
type MentorProfileResponse struct {
	AdviseeCount       int      `json:"advisee_count"`
	OpenContactRequest int      `json:"open_contact_request"`
	AccessLimits       []string `json:"access_limits"`
}

// EmotionShareResponse dipakai sebaran emosi kelompok.
type EmotionShareResponse struct {
	EmotionLabel string  `json:"emotion_label"`
	Total        int     `json:"total"`
	Percentage   float64 `json:"percentage"`
}

// GroupConditionResponse adalah tab Kondisi (agregat kelompok bimbingan).
// Wajib melewati k-anonymity: bila anggota < ambang, seluruh angka null.
type GroupConditionResponse struct {
	IsSufficient     bool   `json:"is_sufficient"`
	GroupSize        int    `json:"group_size"`
	MinimumGroupSize int    `json:"minimum_group_size"`
	Message          string `json:"message,omitempty"`

	PeriodDays    int      `json:"period_days"`
	AvgMood       *float64 `json:"avg_mood"`
	AvgStress     *float64 `json:"avg_stress"`
	AvgSleepHours *float64 `json:"avg_sleep_hours"`

	EWSDistribution     map[string]int         `json:"ews_distribution,omitempty"`
	EmotionDistribution []EmotionShareResponse `json:"emotion_distribution,omitempty"`
}
