package service

import (
	"testing"

	"github.com/gilabs/sanctuary/internal/core/constants"
)

// answersAll mengisi seluruh 21 item dengan nilai yang sama.
func answersAll(value int) []int {
	answers := make([]int, DassQuestionCount)
	for i := range answers {
		answers[i] = value
	}
	return answers
}

// answersFor mengisi item milik satu subskala saja, sisanya nol.
// Dipakai menguji bahwa pemetaan item ke subskala tidak tertukar.
func answersFor(sub DassSubscale, value int) []int {
	answers := make([]int, DassQuestionCount)
	for i, q := range DassQuestions() {
		if q.Subscale == sub {
			answers[i] = value
		}
	}
	return answers
}

func TestQuestionCatalog_HasSevenItemsPerSubscale(t *testing.T) {
	if len(DassQuestions()) != DassQuestionCount {
		t.Fatalf("jumlah soal = %d, want %d", len(DassQuestions()), DassQuestionCount)
	}

	counts := map[DassSubscale]int{}
	for _, q := range DassQuestions() {
		counts[q.Subscale]++
	}

	for _, sub := range []DassSubscale{SubscaleDepression, SubscaleAnxiety, SubscaleStress} {
		if counts[sub] != 7 {
			t.Errorf("subskala %s punya %d item, want 7", sub, counts[sub])
		}
	}
}

func TestScoreDass21_AllZeroIsNormal(t *testing.T) {
	score := ScoreDass21(answersAll(0))

	if score.TotalScore() != 0 {
		t.Fatalf("total = %d, want 0", score.TotalScore())
	}
	if score.HasSevere() {
		t.Fatal("skor nol tidak boleh dianggap severe")
	}
	if score.Depression.Severity != constants.DassNormal {
		t.Errorf("depresi = %s, want NORMAL", score.Depression.Severity)
	}
}

func TestScoreDass21_MultipliesRawScoreByTwo(t *testing.T) {
	// Tiap subskala 7 item bernilai 1 → raw 7, skor 14 (skala DASS-42).
	score := ScoreDass21(answersAll(1))

	if score.Depression.RawScore != 7 {
		t.Fatalf("raw depresi = %d, want 7", score.Depression.RawScore)
	}
	if score.Depression.Score != 14 {
		t.Fatalf("skor depresi = %d, want 14", score.Depression.Score)
	}
	if score.Depression.MaxScore != 42 {
		t.Fatalf("skor maks = %d, want 42", score.Depression.MaxScore)
	}
}

func TestScoreDass21_SubscalesAreIndependent(t *testing.T) {
	score := ScoreDass21(answersFor(SubscaleAnxiety, 3))

	if score.Anxiety.Score != 42 {
		t.Fatalf("skor kecemasan = %d, want 42", score.Anxiety.Score)
	}
	if score.Depression.Score != 0 || score.Stress.Score != 0 {
		t.Fatalf("subskala lain bocor: depresi=%d stres=%d",
			score.Depression.Score, score.Stress.Score)
	}
}

// Ambang tiap subskala berbeda — skor yang sama bisa berarti kategori berbeda.
// Kesalahan menyalin ambang antar subskala adalah bug yang sulit terlihat,
// jadi diuji per batas.
func TestScoreDass21_SeverityBands(t *testing.T) {
	tests := []struct {
		name     string
		subscale DassSubscale
		raw      int // per item x 7; dipakai lewat konstruksi manual di bawah
		want     constants.DassSeverity
	}{
		{"depresi 8 masih normal", SubscaleDepression, 4, constants.DassNormal},
		{"depresi 10 mulai ringan", SubscaleDepression, 5, constants.DassMild},
		{"depresi 14 sedang", SubscaleDepression, 7, constants.DassModerate},
		{"depresi 22 parah", SubscaleDepression, 11, constants.DassSevere},
		{"depresi 28 sangat parah", SubscaleDepression, 14, constants.DassExtremelySevere},

		{"cemas 6 normal", SubscaleAnxiety, 3, constants.DassNormal},
		{"cemas 8 ringan", SubscaleAnxiety, 4, constants.DassMild},
		{"cemas 10 sedang", SubscaleAnxiety, 5, constants.DassModerate},
		{"cemas 16 parah", SubscaleAnxiety, 8, constants.DassSevere},
		{"cemas 20 sangat parah", SubscaleAnxiety, 10, constants.DassExtremelySevere},

		{"stres 14 masih normal", SubscaleStress, 7, constants.DassNormal},
		{"stres 16 ringan", SubscaleStress, 8, constants.DassMild},
		{"stres 20 sedang", SubscaleStress, 10, constants.DassModerate},
		{"stres 26 parah", SubscaleStress, 13, constants.DassSevere},
		{"stres 34 sangat parah", SubscaleStress, 17, constants.DassExtremelySevere},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			score := ScoreDass21(spreadRaw(tt.subscale, tt.raw))

			got := map[DassSubscale]constants.DassSeverity{
				SubscaleDepression: score.Depression.Severity,
				SubscaleAnxiety:    score.Anxiety.Severity,
				SubscaleStress:     score.Stress.Severity,
			}[tt.subscale]

			if got != tt.want {
				t.Fatalf("severity = %s, want %s (raw %d → skor %d)",
					got, tt.want, tt.raw, tt.raw*DassScoreMultiplier)
			}
		})
	}
}

// spreadRaw menyebar skor mentah ke 7 item milik subskala (tiap item maks 3).
func spreadRaw(sub DassSubscale, raw int) []int {
	answers := make([]int, DassQuestionCount)
	remaining := raw
	for i, q := range DassQuestions() {
		if q.Subscale != sub || remaining <= 0 {
			continue
		}
		value := min(remaining, 3)
		answers[i] = value
		remaining -= value
	}
	return answers
}

func TestHasSevere_TriggersOnAnySubscale(t *testing.T) {
	score := ScoreDass21(spreadRaw(SubscaleStress, 13)) // stres 26 = Severe

	if !score.HasSevere() {
		t.Fatal("satu subskala Severe harus membuat HasSevere true")
	}
}

func TestCopingSuggestions_SevereDirectsToHumanHelp(t *testing.T) {
	suggestions := DassCopingSuggestions(
		constants.DassSevere, constants.DassNormal, constants.DassNormal,
	)

	if len(suggestions) == 0 {
		t.Fatal("kategori berat harus tetap memberi saran")
	}
	// Pada kategori berat, langkah pertama tidak boleh berupa latihan mandiri.
	if !containsAny(suggestions[0], "Konseling", "konseling", "Bantuan") {
		t.Fatalf("saran pertama untuk kategori berat = %q, seharusnya mengarah ke bantuan manusia",
			suggestions[0])
	}
}

func TestCopingSuggestions_NormalStillReturnsSomething(t *testing.T) {
	suggestions := DassCopingSuggestions(
		constants.DassNormal, constants.DassNormal, constants.DassNormal,
	)
	if len(suggestions) == 0 {
		t.Fatal("kategori normal tetap perlu saran perawatan diri")
	}
}

func containsAny(haystack string, needles ...string) bool {
	for _, needle := range needles {
		for i := 0; i+len(needle) <= len(haystack); i++ {
			if haystack[i:i+len(needle)] == needle {
				return true
			}
		}
	}
	return false
}
