package constants

// ------------------------------------------------------------------
// Opsi check-in harian.
//
// Daftar ini berada di server dan dikirim lewat endpoint /options. Alasannya
// sama dengan katalog DASS-21: menambah atau mengubah pilihan tidak boleh
// menunggu rilis aplikasi, dan dua klien tidak boleh menampilkan pilihan
// yang berbeda untuk kolom yang sama.
// ------------------------------------------------------------------

// MoodScaleMin/Max adalah rentang skor mood dan stres (dijaga CHECK constraint
// di skema, jadi nilainya tidak boleh berubah tanpa migrasi).
const (
	MoodScoreMin   = 1
	MoodScoreMax   = 5
	StressLevelMin = 1
	StressLevelMax = 5
	SleepHoursMin  = 0.0
	SleepHoursMax  = 24.0
)

// LabeledOption adalah pasangan kode tersimpan dan teks yang dilihat pengguna.
type LabeledOption struct {
	Value string
	Label string
}

// MoodScaleOption menjelaskan arti tiap angka pada skala mood 1..5.
// Tanpa label ini, angka 3 bisa berarti apa saja bagi tiap mahasiswa.
type MoodScaleOption struct {
	Value int
	Label string
}

var MoodScaleOptions = []MoodScaleOption{
	{1, "Sangat buruk"},
	{2, "Buruk"},
	{3, "Biasa saja"},
	{4, "Baik"},
	{5, "Sangat baik"},
}

var StressScaleOptions = []MoodScaleOption{
	{1, "Sangat santai"},
	{2, "Santai"},
	{3, "Sedang"},
	{4, "Tertekan"},
	{5, "Sangat tertekan"},
}

// Check-in tidak lagi menanyakan label emosi. Dulu ada EmotionCheckinOptions —
// tujuh emosi yang dipilih sendiri mahasiswa — di samping skala mood 1..5.
// Keduanya menanyakan hal yang sama dengan dua cara, dan yang digambar kalender
// tetap skala mood. Emosi bernama kini hanya datang dari analisis jurnal
// (constants.Emotion*, dipakai emotion_analyzer dan EWS #2 / D-3).

// Pemicu akademik kini berupa string bebas (opsional, maks 255 karakter).
func IsValidAcademicTrigger(text string) bool {
	return len(text) <= 255
}

// AcademicTriggerLabel mengembalikan teks pemicu lansung karena pemicu berupa string bebas.
func AcademicTriggerLabel(text string) string {
	return text
}
