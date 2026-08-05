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

	HasOpenContactRequest bool   `json:"has_open_contact_request"`
	ContactRequestNote    string `json:"contact_request_note,omitempty"`

	LastCheckinDate *string             `json:"last_checkin_date,omitempty"`
	EWS             *EWSSummaryResponse `json:"ews"`
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

	HasOpenContactRequest bool `json:"has_open_contact_request"`
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
