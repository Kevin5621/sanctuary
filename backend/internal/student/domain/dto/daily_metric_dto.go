package dto

// DailyMetricResponse adalah satu titik check-in harian (kuantitatif saja —
// tidak ada konten bebas, sehingga aman ditampilkan di ringkasan Beranda).
//
// Tidak ada label emosi di sini. Check-in menanyakan satu hal tentang perasaan
// — skala mood 1..5 — dan itulah yang digambar kalender. Emosi bernama (JOY,
// SAD, …) hanya lahir dari analisis jurnal (D-3).
type DailyMetricResponse struct {
	Date        string  `json:"date"` // YYYY-MM-DD
	MoodScore   int     `json:"mood_score"`
	MoodLabel   string  `json:"mood_label"`
	StressLevel int     `json:"stress_level"`
	StressLabel string  `json:"stress_label"`
	SleepHours  float64 `json:"sleep_hours"`

	AcademicTrigger string `json:"academic_trigger,omitempty"`
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
	// CheckinCount & CurrentStreak dipakai kartu ringkasan Beranda agar klien
	// tidak menghitung ulang hal yang sudah diketahui server.
	CheckinCount  int `json:"checkin_count"`
	CurrentStreak int `json:"current_streak"`
}

type SaveDailyMetricRequest struct {
	// MetricDate opsional (YYYY-MM-DD); default hari ini.
	MetricDate      string  `json:"metric_date" binding:"omitempty,datetime=2006-01-02"`
	MoodScore       int     `json:"mood_score" binding:"required,min=1,max=5"`
	StressLevel     int     `json:"stress_level" binding:"required,min=1,max=5"`
	SleepHours      float64 `json:"sleep_hours" binding:"min=0,max=24"`
	AcademicTrigger string  `json:"academic_trigger" binding:"omitempty,max=255"`
}

// ------------------------------------------------------------------
// Opsi check-in — dikirim server agar klien tidak menyimpan daftarnya sendiri.
// ------------------------------------------------------------------

type ScaleOptionResponse struct {
	Value int    `json:"value"`
	Label string `json:"label"`
}

type CodedOptionResponse struct {
	Value string `json:"value"`
	Label string `json:"label"`
}

type DailyMetricOptionsResponse struct {
	MoodScale   []ScaleOptionResponse `json:"mood_scale"`
	StressScale []ScaleOptionResponse `json:"stress_scale"`
	// MaxBackdateDays memberi tahu klien sampai berapa hari ke belakang
	// pemilih tanggal boleh dibuka, sehingga batas itu tidak diduplikasi.
	MaxBackdateDays int `json:"max_backdate_days"`
}

// ------------------------------------------------------------------
// Riwayat mood — kalender bulanan & statistik periode.
// ------------------------------------------------------------------

// MonthlyMoodResponse dipakai kalender mood bulanan pada tab Mood.
// Days hanya memuat hari yang terisi; klien menggambar sisanya sebagai kosong.
type MonthlyMoodResponse struct {
	Month       string                `json:"month"` // YYYY-MM
	MonthLabel  string                `json:"month_label"`
	FirstDate   string                `json:"first_date"`
	LastDate    string                `json:"last_date"`
	DaysInMonth int                   `json:"days_in_month"`
	Days        []DailyMetricResponse `json:"days"`

	CheckinCount int     `json:"checkin_count"`
	AvgMood      float64 `json:"avg_mood"`

	// HasNextMonth mencegah klien menawarkan navigasi ke bulan depan.
	HasNextMonth bool `json:"has_next_month"`
}

// MoodTrendPoint adalah satu titik pada grafik ritme mood.
type MoodTrendPoint struct {
	Date        string  `json:"date"`
	MoodScore   int     `json:"mood_score"`
	StressLevel int     `json:"stress_level"`
	SleepHours  float64 `json:"sleep_hours"`
}

// EmotionShareResponse adalah satu irisan sebaran emosi.
type EmotionShareResponse struct {
	Emotion    string  `json:"emotion"`
	Label      string  `json:"label"`
	Count      int     `json:"count"`
	Percentage float64 `json:"percentage"`
	IsNegative bool    `json:"is_negative"`
}

// TriggerShareResponse memperlihatkan pemicu yang paling sering muncul.
type TriggerShareResponse struct {
	Trigger string `json:"trigger"`
	Label   string `json:"label"`
	Count   int    `json:"count"`
}

// MoodStatsResponse adalah bahan seluruh kartu statistik pada tab Mood.
type MoodStatsResponse struct {
	PeriodDays int    `json:"period_days"`
	From       string `json:"from"`
	To         string `json:"to"`

	// Tidak ada sebaran emosi di sini. Statistik ini dibangun dari check-in yang
	// kuantitatif; sebaran emosi milik tab Mood dilayani endpoint jurnal
	// (M-MOOD-04 / D-3) agar satu hari buruk tidak terhitung dua kali.
	Points      []MoodTrendPoint       `json:"points"`
	TopTriggers []TriggerShareResponse `json:"top_triggers"`

	CheckinCount  int     `json:"checkin_count"`
	AvgMood       float64 `json:"avg_mood"`
	AvgStress     float64 `json:"avg_stress"`
	AvgSleepHours float64 `json:"avg_sleep_hours"`

	// CurrentStreak dihitung mundur dari hari ini; hari tanpa check-in memutus
	// rangkaian (aturan yang sama dipakai indikator EWS).
	CurrentStreak int `json:"current_streak"`
	LongestStreak int `json:"longest_streak"`

	// IsSufficient false berarti klien menampilkan "Data belum cukup" alih-alih
	// grafik yang terlihat meyakinkan padahal ditarik dari satu-dua titik.
	IsSufficient bool   `json:"is_sufficient"`
	Message      string `json:"message,omitempty"`
}
