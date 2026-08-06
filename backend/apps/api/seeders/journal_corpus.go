package seeders

// ------------------------------------------------------------------
// Korpus jurnal latar.
//
// Berkas ini melengkapi journalSeed yang ditulis tangan di profiles.go dengan
// pola dua lapis yang sama seperti check-in mood:
//
//   - profile.Journals   — ditulis tangan, beberapa hari terakhir. Ini yang
//     dibaca QA saat memverifikasi tampilan hasil analisis.
//   - JournalBackground  — dibangkitkan deterministik dari korpus di bawah,
//     tersebar pada 30 hari terakhir. Tujuannya mengisi grafik Sebaran Emosi
//     (M-MOOD-04) dengan sebaran yang wajar dan bervariasi.
//
// Catatan penting: label emosi TIDAK ditulis di sini. Seeder tetap menjalankan
// analyzer sungguhan atas teksnya, persis seperti pada entri tulisan tangan.
// Nama "tone" di bawah hanyalah maksud penulis korpus — bila kelak analyzer
// diganti, label data demo ikut berubah mengikuti model yang baru, dan itu
// memang perilaku yang diinginkan.
//
// Aman terhadap EWS: Early Warning System hanya membaca student_daily_metrics,
// tidak pernah student_journals. Menambah jurnal sebanyak apa pun karena itu
// tidak menggeser satu pun skenario EWS di README §5.
// ------------------------------------------------------------------

// journalTone mengelompokkan teks menurut nada yang dimaksudkan penulisnya.
type journalTone string

const (
	toneAnxious journalTone = "anxious"
	toneSad     journalTone = "sad"
	toneAngry   journalTone = "angry"
	toneTired   journalTone = "tired"
	toneCalm    journalTone = "calm"
	toneJoy     journalTone = "joy"
	toneNeutral journalTone = "neutral"
)

type corpusEntry struct {
	Title   string
	Content string
}

// journalCorpus memuat catatan realistis mahasiswa Indonesia. Setiap nada
// punya beberapa varian supaya dua mahasiswa demo tidak terlihat menyalin
// buku harian yang sama.
var journalCorpus = map[journalTone][]corpusEntry{
	toneAnxious: {
		{"Menjelang seminar", "Besok seminar proposal dan aku cemas sekali. Overthinking membayangkan pertanyaan penguji yang tidak bisa kujawab."},
		{"Belum ada kabar", "Sudah seminggu menunggu balasan email dosen. Khawatir jadwalku mundur lagi semester ini."},
		{"Deg-degan", "Presentasi tadi bikin deg-degan sampai tanganku dingin. Takut salah menyebut angka di depan kelas."},
		{"Nilai belum keluar", "Nilai UTS belum keluar juga. Gelisah memikirkan kemungkinan harus mengulang mata kuliah ini."},
		{"Panik kecil", "Sempat panik waktu sadar file revisiku belum tersimpan. Untung masih ada salinan lama."},
		{"Khawatir biaya", "Uang kos bulan depan belum jelas. Aku khawatir harus menunda bayar UKT."},
	},
	toneSad: {
		{"Sepi", "Teman satu angkatan sudah pada sidang. Aku merasa sendiri dan tertinggal jauh."},
		{"Kecewa", "Proposalku ditolak lagi. Kecewa rasanya, sudah dikerjakan berminggu-minggu."},
		{"Hampa", "Hari ini terasa hampa. Tidak ada yang salah, tapi juga tidak ada yang terasa berarti."},
		{"Rindu rumah", "Kangen masakan ibu. Sedih tinggal jauh dan cuma bisa telepon seminggu sekali."},
		{"Menangis diam-diam", "Sempat menangis di kamar mandi kampus tadi siang. Setelah itu pura-pura biasa saja."},
		{"Kesepian di keramaian", "Ramai di kantin tapi aku merasa kesepian. Sulit menjelaskannya ke siapa pun."},
	},
	toneAngry: {
		{"Kerja kelompok", "Kesal sekali dengan anggota kelompok yang tidak mengerjakan bagiannya. Aku yang harus menambal semuanya."},
		{"Jadwal berubah", "Jadwal kuliah diubah mendadak tanpa pemberitahuan. Jengkel karena rencanaku hari ini berantakan."},
		{"Antre lama", "Muak mengantre urusan administrasi yang bolak-balik. Emosi rasanya menahan diri di loket."},
		{"Dijanjikan tapi tidak", "Marah karena dijanjikan bimbingan lalu dibatalkan sepihak. Sudah bolak-balik ke kampus."},
		{"Salah paham", "Ada salah paham di grup dan aku kesal karena dianggap tidak bekerja."},
	},
	toneTired: {
		{"Begadang", "Tidur jam tiga pagi mengejar laporan. Badan capek dan kepala berat sepanjang hari."},
		{"Padat", "Kuliah pagi, asisten praktikum siang, rapat organisasi malam. Kewalahan mengatur waktu."},
		{"Burnout", "Rasanya burnout. Sudah dua minggu tidak ada hari yang benar-benar libur."},
		{"Ngantuk terus", "Ngantuk sepanjang kelas walau sudah minum kopi. Lelah yang tidak hilang walau tidur."},
		{"Drained", "Habis presentasi rasanya drained total. Ingin tidur saja sisa harinya."},
	},
	toneCalm: {
		{"Sore yang enak", "Jalan sore keliling kampus dan rasanya damai. Sempat duduk lama di taman."},
		{"Lega", "Akhirnya revisi bab dua disetujui. Lega sekali setelah berminggu-minggu."},
		{"Pagi santai", "Bangun lebih pagi, sarapan pelan-pelan. Hari ini terasa tenang."},
		{"Bersyukur", "Bersyukur masih punya teman yang mau mendengarkan tanpa menghakimi."},
		{"Rutinitas kembali", "Mulai rutin olahraga ringan lagi. Badan terasa lebih santai."},
	},
	toneJoy: {
		{"Berhasil", "Senang sekali, kode yang error tiga hari akhirnya jalan. Puas rasanya."},
		{"Dapat kabar baik", "Bahagia dapat kabar lolos seleksi asisten lab. Semangat lagi kuliahnya."},
		{"Presentasi lancar", "Presentasi berjalan lancar dan dosen memuji analisisnya. Bangga pada diri sendiri."},
		{"Kumpul teman", "Ketemu teman lama dan cerita banyak. Excited menunggu agenda berikutnya."},
		{"Progres skripsi", "Bab tiga selesai lebih cepat dari target. Senang dan lega bersamaan."},
	},
	toneNeutral: {
		{"Catatan singkat", "Hari ini berjalan seperti biasa. Kuliah, makan, pulang."},
		{"Tidak banyak", "Tidak banyak yang terjadi hari ini. Menulis sekadar supaya rutin."},
		{"Agenda besok", "Mencatat agenda besok supaya tidak lupa: kelas pagi dan tugas statistik."},
		{"Biasa saja", "Biasa saja. Tidak buruk, tidak istimewa."},
		{"Rekap minggu", "Merekap apa yang sudah dikerjakan minggu ini. Sebagian besar selesai."},
	},
}

// journalBackgroundPlan menentukan berapa banyak jurnal latar dibuat dan
// dengan komposisi nada seperti apa.
//
// Bobot ditulis sebagai daftar nada berulang: makin sering sebuah nada muncul
// di daftar, makin besar porsinya. Cara ini dipilih agar komposisinya terbaca
// langsung tanpa perlu menghitung persentase.
type journalBackgroundPlan struct {
	Count int
	Tones []journalTone
}

// backgroundPlans dipetakan dari conditionProfile.Key.
//
// Komposisinya sengaja mencerminkan kondisi tiap akun demo, sehingga grafik
// Sebaran Emosi terlihat konsisten dengan level EWS-nya — mahasiswa "Perlu
// Intervensi" memang didominasi nada negatif, dan yang "Normal" tidak.
var backgroundPlans = map[string]journalBackgroundPlan{
	"intervention": {
		Count: 15,
		Tones: []journalTone{
			toneAnxious, toneAnxious, toneAnxious, toneAnxious,
			toneSad, toneSad, toneSad, toneSad,
			toneTired, toneTired, toneTired,
			toneAngry,
			toneNeutral, toneNeutral,
			toneCalm,
		},
	},
	"risk": {
		Count: 14,
		Tones: []journalTone{
			toneAnxious, toneAnxious, toneAnxious,
			toneSad, toneSad, toneSad,
			toneTired, toneTired,
			toneAngry, toneAngry,
			toneNeutral, toneNeutral,
			toneCalm, toneJoy,
		},
	},
	"watch": {
		Count: 14,
		Tones: []journalTone{
			toneTired, toneTired, toneTired,
			toneAnxious, toneAnxious,
			toneNeutral, toneNeutral, toneNeutral,
			toneCalm, toneCalm, toneCalm,
			toneJoy, toneJoy,
			toneSad,
		},
	},
	"normal": {
		Count: 15,
		Tones: []journalTone{
			toneJoy, toneJoy, toneJoy, toneJoy,
			toneCalm, toneCalm, toneCalm, toneCalm,
			toneNeutral, toneNeutral, toneNeutral,
			toneTired, toneTired,
			toneAnxious, toneAngry,
		},
	},
	"normal-summary": {
		Count: 16,
		Tones: []journalTone{
			toneCalm, toneCalm, toneCalm,
			toneJoy, toneJoy, toneJoy,
			toneNeutral, toneNeutral, toneNeutral, toneNeutral,
			toneTired, toneTired,
			toneAnxious, toneAnxious,
			toneSad, toneAngry,
		},
	},
	"closed": {
		Count: 17,
		Tones: []journalTone{
			toneAnxious, toneAnxious, toneAnxious,
			toneNeutral, toneNeutral, toneNeutral, toneNeutral,
			toneSad, toneSad,
			toneTired, toneTired,
			toneCalm, toneCalm, toneCalm,
			toneJoy, toneJoy,
			toneAngry,
		},
	},
	"watch-contact": {
		Count: 16,
		Tones: []journalTone{
			toneTired, toneTired, toneTired, toneTired,
			toneAnxious, toneAnxious, toneAnxious,
			toneSad, toneSad,
			toneNeutral, toneNeutral, toneNeutral,
			toneCalm, toneCalm,
			toneJoy, toneAngry,
		},
	},
	// profileInsufficient sengaja TIDAK diberi jurnal latar: akun ini ada untuk
	// memverifikasi state "Data belum cukup", termasuk empty state pada grafik
	// Sebaran Emosi. Mengisinya justru menghapus skenario yang ingin diuji.
	"insufficient": {Count: 0},
}

// backgroundJournals memproduksi jurnal latar untuk mengisi riwayat.
func backgroundJournals(studentID string, profile conditionProfile) []journalSeed {
	plan, ok := backgroundPlans[profile.Key]
	if !ok || plan.Count == 0 {
		return nil
	}

	// Buat seed deterministik dari studentID agar sebaran pesan stabil
	var seedInt int
	for _, char := range studentID {
		seedInt += int(char)
	}

	var seeds []journalSeed
	usedDays := make(map[int]bool)
	for _, j := range profile.Journals {
		usedDays[j.DaysAgo] = true
	}

	for i := 0; i < plan.Count; i++ {
		tone := plan.Tones[i%len(plan.Tones)]
		entries := journalCorpus[tone]
		if len(entries) == 0 {
			continue
		}

		entryIdx := (seedInt + i) % len(entries)
		entry := entries[entryIdx]

		// Distribusikan daysAgo secara merata dalam rentang 2 - 30 hari lalu
		daysAgo := 2 + (i * 28 / plan.Count)
		// Hindari tabrakan hari
		for offset := 0; offset < 30; offset++ {
			candidate := 2 + ((daysAgo - 2 + offset) % 29)
			if !usedDays[candidate] {
				daysAgo = candidate
				break
			}
		}
		usedDays[daysAgo] = true

		seeds = append(seeds, journalSeed{
			DaysAgo:  daysAgo,
			Title:    entry.Title,
			Content:  entry.Content,
			Analyzed: true,
		})
	}

	return seeds
}

