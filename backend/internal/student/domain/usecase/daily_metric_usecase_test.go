package usecase

import (
	"context"
	"errors"
	"testing"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

func testStudentConfig() config.StudentConfig {
	return config.StudentConfig{
		CheckinMaxBackdateDays: 30,
		JournalMaxBackdateDays: 7,
		MoodStatsDefaultPeriod: 30,
		MoodStatsMaxPeriod:     365,
	}
}

func validCheckin() dto.SaveDailyMetricRequest {
	return dto.SaveDailyMetricRequest{
		MoodScore:       4,
		StressLevel:     2,
		SleepHours:      7.5,
		AcademicTrigger: "Tugas kuliah",
	}
}

// errorCode mengambil kode error domain dari error apa pun.
func errorCode(err error) string {
	var appErr *utils.AppError
	if errors.As(err, &appErr) {
		return appErr.Code
	}
	return ""
}

func TestSaveMetric_DefaultsToToday(t *testing.T) {
	repo := &fakeMetricRepo{}
	uc := NewDailyMetricUsecase(repo, testStudentConfig())

	result, err := uc.SaveMetric(context.Background(), "student-1", validCheckin())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result.Date != apptime.FormatDate(apptime.Today()) {
		t.Fatalf("tanggal = %s, want hari ini", result.Date)
	}
	if len(repo.saved) != 1 {
		t.Fatalf("jumlah tersimpan = %d, want 1", len(repo.saved))
	}
}

// Batas mundur check-in adalah 30 hari — inilah yang membuat kalender tab Mood
// bisa diketuk untuk menutup celah sebulan ke belakang. Batasnya terpisah dari
// jurnal (D-8, 7 hari), jadi keduanya diuji terhadap config-nya masing-masing.
func TestSaveMetric_AcceptsBackdateWithinThirtyDays(t *testing.T) {
	repo := &fakeMetricRepo{}
	uc := NewDailyMetricUsecase(repo, testStudentConfig())

	req := validCheckin()
	req.MetricDate = apptime.FormatDate(apptime.DaysAgo(30))

	result, err := uc.SaveMetric(context.Background(), "student-1", req)
	if err != nil {
		t.Fatalf("tanggal 30 hari lalu masih di dalam batas: %v", err)
	}
	if result.Date != req.MetricDate {
		t.Fatalf("tanggal tersimpan = %s, want %s", result.Date, req.MetricDate)
	}
}

func TestSaveMetric_RejectsBackdateBeyondThirtyDays(t *testing.T) {
	uc := NewDailyMetricUsecase(&fakeMetricRepo{}, testStudentConfig())

	req := validCheckin()
	req.MetricDate = apptime.FormatDate(apptime.DaysAgo(31))

	_, err := uc.SaveMetric(context.Background(), "student-1", req)
	if errorCode(err) != utils.CodeBackdateLimitExceeded {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeBackdateLimitExceeded)
	}
}

// Check-in tidak lagi punya label emosi: satu pertanyaan tentang perasaan sudah
// diwakili skala mood, dan emosi bernama hanya lahir dari analisis jurnal (D-3).
func TestSaveMetric_StoresNoEmotionLabel(t *testing.T) {
	repo := &fakeMetricRepo{}
	uc := NewDailyMetricUsecase(repo, testStudentConfig())

	if _, err := uc.SaveMetric(context.Background(), "student-1", validCheckin()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(repo.saved) != 1 {
		t.Fatalf("jumlah tersimpan = %d, want 1", len(repo.saved))
	}
	if label := repo.saved[0].EmotionLabel; label != "" {
		t.Fatalf("emotion_label = %q, want kosong", label)
	}
}

func TestSaveMetric_IncludesHumanReadableLabels(t *testing.T) {
	uc := NewDailyMetricUsecase(&fakeMetricRepo{}, testStudentConfig())

	result, err := uc.SaveMetric(context.Background(), "student-1", validCheckin())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Klien tidak boleh perlu menyimpan tabel arti angka sendiri.
	if result.MoodLabel == "" || result.StressLabel == "" {
		t.Fatalf("label kosong: mood=%q stres=%q", result.MoodLabel, result.StressLabel)
	}
}

func TestSaveMetric_AllowsEmptyOptionalFields(t *testing.T) {
	uc := NewDailyMetricUsecase(&fakeMetricRepo{}, testStudentConfig())

	req := validCheckin()
	req.AcademicTrigger = ""

	if _, err := uc.SaveMetric(context.Background(), "student-1", req); err != nil {
		t.Fatalf("pemicu bersifat opsional, dapat: %v", err)
	}
}

func TestWeeklySummary_MarksTodayAndCountsStreak(t *testing.T) {
	repo := &fakeMetricRepo{listing: []models.StudentDailyMetric{
		{MetricDate: apptime.DaysAgo(2), MoodScore: 4, StressLevel: 2, SleepHours: 7},
		{MetricDate: apptime.DaysAgo(1), MoodScore: 4, StressLevel: 2, SleepHours: 7},
		{MetricDate: apptime.Today(), MoodScore: 5, StressLevel: 1, SleepHours: 8},
	}}
	uc := NewDailyMetricUsecase(repo, testStudentConfig())

	summary, err := uc.WeeklySummary(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if summary.Today == nil {
		t.Fatal("check-in hari ini harus terdeteksi")
	}
	if summary.CurrentStreak != 3 {
		t.Fatalf("streak = %d, want 3", summary.CurrentStreak)
	}
}

func TestWeeklySummary_TodayNilWhenNotCheckedIn(t *testing.T) {
	repo := &fakeMetricRepo{listing: []models.StudentDailyMetric{
		{MetricDate: apptime.DaysAgo(1), MoodScore: 4, StressLevel: 2, SleepHours: 7},
	}}
	uc := NewDailyMetricUsecase(repo, testStudentConfig())

	summary, err := uc.WeeklySummary(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if summary.Today != nil {
		t.Fatal("hari ini belum diisi, Today harus nil")
	}
}

// Statistik dari satu-dua titik lebih menyesatkan daripada informatif —
// aturan yang sama dipakai EWS dan k-anonymity.
func TestStats_InsufficientDataHidesAverages(t *testing.T) {
	repo := &fakeMetricRepo{listing: []models.StudentDailyMetric{
		{MetricDate: apptime.DaysAgo(1), MoodScore: 1, StressLevel: 5, SleepHours: 3},
	}}
	uc := NewDailyMetricUsecase(repo, testStudentConfig())

	stats, err := uc.Stats(context.Background(), "student-1", 30)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if stats.IsSufficient {
		t.Fatal("satu titik tidak boleh dianggap cukup")
	}
	if stats.AvgMood != 0 {
		t.Fatalf("rata-rata tidak boleh keluar saat data belum cukup, dapat %v", stats.AvgMood)
	}
	if stats.Message == "" {
		t.Error("state 'belum cukup' harus menjelaskan sebabnya")
	}
	if len(stats.Points) != 1 {
		t.Errorf("titik mentah tetap dikirim untuk konteks, dapat %d", len(stats.Points))
	}
}

func TestStats_BuildsTriggers(t *testing.T) {
	repo := &fakeMetricRepo{listing: []models.StudentDailyMetric{
		{MetricDate: apptime.DaysAgo(3), MoodScore: 2, StressLevel: 4, SleepHours: 5,
			AcademicTrigger: "Skripsi / tugas akhir"},
		{MetricDate: apptime.DaysAgo(2), MoodScore: 2, StressLevel: 4, SleepHours: 5,
			AcademicTrigger: "Skripsi / tugas akhir"},
		{MetricDate: apptime.DaysAgo(1), MoodScore: 4, StressLevel: 2, SleepHours: 8,
			AcademicTrigger: "Ujian (UTS/UAS)"},
	}}
	uc := NewDailyMetricUsecase(repo, testStudentConfig())

	stats, err := uc.Stats(context.Background(), "student-1", 30)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !stats.IsSufficient {
		t.Fatal("tiga titik sudah cukup untuk menampilkan pola")
	}
	if len(stats.TopTriggers) == 0 || stats.TopTriggers[0].Trigger != "Skripsi / tugas akhir" {
		t.Fatalf("pemicu teratas = %+v, want Skripsi / tugas akhir", stats.TopTriggers)
	}
}

func TestStats_ClampsPeriodToConfiguredMaximum(t *testing.T) {
	uc := NewDailyMetricUsecase(&fakeMetricRepo{}, testStudentConfig())

	stats, err := uc.Stats(context.Background(), "student-1", 9999)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if stats.PeriodDays != 365 {
		t.Fatalf("periode = %d, want dibatasi ke 365", stats.PeriodDays)
	}
}

func TestMonthly_RejectsFutureMonth(t *testing.T) {
	uc := NewDailyMetricUsecase(&fakeMetricRepo{}, testStudentConfig())

	next := apptime.StartOfMonth(apptime.Today()).AddDate(0, 1, 0)

	_, err := uc.Monthly(context.Background(), "student-1", apptime.FormatMonth(next))
	if errorCode(err) != utils.CodeFutureDateNotAllowed {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeFutureDateNotAllowed)
	}
}

func TestMonthly_RejectsMalformedMonth(t *testing.T) {
	uc := NewDailyMetricUsecase(&fakeMetricRepo{}, testStudentConfig())

	_, err := uc.Monthly(context.Background(), "student-1", "Agustus")
	if errorCode(err) != utils.CodeInvalidQueryParam {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeInvalidQueryParam)
	}
}

func TestMonthly_DefaultsToCurrentMonth(t *testing.T) {
	repo := &fakeMetricRepo{listing: []models.StudentDailyMetric{
		{MetricDate: apptime.Today(), MoodScore: 4, StressLevel: 2, SleepHours: 7},
	}}
	uc := NewDailyMetricUsecase(repo, testStudentConfig())

	month, err := uc.Monthly(context.Background(), "student-1", "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if month.Month != apptime.FormatMonth(apptime.Today()) {
		t.Fatalf("bulan = %s, want bulan berjalan", month.Month)
	}
	if month.MonthLabel == "" {
		t.Error("label bulan harus terisi (dipakai judul kalender)")
	}
	if month.HasNextMonth {
		t.Error("bulan berjalan tidak boleh menawarkan navigasi ke depan")
	}
}

func TestOptions_ExposesEveryChoiceAndBackdateLimit(t *testing.T) {
	uc := NewDailyMetricUsecase(&fakeMetricRepo{}, testStudentConfig())

	options := uc.Options(context.Background())

	if len(options.MoodScale) != 5 || len(options.StressScale) != 5 {
		t.Fatalf("skala tidak lengkap: mood=%d stres=%d",
			len(options.MoodScale), len(options.StressScale))
	}
	// Batas check-in terpisah dari batas jurnal; klien memakai angka ini untuk
	// menentukan tanggal mana pada kalender yang boleh diketuk.
	if options.MaxBackdateDays != 30 {
		t.Fatalf("batas backdate = %d, want 30", options.MaxBackdateDays)
	}
}
