// Package crisis adalah SATU-SATUNYA leksikon deteksi tanda krisis di Sanctuary.
//
// Sebelumnya leksikon ini hidup di dalam service.EmotionAnalyzer (jurnal saja).
// Ia dipindahkan ke core karena Terapis AI (M-AI-04) harus memakai daftar yang
// SAMA PERSIS dengan jurnal (M-JUR-05).
//
// Alasan keamanan menaruhnya di satu tempat:
//
//   - Dua leksikon yang terpisah pasti menyimpang seiring waktu. Bila daftar
//     chat tertinggal satu frasa dari daftar jurnal, ada kalimat yang memicu
//     kartu bantuan saat ditulis di jurnal tetapi DIAM saat ditulis ke Terapis
//     AI. Untuk fitur yang tugasnya mengenali risiko bunuh diri, senyap adalah
//     mode kegagalan yang paling mahal.
//   - Menambah frasa baru (mis. slang baru) harus otomatis berlaku di seluruh
//     permukaan tulisan mahasiswa, tanpa bergantung pada ingatan penulis kode
//     untuk menyalinnya ke tempat kedua.
//
// Deteksi berjalan IN-PROCESS dan tidak pernah bergantung pada balasan model
// eksternal. Ini disengaja: kartu bantuan darurat harus tetap muncul walau
// Gemini timeout, error, atau mengembalikan jawaban yang tidak relevan.
package crisis

import "strings"

// Result adalah keluaran deteksi. Message sengaja ikut di sini (bukan disusun
// klien) supaya kalimat yang dibaca mahasiswa dalam keadaan rentan identik di
// jurnal maupun chat, dan hanya berubah lewat satu tempat.
type Result struct {
	IsFlagged bool
	Message   string
}

// lexicon memicu penanganan krisis. Daftar ini sengaja konservatif
// (lebih baik false positive daripada terlewat).
var lexicon = []string{
	"bunuh diri", "mengakhiri hidup", "tidak ingin hidup", "ingin mati",
	"menyakiti diri", "melukai diri", "self harm", "tidak ada gunanya hidup",
	"lebih baik aku hilang", "menyerah pada hidup",
}

// message adalah teks pendamping kartu bantuan darurat.
const message = "Sepertinya kamu sedang melewati masa yang sangat berat. " +
	"Kamu tidak harus menghadapinya sendirian. Buka menu Layanan Bantuan Darurat " +
	"untuk terhubung dengan pendamping profesional sekarang."

// Detect memeriksa teks bebas apa pun (jurnal maupun pesan chat).
//
// Pencocokan dilakukan case-insensitive atas substring. Substring dipilih
// dengan sadar: pemenggalan kata akan melewatkan "pengen bunuh diri aja"
// karena imbuhan dan variasi ejaan mahasiswa tidak dapat diprediksi.
func Detect(text string) Result {
	lower := strings.ToLower(text)
	for _, phrase := range lexicon {
		if strings.Contains(lower, phrase) {
			return Result{IsFlagged: true, Message: message}
		}
	}
	return Result{}
}

// Message mengembalikan teks pendamping kartu bantuan darurat.
func Message() string { return message }

// Lexicon mengembalikan salinan daftar frasa.
//
// Dipakai test untuk memastikan jurnal dan chat benar-benar memakai daftar yang
// sama. Salinan dikembalikan agar pemanggil tidak dapat memodifikasi leksikon
// yang berlaku secara global.
func Lexicon() []string {
	out := make([]string, len(lexicon))
	copy(out, lexicon)
	return out
}
