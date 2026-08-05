package dto

// DailyMetricResponse adalah satu titik check-in harian (kuantitatif saja —
// tidak ada konten bebas, sehingga aman ditampilkan di ringkasan Beranda).
type DailyMetricResponse struct {
	Date             string  `json:"date"` // YYYY-MM-DD
	MoodScore        int     `json:"mood_score"`
	StressLevel      int     `json:"stress_level"`
	SleepHours       float64 `json:"sleep_hours"`
	EmotionLabel     string  `json:"emotion_label,omitempty"`
	EmotionLabelText string  `json:"emotion_label_text,omitempty"`
	AcademicTrigger  string  `json:"academic_trigger,omitempty"`
}

// WeeklyMoodSummaryResponse memuat data untuk kartu "Ringkasan Hari Ini" dan
// "Kalender Mood Mingguan" pada Beranda. Hanya hari yang sudah diisi yang
// muncul di Days — hari kosong ditampilkan sebagai state "belum check-in"
// oleh klien.
type WeeklyMoodSummaryResponse struct {
	WeekStart string                `json:"week_start"`
	WeekEnd   string                `json:"week_end"`
	Today     *DailyMetricResponse  `json:"today"`
	Days      []DailyMetricResponse `json:"days"`
}

type SaveDailyMetricRequest struct {
	MetricDate      string  `json:"metric_date"` // YYYY-MM-DD (opsional, default hari ini)
	MoodScore       int     `json:"mood_score" binding:"required,min=1,max=5"`
	StressLevel     int     `json:"stress_level"`
	SleepHours      float64 `json:"sleep_hours"`
	EmotionLabel    string  `json:"emotion_label"`
	AcademicTrigger string  `json:"academic_trigger"`
}

