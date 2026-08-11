package service

import (
	"testing"

	"github.com/gilabs/sanctuary/internal/core/constants"
)

// Teks yang menyentuh dua emosi dengan jumlah kecocokan sama ("capek" vs
// "semangat"). Sebelumnya pemenangnya ditentukan urutan iterasi map, yang
// diacak Go setiap proses — dan sejak EWS #2 membaca label jurnal, keacakan itu
// bisa menggeser level peringatan dini mahasiswa tanpa tulisannya berubah.
const ambiguousText = "Badan capek sekali hari ini, tapi masih semangat menyelesaikan laporan."

func TestAnalyze_SameTextAlwaysSameLabel(t *testing.T) {
	analyzer := NewEmotionAnalyzer()

	first := analyzer.Analyze(ambiguousText)
	for i := 0; i < 50; i++ {
		got := analyzer.Analyze(ambiguousText)
		if got.EmotionLabel != first.EmotionLabel {
			t.Fatalf("panggilan ke-%d menghasilkan %s, sebelumnya %s",
				i, got.EmotionLabel, first.EmotionLabel)
		}
		if got.SentimentScore != first.SentimentScore {
			t.Fatalf("sentimen ikut berubah: %v vs %v", got.SentimentScore, first.SentimentScore)
		}
	}

	// Instance baru harus sepakat dengan yang lama: seeder, endpoint analisis,
	// dan EWS masing-masing membuat analyzer sendiri.
	if other := NewEmotionAnalyzer().Analyze(ambiguousText); other.EmotionLabel != first.EmotionLabel {
		t.Fatalf("instance lain menghasilkan %s, want %s", other.EmotionLabel, first.EmotionLabel)
	}
}

// Saat seri, yang menang adalah emosi yang lebih perlu diperhatikan — pada
// sistem peringatan dini, keluhan yang tersembunyi lebih mahal daripada
// keluhan yang kelewat terbaca.
func TestAnalyze_TieResolvesToTheConcerningLabel(t *testing.T) {
	result := NewEmotionAnalyzer().Analyze(ambiguousText)

	if !constants.IsNegativeEmotion(result.EmotionLabel) {
		t.Fatalf("label = %s, want emosi yang perlu diperhatikan", result.EmotionLabel)
	}
	if result.EmotionLabel != constants.EmotionTired {
		t.Fatalf("label = %s, want TIRED", result.EmotionLabel)
	}
}

func TestAnalyze_ClearTextIsNotAffectedByTieRule(t *testing.T) {
	analyzer := NewEmotionAnalyzer()

	cases := map[string]string{
		"Aku cemas sekali menghadapi sidang, khawatir tidak siap.": constants.EmotionAnxious,
		"Hari ini tenang, aku merasa lega dan bersyukur.":          constants.EmotionCalm,
		"Rapat berjalan biasa saja.":                               constants.EmotionNeutral,
	}

	for text, want := range cases {
		if got := analyzer.Analyze(text).EmotionLabel; got != want {
			t.Errorf("%q -> %s, want %s", text, got, want)
		}
	}
}
