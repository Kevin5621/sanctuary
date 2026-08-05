package usecase

import (
	"context"
	"testing"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

func answersAll(value int) []int {
	answers := make([]int, service.DassQuestionCount)
	for i := range answers {
		answers[i] = value
	}
	return answers
}

func TestQuestionnaire_ShipsCatalogWithDisclaimer(t *testing.T) {
	uc := NewDassUsecase(&fakeDassRepo{})

	questionnaire := uc.Questionnaire(context.Background())

	if len(questionnaire.Questions) != service.DassQuestionCount {
		t.Fatalf("jumlah soal = %d, want %d",
			len(questionnaire.Questions), service.DassQuestionCount)
	}
	if len(questionnaire.Options) != 4 {
		t.Fatalf("jumlah pilihan jawaban = %d, want 4", len(questionnaire.Options))
	}
	// Instrumen skrining tanpa disclaimer mudah dibaca sebagai diagnosis.
	if questionnaire.Disclaimer == "" || questionnaire.Instruction == "" {
		t.Fatal("instruksi dan disclaimer wajib ikut terkirim")
	}
	if questionnaire.Questions[0].SubscaleLabel == "" {
		t.Error("subskala harus punya label agar klien tidak memetakan sendiri")
	}
}

func TestSubmit_RejectsIncompleteAnswers(t *testing.T) {
	uc := NewDassUsecase(&fakeDassRepo{})

	_, err := uc.Submit(context.Background(), "student-1", dto.SubmitDassRequest{
		Answers: []int{0, 1, 2},
	})

	if errorCode(err) != utils.CodeValidationError {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeValidationError)
	}
}

func TestSubmit_RejectsOutOfRangeAnswer(t *testing.T) {
	uc := NewDassUsecase(&fakeDassRepo{})

	answers := answersAll(0)
	answers[5] = 7

	_, err := uc.Submit(context.Background(), "student-1", dto.SubmitDassRequest{Answers: answers})
	if err == nil {
		t.Fatal("nilai di luar 0..3 harus ditolak")
	}
}

// Severity dihitung server, bukan dikirim klien — supaya versi aplikasi lama
// tidak dapat menyimpan kategori dengan ambang yang sudah berubah.
func TestSubmit_StoresServerComputedSeverity(t *testing.T) {
	repo := &fakeDassRepo{}
	uc := NewDassUsecase(repo)

	result, err := uc.Submit(context.Background(), "student-1", dto.SubmitDassRequest{
		Answers: answersAll(3), // maksimum di semua item
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(repo.created) != 1 {
		t.Fatalf("jumlah tersimpan = %d, want 1", len(repo.created))
	}
	saved := repo.created[0]
	if saved.DepressionSeverity != constants.DassExtremelySevere {
		t.Fatalf("severity tersimpan = %s, want EXTREMELY_SEVERE", saved.DepressionSeverity)
	}
	if !result.HasSevere {
		t.Error("hasil maksimum harus menandai HasSevere")
	}
	if result.Disclaimer == "" {
		t.Error("disclaimer harus ikut pada hasil")
	}
	if len(result.CopingSuggestions) == 0 {
		t.Error("hasil harus disertai saran tindak lanjut")
	}
}

func TestSubmit_AllZeroIsNormal(t *testing.T) {
	uc := NewDassUsecase(&fakeDassRepo{})

	result, err := uc.Submit(context.Background(), "student-1", dto.SubmitDassRequest{
		Answers: answersAll(0),
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result.TotalScore != 0 || result.HasSevere {
		t.Fatalf("skor nol seharusnya normal, dapat total=%d severe=%v",
			result.TotalScore, result.HasSevere)
	}
}

func TestHistory_EmptyStateHasNoLatest(t *testing.T) {
	uc := NewDassUsecase(&fakeDassRepo{})

	history, err := uc.History(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if history.Latest != nil {
		t.Fatal("belum ada hasil, Latest harus nil")
	}
	if history.TotalDelta != nil {
		t.Fatal("tanpa data tidak ada perbandingan")
	}
	if history.ChangeLabel == "" {
		t.Error("state kosong tetap perlu penjelasan")
	}
}

func TestHistory_ComparesTwoLatestResults(t *testing.T) {
	// Repository mengembalikan terbaru lebih dulu.
	repo := &fakeDassRepo{listing: []models.Dass21Result{
		{
			DepressionScore: 20, AnxietyScore: 18, StressScore: 22,
			DepressionSeverity: constants.DassModerate,
			AnxietySeverity:    constants.DassSevere,
			StressSeverity:     constants.DassModerate,
			TakenAt:            apptime.DaysAgo(1),
		},
		{
			DepressionScore: 10, AnxietyScore: 8, StressScore: 15,
			DepressionSeverity: constants.DassMild,
			AnxietySeverity:    constants.DassMild,
			StressSeverity:     constants.DassMild,
			TakenAt:            apptime.DaysAgo(30),
		},
	}}
	uc := NewDassUsecase(repo)

	history, err := uc.History(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if history.Latest == nil {
		t.Fatal("Latest harus terisi")
	}
	if history.TotalDelta == nil || *history.TotalDelta != 27 {
		t.Fatalf("delta = %v, want 27", history.TotalDelta)
	}
	if history.ChangeLabel == "" {
		t.Error("perubahan skor harus dijelaskan dalam kalimat")
	}

	// Tren dibalik agar klien menggambar dari kiri (lama) ke kanan (baru).
	if len(history.Trend) != 2 {
		t.Fatalf("jumlah titik tren = %d, want 2", len(history.Trend))
	}
	if history.Trend[0].TakenDate != apptime.FormatDate(apptime.DaysAgo(30)) {
		t.Fatalf("titik pertama = %s, want yang paling lama", history.Trend[0].TakenDate)
	}
}

func TestHistory_SingleResultHasNoDelta(t *testing.T) {
	repo := &fakeDassRepo{listing: []models.Dass21Result{{
		DepressionScore: 4, AnxietyScore: 4, StressScore: 4,
		DepressionSeverity: constants.DassNormal,
		AnxietySeverity:    constants.DassNormal,
		StressSeverity:     constants.DassNormal,
		TakenAt:            apptime.DaysAgo(2),
	}}}
	uc := NewDassUsecase(repo)

	history, err := uc.History(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if history.TotalDelta != nil {
		t.Fatal("satu hasil tidak punya pembanding")
	}
	if history.Count != 1 {
		t.Fatalf("count = %d, want 1", history.Count)
	}
}
