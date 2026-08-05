package dto

// UpdatePrivacySettingRequest — 3 tingkat berbagi + 2 permission terpisah.
type UpdatePrivacySettingRequest struct {
	ShareLevel            string `json:"share_level" binding:"required,oneof=CLOSED SUMMARY SUMMARY_TREND"`
	AllowEarlyWarning     *bool  `json:"allow_early_warning" binding:"required"`
	AllowProgramStatistic *bool  `json:"allow_program_statistic" binding:"required"`
}

type PrivacySettingResponse struct {
	ShareLevel      string `json:"share_level"`
	ShareLevelLabel string `json:"share_level_label"`
	// Effect menjelaskan konsekuensi pilihan dengan bahasa yang dipahami mahasiswa.
	Effect string `json:"effect"`

	AllowEarlyWarning     bool `json:"allow_early_warning"`
	AllowProgramStatistic bool `json:"allow_program_statistic"`

	// Ringkasan turunan agar UI tidak perlu menduplikasi aturan bisnis.
	AdvisorCanSeeIndicator bool `json:"advisor_can_see_indicator"`
	AdvisorCanSeeTrend     bool `json:"advisor_can_see_trend"`
	AdvisorCanGetAlert     bool `json:"advisor_can_get_alert"`

	UpdatedAt string `json:"updated_at,omitempty"`
}

// PrivacyOptionResponse dipakai layar Privasi & Berbagi Data untuk merender
// pilihan tanpa hardcode label di sisi klien.
type PrivacyOptionResponse struct {
	Value       string `json:"value"`
	Label       string `json:"label"`
	Description string `json:"description"`
}
