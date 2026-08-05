package service

import "github.com/gilabs/sanctuary/internal/core/constants"

// ------------------------------------------------------------------
// DASS-21 — katalog soal & skoring.
//
// Katalog berada di SERVER, bukan di klien. Alasannya: kalibrasi ulang soal
// atau perbaikan terjemahan tidak boleh menunggu rilis aplikasi, dan dua
// klien (mobile & web) tidak boleh menampilkan soal yang berbeda.
//
// Skoring mengikuti manual DASS-21: setiap subskala terdiri dari 7 item
// bernilai 0..3, lalu totalnya DIKALIKAN 2 agar sebanding dengan DASS-42
// yang menjadi dasar ambang severity. Karena itu skor maksimum per subskala
// adalah 42, bukan 21.
//
// Instrumen ini adalah SKRINING, bukan diagnosis — lihat DisclaimerText.
// ------------------------------------------------------------------

// DassSubscale adalah tiga dimensi yang diukur DASS-21.
type DassSubscale string

const (
	SubscaleDepression DassSubscale = "DEPRESSION"
	SubscaleAnxiety    DassSubscale = "ANXIETY"
	SubscaleStress     DassSubscale = "STRESS"
)

// DassQuestionCount adalah jumlah item yang wajib dijawab.
const DassQuestionCount = 21

// DassScoreMultiplier menyetarakan skor DASS-21 dengan ambang DASS-42.
const DassScoreMultiplier = 2

// DassInstrumentVersion menjaga transparansi bila katalog soal berubah.
const DassInstrumentVersion = "dass21-id-v1"

// DassQuestion adalah satu item kuesioner.
type DassQuestion struct {
	Number   int
	Text     string
	Subscale DassSubscale
}

// dassQuestions memakai pemetaan subskala standar DASS-21:
//
//	Depresi  : 3, 5, 10, 13, 16, 17, 21
//	Kecemasan: 2, 4, 7, 9, 15, 19, 20
//	Stres    : 1, 6, 8, 11, 12, 14, 18
//
// Urutan item TIDAK boleh diubah tanpa mengubah pemetaan di atas.
var dassQuestions = []DassQuestion{
	{1, "Saya merasa sulit untuk menenangkan diri.", SubscaleStress},
	{2, "Saya merasa mulut saya kering.", SubscaleAnxiety},
	{3, "Saya sama sekali tidak merasakan perasaan positif.", SubscaleDepression},
	{4, "Saya mengalami kesulitan bernapas (misalnya napas cepat atau sesak tanpa aktivitas fisik).", SubscaleAnxiety},
	{5, "Saya merasa sulit untuk berinisiatif melakukan sesuatu.", SubscaleDepression},
	{6, "Saya cenderung bereaksi berlebihan terhadap suatu situasi.", SubscaleStress},
	{7, "Saya merasakan gemetar, misalnya pada tangan.", SubscaleAnxiety},
	{8, "Saya merasa menggunakan banyak energi untuk merasa gelisah.", SubscaleStress},
	{9, "Saya khawatir situasi tertentu membuat saya panik dan mempermalukan diri sendiri.", SubscaleAnxiety},
	{10, "Saya merasa tidak ada hal yang dapat saya harapkan.", SubscaleDepression},
	{11, "Saya merasa diri saya mudah gelisah.", SubscaleStress},
	{12, "Saya merasa sulit untuk bersantai.", SubscaleStress},
	{13, "Saya merasa sedih dan tertekan.", SubscaleDepression},
	{14, "Saya tidak dapat memaklumi hal apa pun yang menghalangi saya menyelesaikan pekerjaan.", SubscaleStress},
	{15, "Saya merasa hampir panik.", SubscaleAnxiety},
	{16, "Saya tidak merasa antusias terhadap hal apa pun.", SubscaleDepression},
	{17, "Saya merasa diri saya tidak berharga.", SubscaleDepression},
	{18, "Saya merasa mudah tersinggung.", SubscaleStress},
	{19, "Saya menyadari detak jantung saya walau tidak sedang beraktivitas fisik.", SubscaleAnxiety},
	{20, "Saya merasa takut tanpa alasan yang jelas.", SubscaleAnxiety},
	{21, "Saya merasa hidup ini tidak berarti.", SubscaleDepression},
}

// DassAnswerOption adalah skala frekuensi 0..3 selama seminggu terakhir.
type DassAnswerOption struct {
	Value int
	Label string
}

var dassAnswerOptions = []DassAnswerOption{
	{0, "Tidak pernah"},
	{1, "Kadang-kadang"},
	{2, "Cukup sering"},
	{3, "Hampir selalu"},
}

// DassInstruction ditampilkan di atas kuesioner; rentang waktunya bagian dari
// instrumen, bukan hiasan — mengubahnya mengubah arti skor.
const DassInstruction = "Bacalah setiap pernyataan dan pilih yang paling menggambarkan keadaanmu " +
	"selama SATU MINGGU TERAKHIR. Tidak ada jawaban benar atau salah."

// DassDisclaimer wajib tampil bersama hasil. DASS-21 adalah alat skrining;
// menyebutnya diagnosis akan menyesatkan dan berpotensi membahayakan.
const DassDisclaimer = "Hasil ini adalah skrining awal, bukan diagnosis. " +
	"Hanya tenaga profesional yang dapat menegakkan diagnosis. " +
	"Bila kamu merasa tidak aman dengan dirimu sendiri, buka menu Butuh Bantuan Sekarang."

func DassQuestions() []DassQuestion         { return dassQuestions }
func DassAnswerOptions() []DassAnswerOption { return dassAnswerOptions }

// DassSubscaleResult adalah hasil satu subskala.
type DassSubscaleResult struct {
	Subscale DassSubscale
	// RawScore adalah jumlah 7 item (0..21) sebelum dikalikan.
	RawScore int
	// Score adalah RawScore x2 — inilah angka yang dibandingkan dengan ambang.
	Score    int
	MaxScore int
	Severity constants.DassSeverity
}

// DassScore adalah hasil lengkap satu pengisian.
type DassScore struct {
	Depression DassSubscaleResult
	Anxiety    DassSubscaleResult
	Stress     DassSubscaleResult
}

// TotalScore dipakai indikator EWS "DASS memburuk".
func (s DassScore) TotalScore() int {
	return s.Depression.Score + s.Anxiety.Score + s.Stress.Score
}

// HasSevere true bila ada subskala pada Severe/Extremely Severe — pemicu
// langsung level "Perlu Intervensi" pada EWS.
func (s DassScore) HasSevere() bool {
	return s.Depression.Severity.IsSevere() ||
		s.Anxiety.Severity.IsSevere() ||
		s.Stress.Severity.IsSevere()
}

// severityBand adalah batas bawah (inklusif) sebuah kategori.
type severityBand struct {
	Min      int
	Severity constants.DassSeverity
}

// Ambang standar DASS-21 (setelah dikalikan 2). Diurutkan dari yang terberat
// agar pencocokan berhenti pada band pertama yang cocok.
var (
	depressionBands = []severityBand{
		{28, constants.DassExtremelySevere},
		{21, constants.DassSevere},
		{14, constants.DassModerate},
		{10, constants.DassMild},
		{0, constants.DassNormal},
	}
	anxietyBands = []severityBand{
		{20, constants.DassExtremelySevere},
		{15, constants.DassSevere},
		{10, constants.DassModerate},
		{8, constants.DassMild},
		{0, constants.DassNormal},
	}
	stressBands = []severityBand{
		{34, constants.DassExtremelySevere},
		{26, constants.DassSevere},
		{19, constants.DassModerate},
		{15, constants.DassMild},
		{0, constants.DassNormal},
	}
)

func severityFor(bands []severityBand, score int) constants.DassSeverity {
	for _, band := range bands {
		if score >= band.Min {
			return band.Severity
		}
	}
	return constants.DassNormal
}

// ScoreDass21 menghitung tiga subskala dari 21 jawaban (masing-masing 0..3).
//
// Fungsi ini murni: tidak menyentuh database maupun waktu, sehingga seluruh
// ambang klinis dapat diuji tanpa infrastruktur.
func ScoreDass21(answers []int) DassScore {
	sums := map[DassSubscale]int{}
	for i, q := range dassQuestions {
		if i >= len(answers) {
			break
		}
		sums[q.Subscale] += answers[i]
	}

	build := func(sub DassSubscale, bands []severityBand) DassSubscaleResult {
		raw := sums[sub]
		score := raw * DassScoreMultiplier
		return DassSubscaleResult{
			Subscale: sub,
			RawScore: raw,
			Score:    score,
			MaxScore: 21 * DassScoreMultiplier,
			Severity: severityFor(bands, score),
		}
	}

	return DassScore{
		Depression: build(SubscaleDepression, depressionBands),
		Anxiety:    build(SubscaleAnxiety, anxietyBands),
		Stress:     build(SubscaleStress, stressBands),
	}
}

// DassSeverityLabel memberi teks bahasa Indonesia untuk kategori severity.
func DassSeverityLabel(severity constants.DassSeverity) string {
	switch severity {
	case constants.DassMild:
		return "Ringan"
	case constants.DassModerate:
		return "Sedang"
	case constants.DassSevere:
		return "Parah"
	case constants.DassExtremelySevere:
		return "Sangat Parah"
	default:
		return "Normal"
	}
}

// severityRank memungkinkan perbandingan kategori (0 = Normal).
func severityRank(severity constants.DassSeverity) int {
	switch severity {
	case constants.DassMild:
		return 1
	case constants.DassModerate:
		return 2
	case constants.DassSevere:
		return 3
	case constants.DassExtremelySevere:
		return 4
	default:
		return 0
	}
}

// DassCopingSuggestions memilih saran berdasarkan subskala tertinggi.
// Saran bersifat non-klinis; pada kategori berat, langkah pertama selalu
// diarahkan ke bantuan manusia, bukan ke latihan mandiri.
func DassCopingSuggestions(depression, anxiety, stress constants.DassSeverity) []string {
	highest, highestSub := severityRank(depression), SubscaleDepression
	if rank := severityRank(anxiety); rank > highest {
		highest, highestSub = rank, SubscaleAnxiety
	}
	if rank := severityRank(stress); rank > highest {
		highest, highestSub = rank, SubscaleStress
	}

	if highest >= severityRank(constants.DassSevere) {
		return []string{
			"Hubungi Unit Konseling kampus atau layanan di menu Butuh Bantuan Sekarang dalam waktu dekat.",
			"Ceritakan kondisimu pada satu orang yang kamu percaya hari ini.",
			"Jaga hal paling dasar dulu: tidur, makan, dan minum air yang cukup.",
		}
	}
	if highest == 0 {
		return []string{
			"Pertahankan rutinitas yang sudah berjalan baik dan catat apa yang membantumu.",
			"Lanjutkan check-in harian agar polanya makin terbaca.",
		}
	}

	switch highestSub {
	case SubscaleDepression:
		return []string{
			"Pilih satu aktivitas kecil yang dulu kamu nikmati dan lakukan 15 menit hari ini.",
			"Jalan kaki singkat di luar ruangan dapat membantu menaikkan energi.",
			"Tuliskan satu hal yang berhasil kamu lakukan minggu ini, sekecil apa pun.",
		}
	case SubscaleAnxiety:
		return []string{
			"Coba latihan napas 4-7-8 selama 3 menit di menu Latihan Menenangkan Diri.",
			"Pisahkan yang bisa kamu kendalikan dari yang tidak, lalu kerjakan yang pertama.",
			"Kurangi konsumsi kafein pada sore hari.",
		}
	default:
		return []string{
			"Pecah tugas besarmu menjadi langkah 25 menit dengan jeda 5 menit.",
			"Tetapkan satu jam bebas layar sebelum tidur.",
			"Tinjau bebanmu — adakah tenggat yang masih bisa dinegosiasikan?",
		}
	}
}

// DassSubscaleLabel memberi nama subskala dalam bahasa Indonesia.
func DassSubscaleLabel(sub DassSubscale) string {
	switch sub {
	case SubscaleDepression:
		return "Depresi"
	case SubscaleAnxiety:
		return "Kecemasan"
	case SubscaleStress:
		return "Stres"
	default:
		return string(sub)
	}
}
