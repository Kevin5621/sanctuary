package usecase

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"strings"
	"testing"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

// ------------------------------------------------------------------
// Helper
// ------------------------------------------------------------------

func apptimeDaysAgoString(days int) string {
	return apptime.DaysAgo(days).Format(apptime.LayoutDate)
}

func mustJSON(t *testing.T, v any) string {
	t.Helper()

	encoded, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("gagal marshal: %v", err)
	}
	return string(encoded)
}

func contains(haystack, needle string) bool {
	return strings.Contains(strings.ToLower(haystack), strings.ToLower(needle))
}

// assertNoTextFields memastikan tipe respons tidak memiliki field yang membawa
// tulisan mahasiswa. Pemeriksaan pada TIPE (bukan hanya nilai) membuat field
// teks yang ditambahkan kelak langsung ketahuan, walau kebetulan bernilai
// kosong saat test berjalan.
func assertNoTextFields(t *testing.T, v any) {
	t.Helper()

	forbidden := []string{"content", "preview", "title", "journal_text", "excerpt"}
	typ := reflect.TypeOf(v)
	for i := 0; i < typ.NumField(); i++ {
		tag := typ.Field(i).Tag.Get("json")
		for _, fragment := range forbidden {
			if strings.Contains(strings.ToLower(tag), fragment) {
				t.Errorf("%s memiliki field %q — sebaran emosi hanya boleh membawa angka",
					typ.Name(), tag)
			}
		}
	}
}

// ------------------------------------------------------------------
// Sebaran Emosi (M-MOOD-04)
// ------------------------------------------------------------------

func TestEmotionDistribution_EmptyStateIsHonest(t *testing.T) {
	uc := newJournalUC(&fakeJournalRepo{})

	result, err := uc.EmotionDistribution(context.Background(), "student-1", 30)
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}

	if !result.IsEmpty {
		t.Error("tanpa jurnal dianalisis, is_empty harus true agar klien tidak menggambar grafik kosong")
	}
	if result.Message == "" {
		t.Error("empty state wajib punya penjelasan jujur, bukan grafik nol")
	}
	if len(result.Distribution) != 0 {
		t.Errorf("distribution harus kosong, dapat %d irisan", len(result.Distribution))
	}
	if result.TotalAnalyzed != 0 {
		t.Errorf("total_analyzed = %d, harusnya 0", result.TotalAnalyzed)
	}
}

// TestEmotionDistribution_IgnoresUnanalyzedJournals: jurnal yang ditulis tapi
// belum ditekan "Analisis Emosi" tidak boleh ikut menghitung.
func TestEmotionDistribution_IgnoresUnanalyzedJournals(t *testing.T) {
	repo := &fakeJournalRepo{stored: []models.StudentJournal{
		analyzedJournal("j1", 2, constants.EmotionSad, -0.6, false),
		// Belum dianalisis: AnalyzedAt nil, tanpa label.
		{Content: "belum dianalisis"},
	}}
	uc := newJournalUC(repo)

	result, err := uc.EmotionDistribution(context.Background(), "student-1", 30)
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}

	if result.TotalAnalyzed != 1 {
		t.Errorf("total_analyzed = %d, harusnya 1 — hanya jurnal yang sudah dianalisis yang dihitung",
			result.TotalAnalyzed)
	}
}

// TestEmotionDistribution_RespectsRangeWindow menjaga agar rentang benar-benar
// menyaring, bukan sekadar dipajang di response.
func TestEmotionDistribution_RespectsRangeWindow(t *testing.T) {
	repo := &fakeJournalRepo{stored: []models.StudentJournal{
		analyzedJournal("recent", 3, constants.EmotionAnxious, -0.7, false),
		analyzedJournal("old", 60, constants.EmotionJoy, 0.8, false),
	}}
	uc := newJournalUC(repo)

	result, err := uc.EmotionDistribution(context.Background(), "student-1", 30)
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}

	if result.TotalAnalyzed != 1 {
		t.Fatalf("total_analyzed = %d, harusnya 1 (jurnal 60 hari lalu di luar rentang 30 hari)",
			result.TotalAnalyzed)
	}
	if result.DominantEmotion != constants.EmotionAnxious {
		t.Errorf("dominant = %q, harusnya ANXIOUS", result.DominantEmotion)
	}
	if result.PeriodDays != 30 {
		t.Errorf("period_days = %d, harusnya 30", result.PeriodDays)
	}
}

func TestEmotionDistribution_PercentagesAndNegativeRatio(t *testing.T) {
	repo := &fakeJournalRepo{stored: []models.StudentJournal{
		analyzedJournal("j1", 1, constants.EmotionSad, -0.6, false),
		analyzedJournal("j2", 2, constants.EmotionSad, -0.6, false),
		analyzedJournal("j3", 3, constants.EmotionAnxious, -0.7, false),
		analyzedJournal("j4", 4, constants.EmotionJoy, 0.8, false),
	}}
	uc := newJournalUC(repo)

	result, err := uc.EmotionDistribution(context.Background(), "student-1", 30)
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}

	if result.TotalAnalyzed != 4 {
		t.Fatalf("total_analyzed = %d, harusnya 4", result.TotalAnalyzed)
	}
	// SAD 2, ANXIOUS 1, JOY 1 -> 3 dari 4 negatif = 0.75
	if result.NegativeRatio != 0.75 {
		t.Errorf("negative_ratio = %v, harusnya 0.75", result.NegativeRatio)
	}
	if result.DominantEmotion != constants.EmotionSad {
		t.Errorf("dominant = %q, harusnya SAD", result.DominantEmotion)
	}

	// Irisan terbanyak harus di depan, dan persentase harus berjumlah 100.
	if result.Distribution[0].Emotion != constants.EmotionSad {
		t.Errorf("irisan pertama = %q, harusnya SAD (terbanyak)", result.Distribution[0].Emotion)
	}
	total := 0.0
	for _, share := range result.Distribution {
		total += share.Percentage
	}
	if total < 99.9 || total > 100.1 {
		t.Errorf("jumlah persentase = %v, harusnya ~100", total)
	}
}

// TestEmotionDistributionMatchesEmotionHistory adalah inti keputusan "satu
// perhitungan, dua layar": tab Mood dan tab Profil tidak boleh menyebutkan
// angka berbeda untuk data yang sama.
func TestEmotionDistributionMatchesEmotionHistory(t *testing.T) {
	stored := []models.StudentJournal{
		analyzedJournal("j1", 1, constants.EmotionSad, -0.6, false),
		analyzedJournal("j2", 2, constants.EmotionSad, -0.6, false),
		analyzedJournal("j3", 3, constants.EmotionAnxious, -0.7, false),
		analyzedJournal("j4", 4, constants.EmotionJoy, 0.8, false),
	}
	uc := newJournalUC(&fakeJournalRepo{stored: stored})

	distribution, err := uc.EmotionDistribution(context.Background(), "student-1", 30)
	if err != nil {
		t.Fatalf("distribution: %v", err)
	}
	history, err := uc.EmotionHistory(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("history: %v", err)
	}

	if len(distribution.Distribution) != len(history.Distribution) {
		t.Fatalf("jumlah irisan berbeda: mood=%d profil=%d",
			len(distribution.Distribution), len(history.Distribution))
	}
	for i := range distribution.Distribution {
		mood, profile := distribution.Distribution[i], history.Distribution[i]
		if mood.Emotion != profile.Emotion || mood.Count != profile.Count || mood.Percentage != profile.Percentage {
			t.Errorf("irisan ke-%d berbeda antar layar: mood=%+v profil=%+v", i, mood, profile)
		}
	}
	if distribution.NegativeRatio != history.NegativeRatio {
		t.Errorf("negative_ratio berbeda: mood=%v profil=%v",
			distribution.NegativeRatio, history.NegativeRatio)
	}
}

// TestEmotionDistributionCarriesNoJournalText mengunci alasan privasi endpoint
// ini dipisah dari riwayat: grafik hanya butuh angka.
func TestEmotionDistributionCarriesNoJournalText(t *testing.T) {
	const secret = "ini isi jurnal yang sangat pribadi"
	journal := analyzedJournal("j1", 1, constants.EmotionSad, -0.6, false)
	journal.Content = secret
	journal.Title = secret

	uc := newJournalUC(&fakeJournalRepo{stored: []models.StudentJournal{journal}})

	result, err := uc.EmotionDistribution(context.Background(), "student-1", 30)
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}

	encoded := mustJSON(t, result)
	if contains(encoded, secret) {
		t.Errorf("respons sebaran emosi membocorkan teks jurnal: %s", encoded)
	}
	// Sanity check: pastikan tipe respons memang tidak punya field teks.
	assertNoTextFields(t, result)
}

func TestEmotionDistribution_ClampsExcessiveRange(t *testing.T) {
	uc := newJournalUC(&fakeJournalRepo{})

	// 9999 hari jauh melebihi MoodStatsMaxPeriod (365).
	result, err := uc.EmotionDistribution(context.Background(), "student-1", 9999)
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}
	if result.PeriodDays != 365 {
		t.Errorf("period_days = %d, harusnya dibatasi ke 365", result.PeriodDays)
	}
}

func TestEmotionDistribution_DefaultsWhenRangeOmitted(t *testing.T) {
	uc := newJournalUC(&fakeJournalRepo{})

	result, err := uc.EmotionDistribution(context.Background(), "student-1", 0)
	if err != nil {
		t.Fatalf("tidak boleh error: %v", err)
	}
	if result.PeriodDays != 30 {
		t.Errorf("period_days = %d, harusnya default 30", result.PeriodDays)
	}
}

// ------------------------------------------------------------------
// D-8 — batas backdate jurnal
// ------------------------------------------------------------------

// TestCreateJournal_RejectsBackdateBeyondLimit menutup celah D-8 pada jurnal.
// Sebelum perbaikan ini, hanya check-in mood yang dibatasi, sementara jurnal
// dapat diberi tanggal mundur sejauh apa pun — padahal EWS #2 membaca jurnal,
// sehingga entri lama yang dikarang belakangan ikut menggeser indikator.
func TestCreateJournal_RejectsBackdateBeyondLimit(t *testing.T) {
	uc := newJournalUC(&fakeJournalRepo{})

	_, _, err := uc.Create(context.Background(), "student-1", dto.CreateJournalRequest{
		Content:     "Catatan yang ditulis untuk 10 hari lalu.",
		JournalDate: apptimeDaysAgoString(10),
	})

	var appErr *utils.AppError
	if !errors.As(err, &appErr) {
		t.Fatalf("harus ditolak dengan AppError, dapat %v", err)
	}
	if appErr.Code != utils.CodeBackdateLimitExceeded {
		t.Errorf("kode = %q, harusnya %q", appErr.Code, utils.CodeBackdateLimitExceeded)
	}
}

func TestCreateJournal_AcceptsBackdateWithinLimit(t *testing.T) {
	repo := &fakeJournalRepo{}
	uc := newJournalUC(repo)

	_, _, err := uc.Create(context.Background(), "student-1", dto.CreateJournalRequest{
		Content:     "Catatan tiga hari lalu.",
		JournalDate: apptimeDaysAgoString(3),
	})
	if err != nil {
		t.Fatalf("backdate 3 hari (di dalam batas 7) harus diterima: %v", err)
	}
	if len(repo.created) != 1 {
		t.Errorf("jurnal harus tersimpan, dapat %d", len(repo.created))
	}
}

// TestCreateJournal_AcceptsExactBackdateBoundary menjaga batas tepat di hari
// ke-7 tetap diterima (batasnya inklusif, sama seperti check-in mood).
func TestCreateJournal_AcceptsExactBackdateBoundary(t *testing.T) {
	repo := &fakeJournalRepo{}
	uc := newJournalUC(repo)

	_, _, err := uc.Create(context.Background(), "student-1", dto.CreateJournalRequest{
		Content:     "Tepat di batas tujuh hari.",
		JournalDate: apptimeDaysAgoString(7),
	})
	if err != nil {
		t.Fatalf("hari ke-7 harus masih diterima: %v", err)
	}
	if len(repo.created) != 1 {
		t.Errorf("jurnal harus tersimpan, dapat %d", len(repo.created))
	}
}
