package usecase

import (
	"context"
	"testing"
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

func newJournalUC(repo *fakeJournalRepo) JournalUsecase {
	// Nilai yang sama dengan default config, agar batas D-8 (7 hari) yang
	// diuji di sini benar-benar batas yang dipakai aplikasi.
	return NewJournalUsecase(repo, service.NewEmotionAnalyzer(), config.StudentConfig{
		CheckinMaxBackdateDays: 30,
		JournalMaxBackdateDays: 7,
		MoodStatsDefaultPeriod: 30,
		MoodStatsMaxPeriod:     365,
	})
}

// analyzedJournal membangun jurnal yang sudah punya hasil analisis.
func analyzedJournal(id string, daysAgo int, emotion string, sentiment float64, crisis bool) models.StudentJournal {
	analyzedAt := apptime.DaysAgo(daysAgo).Add(20 * time.Hour)
	confidence := 0.8

	journal := models.StudentJournal{
		Content:           "Catatan uji untuk " + emotion,
		JournalDate:       apptime.DaysAgo(daysAgo),
		EmotionLabel:      emotion,
		EmotionConfidence: &confidence,
		SentimentScore:    &sentiment,
		IsCrisisFlagged:   crisis,
		AnalyzedAt:        &analyzedAt,
	}
	journal.ID = id
	return journal
}

func TestCreateJournal_RejectsFutureDate(t *testing.T) {
	uc := newJournalUC(&fakeJournalRepo{})

	_, _, err := uc.Create(context.Background(), "student-1", dto.CreateJournalRequest{
		Content:     "Catatan hari ini.",
		JournalDate: apptime.FormatDate(apptime.Today().AddDate(0, 0, 1)),
	})

	if errorCode(err) != utils.CodeFutureDateNotAllowed {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeFutureDateNotAllowed)
	}
}

func TestCreateJournal_AnalyzeNowReturnsAnalysis(t *testing.T) {
	repo := &fakeJournalRepo{}
	uc := newJournalUC(repo)

	_, analysis, err := uc.Create(context.Background(), "student-1", dto.CreateJournalRequest{
		Content:    "Aku cemas dan khawatir menghadapi ujian besok, sulit tidur.",
		AnalyzeNow: true,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if analysis == nil {
		t.Fatal("analisis harus dikembalikan saat analyze_now")
	}
	if analysis.EmotionLabel != constants.EmotionAnxious {
		t.Fatalf("label = %s, want ANXIOUS", analysis.EmotionLabel)
	}
	if len(analysis.CopingSuggestions) == 0 {
		t.Error("hasil analisis harus disertai saran coping")
	}
	if analysis.ModelVersion == "" {
		t.Error("versi model wajib dikirim demi transparansi")
	}
}

// Deteksi krisis harus menang atas label emosi apa pun, dan wajib membawa
// pesan yang mengarahkan ke bantuan.
func TestCreateJournal_CrisisPhraseIsFlagged(t *testing.T) {
	uc := newJournalUC(&fakeJournalRepo{})

	_, analysis, err := uc.Create(context.Background(), "student-1", dto.CreateJournalRequest{
		Content:    "Aku merasa tidak ingin hidup lagi, semuanya terasa berat.",
		AnalyzeNow: true,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !analysis.IsCrisisFlagged {
		t.Fatal("frasa krisis harus terdeteksi")
	}
	if analysis.CrisisMessage == "" {
		t.Fatal("penandaan krisis tanpa pesan bantuan tidak berguna")
	}
}

func TestCreateJournal_WithoutAnalyzeStoresPlainEntry(t *testing.T) {
	repo := &fakeJournalRepo{}
	uc := newJournalUC(repo)

	journal, analysis, err := uc.Create(context.Background(), "student-1", dto.CreateJournalRequest{
		Content: "Hanya ingin menulis, belum ingin dianalisis.",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if analysis != nil {
		t.Fatal("analisis tidak boleh berjalan tanpa diminta")
	}
	if journal.EmotionLabel != "" {
		t.Fatalf("label emosi = %q, want kosong", journal.EmotionLabel)
	}
	if len(repo.analyzed) != 0 {
		t.Error("tidak boleh ada penyimpanan hasil analisis")
	}
}

func TestEmotionHistory_EmptyStateGuidesUser(t *testing.T) {
	uc := newJournalUC(&fakeJournalRepo{})

	history, err := uc.EmotionHistory(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if history.TotalAnalyzed != 0 {
		t.Fatalf("total = %d, want 0", history.TotalAnalyzed)
	}
	if history.Message == "" {
		t.Error("state kosong harus memberi tahu cara mengisinya")
	}
	if history.IsSufficient {
		t.Error("tanpa data tidak boleh dinyatakan cukup")
	}
}

func TestEmotionHistory_BuildsDistributionAndTrend(t *testing.T) {
	repo := &fakeJournalRepo{stored: []models.StudentJournal{
		analyzedJournal("j1", 1, constants.EmotionAnxious, -0.7, false),
		analyzedJournal("j2", 3, constants.EmotionAnxious, -0.6, false),
		analyzedJournal("j3", 6, constants.EmotionCalm, 0.6, false),
	}}
	uc := newJournalUC(repo)

	history, err := uc.EmotionHistory(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if history.TotalAnalyzed != 3 || !history.IsSufficient {
		t.Fatalf("total=%d cukup=%v, want 3 & true", history.TotalAnalyzed, history.IsSufficient)
	}
	if history.DominantEmotion != constants.EmotionAnxious {
		t.Fatalf("emosi dominan = %s, want ANXIOUS", history.DominantEmotion)
	}
	if history.DominantEmotionText == "" {
		t.Error("emosi dominan harus punya teks bahasa Indonesia")
	}

	// Dua dari tiga bernada negatif.
	if history.NegativeRatio < 0.66 || history.NegativeRatio > 0.67 {
		t.Fatalf("rasio negatif = %v, want ~0.667", history.NegativeRatio)
	}

	// Tren dibalik menjadi lama → baru agar klien menggambar apa adanya.
	if len(history.Trend) != 3 {
		t.Fatalf("jumlah titik tren = %d, want 3", len(history.Trend))
	}
	if history.Trend[0].Date != apptime.FormatDate(apptime.DaysAgo(6)) {
		t.Fatalf("titik pertama = %s, want yang paling lama", history.Trend[0].Date)
	}
}

func TestEmotionHistory_CountsCrisisFlags(t *testing.T) {
	repo := &fakeJournalRepo{stored: []models.StudentJournal{
		analyzedJournal("j1", 1, constants.EmotionSad, -0.95, true),
		analyzedJournal("j2", 2, constants.EmotionCalm, 0.5, false),
	}}
	uc := newJournalUC(repo)

	history, err := uc.EmotionHistory(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if history.CrisisFlaggedCount != 1 {
		t.Fatalf("jumlah penanda krisis = %d, want 1", history.CrisisFlaggedCount)
	}
	// Dua hasil belum membentuk pola; menyebutnya tren melebih-lebihkan.
	if history.IsSufficient {
		t.Error("dua hasil belum cukup untuk dinyatakan sebagai pola")
	}
}

func TestEmotionHistory_ItemsCarryCopingSuggestions(t *testing.T) {
	repo := &fakeJournalRepo{stored: []models.StudentJournal{
		analyzedJournal("j1", 1, constants.EmotionAnxious, -0.7, false),
	}}
	uc := newJournalUC(repo)

	history, err := uc.EmotionHistory(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(history.Items) != 1 {
		t.Fatalf("jumlah item = %d, want 1", len(history.Items))
	}
	if len(history.Items[0].CopingSuggestions) == 0 {
		t.Error("saran coping di riwayat harus sama tersedianya dengan saat analisis")
	}
	if history.Items[0].Preview == "" {
		t.Error("preview singkat diperlukan agar pemilik mengenali catatannya")
	}
}
