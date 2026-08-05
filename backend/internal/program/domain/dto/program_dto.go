package dto

// MetricCardResponse adalah satu kartu metrik pada dashboard Kaprodi.
// Value bertipe pointer: null saat k-anonymity belum terpenuhi.
//
// Unit "%" menandai kartu yang nilainya persentase, bukan hitungan orang —
// klien memakai penanda ini untuk memformat angka, bukan menebak dari Key.
type MetricCardResponse struct {
	Key   string   `json:"key"`
	Label string   `json:"label"`
	Value *float64 `json:"value"`
	Unit  string   `json:"unit,omitempty"`
	Hint  string   `json:"hint,omitempty"`
}

// EWSShareResponse adalah satu potong sebaran tingkat perhatian (K-DAS-07).
//
// SENGAJA TANPA FIELD JUMLAH. Mengirim hitungan mentah per level akan membatalkan
// D-9: "perlu intervensi" sudah dipaksa tampil sebagai persentase justru karena
// angka kecil dapat menunjuk orang tertentu, dan angka itu akan bocor kembali
// lewat pintu belakang bila sebaran dikirim sebagai hitungan.
type EWSShareResponse struct {
	Level      string  `json:"level"`
	LevelLabel string  `json:"level_label"`
	Percentage float64 `json:"percentage"`
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
	EWSDistribution []EWSShareResponse   `json:"ews_distribution,omitempty"`
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
	AccessLimits  []string `json:"access_limits"`
}
