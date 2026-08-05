package service

import (
	"math"
	"strings"

	"github.com/gilabs/sanctuary/internal/core/constants"
)

// ------------------------------------------------------------------
// EmotionAnalyzer — MOCK.
//
// Implementasi saat ini berbasis leksikon sederhana agar alur end-to-end
// (jurnal → analisis → saran coping → deteksi krisis) dapat berjalan tanpa
// dependensi model NLP. Antarmuka sengaja dibuat kecil supaya penggantian ke
// model sesungguhnya (atau layanan eksternal) tidak mengubah usecase.
//
// Catatan privasi: analisis berjalan in-process. Bila kelak memakai layanan
// eksternal, teks jurnal TIDAK BOLEH dikirim tanpa persetujuan eksplisit
// mahasiswa dan tinjauan etik.
// ------------------------------------------------------------------

const ModelVersion = "mock-lexicon-v1"

type AnalysisResult struct {
	EmotionLabel      string
	EmotionConfidence float64
	SentimentScore    float64 // -1.0 (sangat negatif) .. 1.0 (sangat positif)
	IsCrisisFlagged   bool
	CopingSuggestions []string
	CrisisMessage     string
}

type EmotionAnalyzer interface {
	Analyze(text string) AnalysisResult
}

type lexiconAnalyzer struct{}

func NewEmotionAnalyzer() EmotionAnalyzer { return &lexiconAnalyzer{} }

var emotionLexicon = map[string][]string{
	constants.EmotionAnxious: {"cemas", "khawatir", "takut", "panik", "gelisah", "deg-degan", "overthinking"},
	constants.EmotionSad:     {"sedih", "kecewa", "hampa", "menangis", "sendiri", "kesepian", "putus asa"},
	constants.EmotionAngry:   {"marah", "kesal", "benci", "muak", "jengkel", "emosi"},
	constants.EmotionTired:   {"lelah", "capek", "burnout", "ngantuk", "kewalahan", "drained"},
	constants.EmotionCalm:    {"tenang", "lega", "damai", "santai", "bersyukur"},
	constants.EmotionJoy:     {"senang", "bahagia", "semangat", "excited", "puas", "bangga"},
}

// crisisLexicon memicu penanganan krisis. Daftar ini sengaja konservatif
// (lebih baik false positive daripada terlewat).
var crisisLexicon = []string{
	"bunuh diri", "mengakhiri hidup", "tidak ingin hidup", "ingin mati",
	"menyakiti diri", "melukai diri", "self harm", "tidak ada gunanya hidup",
	"lebih baik aku hilang", "menyerah pada hidup",
}

var copingByEmotion = map[string][]string{
	constants.EmotionAnxious: {
		"Coba latihan napas 4-7-8 selama 3 menit di menu Latihan Napas.",
		"Tuliskan satu hal yang bisa kamu kendalikan hari ini, dan satu yang tidak.",
		"Pecah tugas besarmu menjadi langkah 15 menit pertama.",
	},
	constants.EmotionSad: {
		"Hubungi satu orang yang membuatmu merasa aman untuk sekadar bercerita.",
		"Jalan kaki 10 menit di luar ruangan dapat membantu menurunkan tekanan.",
		"Ingat kembali satu hal kecil yang berhasil kamu lakukan minggu ini.",
	},
	constants.EmotionAngry: {
		"Beri jeda 10 menit sebelum merespons situasi yang memicu.",
		"Coba grounding 5-4-3-2-1 untuk menurunkan intensitas emosi.",
		"Tuliskan apa kebutuhanmu yang belum terpenuhi di balik rasa marah ini.",
	},
	constants.EmotionTired: {
		"Prioritaskan tidur 7 jam malam ini; catat jam tidurmu di menu Mood.",
		"Ambil istirahat 20 menit tanpa layar setelah sesi belajar.",
		"Tinjau ulang beban tugasmu — adakah yang bisa dinegosiasikan tenggatnya?",
	},
	constants.EmotionCalm: {
		"Catat apa yang membuat harimu terasa tenang agar bisa diulang.",
		"Manfaatkan energi stabil ini untuk menyelesaikan satu tugas tertunda.",
	},
	constants.EmotionJoy: {
		"Bagikan momen baik ini pada seseorang yang kamu percaya.",
		"Simpan catatan syukur hari ini untuk dibaca saat hari berat.",
	},
	constants.EmotionNeutral: {
		"Lakukan check-in mood harian agar polamu makin terbaca.",
		"Sisihkan 5 menit untuk peregangan ringan.",
	},
}

const crisisMessage = "Sepertinya kamu sedang melewati masa yang sangat berat. " +
	"Kamu tidak harus menghadapinya sendirian — buka menu Layanan Bantuan Darurat " +
	"untuk terhubung dengan pendamping profesional sekarang."

func (a *lexiconAnalyzer) Analyze(text string) AnalysisResult {
	lower := strings.ToLower(text)

	// 1. Deteksi krisis lebih dulu — selalu diprioritaskan di atas label emosi.
	isCrisis := false
	for _, phrase := range crisisLexicon {
		if strings.Contains(lower, phrase) {
			isCrisis = true
			break
		}
	}

	// 2. Skor per emosi dari kemunculan kata kunci.
	bestLabel, bestHits := constants.EmotionNeutral, 0
	totalHits := 0
	for label, keywords := range emotionLexicon {
		hits := 0
		for _, kw := range keywords {
			hits += strings.Count(lower, kw)
		}
		totalHits += hits
		if hits > bestHits {
			bestLabel, bestHits = label, hits
		}
	}

	confidence := 0.35
	if totalHits > 0 {
		confidence = 0.5 + 0.5*float64(bestHits)/float64(totalHits)
		if confidence > 0.97 {
			confidence = 0.97
		}
	}

	sentiment := 0.0
	switch {
	case isCrisis:
		sentiment = -0.95
	case constants.IsNegativeEmotion(bestLabel):
		sentiment = -0.3 - 0.5*confidence
	case bestLabel != constants.EmotionNeutral:
		sentiment = 0.3 + 0.5*confidence
	}
	sentiment = clamp(sentiment, -1, 1)

	result := AnalysisResult{
		EmotionLabel:      bestLabel,
		EmotionConfidence: round3(confidence),
		SentimentScore:    round3(sentiment),
		IsCrisisFlagged:   isCrisis,
		CopingSuggestions: copingByEmotion[bestLabel],
	}
	if isCrisis {
		result.CrisisMessage = crisisMessage
	}
	return result
}

func clamp(v, min, max float64) float64 { return math.Min(math.Max(v, min), max) }

func round3(v float64) float64 { return math.Round(v*1000) / 1000 }

// EmotionLabelText memberi teks bahasa Indonesia untuk label emosi.
func EmotionLabelText(label string) string {
	switch label {
	case constants.EmotionJoy:
		return "Senang"
	case constants.EmotionCalm:
		return "Tenang"
	case constants.EmotionSad:
		return "Sedih"
	case constants.EmotionAnxious:
		return "Cemas"
	case constants.EmotionAngry:
		return "Marah"
	case constants.EmotionTired:
		return "Lelah"
	default:
		return "Netral"
	}
}
