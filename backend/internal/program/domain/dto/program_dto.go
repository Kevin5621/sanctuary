package dto

// MetricCardResponse adalah satu kartu metrik pada dashboard Kaprodi.
// Value bertipe pointer: null saat k-anonymity belum terpenuhi.
type MetricCardResponse struct {
	Key   string   `json:"key"`
	Label string   `json:"label"`
	Value *float64 `json:"value"`
	Unit  string   `json:"unit,omitempty"`
	Hint  string   `json:"hint,omitempty"`
}

// ProgramDashboardResponse — 6 metrik agregat + sebaran EWS.
// Seluruh angka hanya keluar bila kelompok memenuhi ambang k-anonymity.
type ProgramDashboardResponse struct {
	IsSufficient     bool   `json:"is_sufficient"`
	GroupSize        int    `json:"group_size"`
	MinimumGroupSize int    `json:"minimum_group_size"`
	Message          string `json:"message,omitempty"`

	PeriodDays      int                  `json:"period_days"`
	Metrics         []MetricCardResponse `json:"metrics"`
	EWSDistribution map[string]int       `json:"ews_distribution,omitempty"`
}

type AdvisorLoadResponse struct {
	AdvisorID      string `json:"advisor_id"`
	FullName       string `json:"full_name"`
	LecturerNumber string `json:"lecturer_number,omitempty"`
	Email          string `json:"email"`
	AdviseeCount   int    `json:"advisee_count"`
}

// CohortReportResponse — evaluasi per angkatan.
// Angkatan dengan peserta di bawah ambang tetap tampil, namun tanpa angka.
type CohortReportResponse struct {
	CohortYear       int      `json:"cohort_year"`
	IsSufficient     bool     `json:"is_sufficient"`
	GroupSize        int      `json:"group_size"`
	MinimumGroupSize int      `json:"minimum_group_size"`
	Message          string   `json:"message,omitempty"`
	AvgMood          *float64 `json:"avg_mood"`
	AvgStress        *float64 `json:"avg_stress"`
	AvgSleepHours    *float64 `json:"avg_sleep_hours"`
	ActiveStudents   *int     `json:"active_students"`
}

// ProgramProfileResponse — tab Profil kaprodi (identitas & batas akses).
type ProgramProfileResponse struct {
	ProgramID     string   `json:"program_id"`
	ProgramName   string   `json:"program_name"`
	TotalStudents int      `json:"total_students"`
	TotalAdvisors int      `json:"total_advisors"`
	AccessNotes   []string `json:"access_notes"`
}
