package config

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// Config adalah single source of truth konfigurasi runtime (ENV-first).
// Tidak boleh ada business default yang di-hardcode di usecase/handler.
type Config struct {
	App        AppConfig
	Database   DatabaseConfig
	Redis      RedisConfig
	Security   SecurityConfig
	RateLimit  RateLimitConfig
	Pagination PaginationConfig
	Privacy    PrivacyConfig
	EWS        EWSConfig
	Student    StudentConfig
	AI         AIConfig
	Seeder     SeederConfig
}

type AppConfig struct {
	Env      string
	Name     string
	Port     string
	LogLevel string
	Timezone string
}

func (a AppConfig) IsProduction() bool { return a.Env == "production" }

type DatabaseConfig struct {
	DSN             string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
	QueryTimeout    time.Duration
	AutoMigrate     bool
	AutoSeed        bool
}

type RedisConfig struct {
	Addr     string
	Password string
	DB       int
}

func (r RedisConfig) Enabled() bool { return r.Addr != "" }

type SecurityConfig struct {
	JWTSecret    string
	AccessTTL    time.Duration
	RefreshTTL   time.Duration
	CookieDomain string
	CookieSecure bool
	AllowOrigins []string
}

type RateLimitConfig struct {
	LoginPerMinute   int
	GeneralPerMinute int
	FailClosed       bool
}

type PaginationConfig struct {
	DefaultPerPage int
	MaxPerPage     int
}

type PrivacyConfig struct {
	KAnonymityMinGroup int
}

// EWSConfig adalah parameter klinis Early Warning System.
// Semua ambang dapat dikonfigurasi agar dapat dikalibrasi tanpa deploy ulang kode.
type EWSConfig struct {
	LookbackDays           int
	MinDataPoints          int
	LowMoodThreshold       int
	LowMoodMinStreakDays   int
	NegativeEmotionRatio   float64
	NegativeEmotionSamples int
	LowSleepHours          float64
	LowSleepMinNights      int
}

// StudentConfig adalah aturan pengisian data milik mahasiswa sendiri.
type StudentConfig struct {
	// CheckinMaxBackdateDays & JournalMaxBackdateDays membatasi seberapa jauh ke
	// belakang check-in mood dan jurnal boleh diisi.
	//
	// Keduanya terpisah karena tujuannya berbeda. Check-in diisi dari kalender
	// tab Mood: menutup celah sebulan ke belakang adalah alasan kalender itu
	// bisa diketuk. Jurnal tetap 7 hari (D-8) — ia berisi cerita, dan cerita
	// yang ditulis sebulan kemudian sudah bukan catatan hari itu.
	CheckinMaxBackdateDays int
	JournalMaxBackdateDays int
	// MoodStatsDefaultPeriod & MoodStatsMaxPeriod membatasi rentang statistik
	// yang boleh diminta klien (mencegah query tanpa batas).
	MoodStatsDefaultPeriod int
	MoodStatsMaxPeriod     int
}

// AIConfig mengatur integrasi Terapis AI (Gemini 2.5 Flash).
//
// APIKey TIDAK memiliki nilai default. Bila kosong, Enabled() bernilai false
// dan wiring memilih penyedia fallback offline — aplikasi tetap jalan, tab
// Terapis AI tetap ada, tetapi tidak ada satu byte pun teks mahasiswa yang
// dikirim keluar. Ini pilihan fail-safe yang disengaja: konfigurasi yang lupa
// diisi harus berujung pada "tidak mengirim", bukan pada crash saat runtime
// atau pada key placeholder yang tanpa sadar ikut ter-commit.
type AIConfig struct {
	APIKey  string
	Model   string
	BaseURL string
	// RequestTimeout memutus panggilan yang menggantung. Mahasiswa yang sedang
	// menunggu balasan tidak boleh dibiarkan melihat spinner tanpa akhir.
	RequestTimeout  time.Duration
	MaxOutputTokens int
	// MaxTurns membatasi giliran percakapan yang dikirim ke penyedia sekaligus
	// yang ditampilkan (M-AI-03). Batas ini juga membatasi jumlah teks pribadi
	// yang keluar dari sistem pada setiap panggilan.
	MaxTurns int
}

// Enabled menentukan apakah panggilan ke penyedia pihak ketiga boleh dilakukan.
func (a AIConfig) Enabled() bool { return a.APIKey != "" }

type SeederConfig struct {
	DefaultPassword string
}

// Load membaca .env (bila ada) lalu ENV, memvalidasi, dan mem-propagasi
// nilai ke helper core (apptime, pagination, k-anonymity).
func Load() (*Config, error) {
	_ = godotenv.Load()

	cfg := &Config{
		App: AppConfig{
			Env:      getString("APP_ENV", "development"),
			Name:     getString("APP_NAME", "sanctuary-api"),
			Port:     getString("HTTP_PORT", "8080"),
			LogLevel: getString("LOG_LEVEL", "info"),
			Timezone: getString("APP_TIMEZONE", "Asia/Jakarta"),
		},
		Database: DatabaseConfig{
			DSN:             getString("DB_DSN", ""),
			MaxOpenConns:    getInt("DB_MAX_OPEN_CONNS", 25),
			MaxIdleConns:    getInt("DB_MAX_IDLE_CONNS", 10),
			ConnMaxLifetime: time.Duration(getInt("DB_CONN_MAX_LIFETIME_MINUTES", 30)) * time.Minute,
			QueryTimeout:    time.Duration(getInt("DB_QUERY_TIMEOUT_SECONDS", 5)) * time.Second,
			AutoMigrate:     getBool("DB_AUTO_MIGRATE", false),
			AutoSeed:        getBool("DB_AUTO_SEED", false),
		},
		Redis: RedisConfig{
			Addr:     getString("REDIS_ADDR", ""),
			Password: getString("REDIS_PASSWORD", ""),
			DB:       getInt("REDIS_DB", 0),
		},
		Security: SecurityConfig{
			JWTSecret:    getString("JWT_SECRET", ""),
			AccessTTL:    time.Duration(getInt("JWT_ACCESS_TTL_MINUTES", 15)) * time.Minute,
			RefreshTTL:   time.Duration(getInt("JWT_REFRESH_TTL_HOURS", 720)) * time.Hour,
			CookieDomain: getString("COOKIE_DOMAIN", "localhost"),
			CookieSecure: getBool("COOKIE_SECURE", true),
			AllowOrigins: getStringSlice("ALLOW_ORIGINS", []string{"http://localhost:3000"}),
		},
		RateLimit: RateLimitConfig{
			LoginPerMinute:   getInt("RATE_LIMIT_LOGIN_PER_MINUTE", 10),
			GeneralPerMinute: getInt("RATE_LIMIT_GENERAL_PER_MINUTE", 120),
			FailClosed:       getBool("RATE_LIMIT_FAIL_CLOSED", true),
		},
		Pagination: PaginationConfig{
			DefaultPerPage: getInt("PAGINATION_DEFAULT_PER_PAGE", 20),
			MaxPerPage:     getInt("PAGINATION_MAX_PER_PAGE", 20),
		},
		Privacy: PrivacyConfig{
			KAnonymityMinGroup: getInt("K_ANONYMITY_MIN_GROUP", 5),
		},
		EWS: EWSConfig{
			LookbackDays:           getInt("EWS_LOOKBACK_DAYS", 14),
			MinDataPoints:          getInt("EWS_MIN_DATA_POINTS", 4),
			LowMoodThreshold:       getInt("EWS_LOW_MOOD_THRESHOLD", 2),
			LowMoodMinStreakDays:   getInt("EWS_LOW_MOOD_MIN_STREAK_DAYS", 5),
			NegativeEmotionRatio:   getFloat("EWS_NEGATIVE_EMOTION_RATIO", 0.6),
			NegativeEmotionSamples: getInt("EWS_NEGATIVE_EMOTION_MIN_SAMPLES", 4),
			LowSleepHours:          getFloat("EWS_LOW_SLEEP_HOURS", 5),
			LowSleepMinNights:      getInt("EWS_LOW_SLEEP_MIN_NIGHTS", 2),
		},
		Student: StudentConfig{
			CheckinMaxBackdateDays: getInt("STUDENT_CHECKIN_MAX_BACKDATE_DAYS", 30),
			JournalMaxBackdateDays: getInt("STUDENT_JOURNAL_MAX_BACKDATE_DAYS", 7),
			MoodStatsDefaultPeriod: getInt("STUDENT_MOOD_STATS_DEFAULT_DAYS", 30),
			MoodStatsMaxPeriod:     getInt("STUDENT_MOOD_STATS_MAX_DAYS", 365),
		},
		AI: AIConfig{
			APIKey:          getString("GEMINI_API_KEY", ""),
			Model:           getString("GEMINI_MODEL", "gemini-2.5-flash"),
			BaseURL:         getString("GEMINI_BASE_URL", "https://generativelanguage.googleapis.com/v1beta"),
			RequestTimeout:  time.Duration(getInt("GEMINI_TIMEOUT_SECONDS", 20)) * time.Second,
			MaxOutputTokens: getInt("GEMINI_MAX_OUTPUT_TOKENS", 512),
			MaxTurns:        getInt("AI_CHAT_MAX_TURNS", 100),
		},
		Seeder: SeederConfig{
			DefaultPassword: getString("SEED_DEFAULT_PASSWORD", "Sanctuary123!"),
		},
	}

	if err := cfg.validate(); err != nil {
		return nil, err
	}

	if err := apptime.Init(cfg.App.Timezone); err != nil {
		return nil, fmt.Errorf("invalid APP_TIMEZONE: %w", err)
	}
	utils.ConfigurePagination(cfg.Pagination.DefaultPerPage, cfg.Pagination.MaxPerPage)
	utils.ConfigureKAnonymity(cfg.Privacy.KAnonymityMinGroup)
	utils.ConfigureDBTimeout(cfg.Database.QueryTimeout)

	return cfg, nil
}

func (c *Config) validate() error {
	if c.Database.DSN == "" {
		return fmt.Errorf("DB_DSN is required")
	}
	if len(c.Security.JWTSecret) < 32 {
		return fmt.Errorf("JWT_SECRET must be at least 32 characters")
	}
	if c.App.IsProduction() {
		if !c.Security.CookieSecure {
			return fmt.Errorf("COOKIE_SECURE must be true in production")
		}
		if c.Database.AutoMigrate {
			return fmt.Errorf("DB_AUTO_MIGRATE must be false in production (use Atlas migrations)")
		}
		if c.Database.AutoSeed {
			return fmt.Errorf("DB_AUTO_SEED must be false in production")
		}
	}
	if c.Privacy.KAnonymityMinGroup < 5 {
		// Ambang privasi tidak boleh diturunkan di bawah standar dokumen Sanctuary.
		return fmt.Errorf("K_ANONYMITY_MIN_GROUP must be >= 5")
	}
	if c.Student.CheckinMaxBackdateDays < 0 {
		return fmt.Errorf("STUDENT_CHECKIN_MAX_BACKDATE_DAYS must be >= 0")
	}
	if c.Student.JournalMaxBackdateDays < 0 {
		return fmt.Errorf("STUDENT_JOURNAL_MAX_BACKDATE_DAYS must be >= 0")
	}
	if c.Student.MoodStatsMaxPeriod < c.Student.MoodStatsDefaultPeriod {
		return fmt.Errorf("STUDENT_MOOD_STATS_MAX_DAYS must be >= STUDENT_MOOD_STATS_DEFAULT_DAYS")
	}
	if c.AI.MaxTurns < 1 {
		return fmt.Errorf("AI_CHAT_MAX_TURNS must be >= 1")
	}
	if c.AI.Enabled() && c.AI.RequestTimeout <= 0 {
		return fmt.Errorf("GEMINI_TIMEOUT_SECONDS must be > 0 when GEMINI_API_KEY is set")
	}
	return nil
}

// MustLoad dipakai pada entry point (cmd/*) — gagal cepat bila config salah.
func MustLoad() *Config {
	cfg, err := Load()
	if err != nil {
		log.Fatalf("config error: %v", err)
	}
	return cfg
}

func getString(key, def string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return def
}

func getInt(key string, def int) int {
	if v, err := strconv.Atoi(getString(key, "")); err == nil {
		return v
	}
	return def
}

func getFloat(key string, def float64) float64 {
	if v, err := strconv.ParseFloat(getString(key, ""), 64); err == nil {
		return v
	}
	return def
}

func getBool(key string, def bool) bool {
	if v, err := strconv.ParseBool(getString(key, "")); err == nil {
		return v
	}
	return def
}

func getStringSlice(key string, def []string) []string {
	raw := getString(key, "")
	if raw == "" {
		return def
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if trimmed := strings.TrimSpace(p); trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}
