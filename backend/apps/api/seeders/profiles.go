package seeders

import "github.com/gilabs/sanctuary/internal/core/constants"

// ------------------------------------------------------------------
// Profil kondisi mahasiswa demo.
//
// Berkas ini adalah SATU-SATUNYA sumber angka untuk data demo mahasiswa.
// Dua lapis yang sengaja dipisah:
//
//   - Recent* — 14 hari terakhir, ditulis tangan. Rentang inilah yang dibaca
//     Early Warning System, sehingga hasil EWS tiap akun demo dapat diprediksi
//     dan diverifikasi QA (lihat ExpectedLevel).
//   - Baseline* — hari ke-15 sampai ke-90, dibangkitkan deterministik dari id
//     mahasiswa. Rentang ini tidak pernah menyentuh EWS; tujuannya mengisi
//     kalender bulanan dan grafik 30 hari dengan data yang wajar, termasuk
//     hari-hari kosong seperti pemakaian sungguhan.
//
// ------------------------------------------------------------------

// metricHistoryDays adalah panjang riwayat mood yang dibuat seeder.
const metricHistoryDays = 90

// recentWindowDays harus >= EWS_LOOKBACK_DAYS agar seluruh rentang yang
// dievaluasi EWS berasal dari deret yang ditulis tangan, bukan dari data latar.
const recentWindowDays = 14

type conditionProfile struct {
	Key string

	ShareLevel            constants.ShareLevel
	AllowEarlyWarning     bool
	AllowProgramStatistic bool

	// Deret berikut dibaca dari index 0 = hari terlama pada jendela terkini,
	// index terakhir = kemarin. Panjangnya menentukan berapa hari yang diisi.
	Moods    []int
	Stress   []int
	Sleep    []float64
	Emotions []string

	// FilledToday mengisi check-in hari ini juga, sehingga ada akun demo yang
	// memperlihatkan state "sudah check-in" di Beranda.
	FilledToday bool

	// BaselineDays = 0 berarti tidak ada data latar sama sekali (dipakai akun
	// yang justru harus menunjukkan "Data belum cukup").
	BaselineDays   int
	BaselineMood   int
	BaselineStress int
	BaselineSleep  float64
	// BaselineFillRate adalah peluang sebuah hari terisi (0..1). Nilai di bawah
	// 1 membuat kalender punya lubang, seperti pemakaian sungguhan.
	BaselineFillRate float64
	BaselineEmotions []string

	Journals       []journalSeed
	Dass           []dassSeed
	ContactRequest bool
	ChatSample     bool

	// ExpectedLevel didokumentasikan agar QA dapat memverifikasi engine EWS.
	ExpectedLevel constants.EWSLevel
}

// journalSeed adalah satu catatan jurnal. Emosi TIDAK ditulis di sini:
// seeder menjalankan analyzer sungguhan atas Content, sehingga label, skor
// keyakinan, sentimen, dan penandaan krisis identik dengan yang dihasilkan
// aplikasi saat mahasiswa menekan "Analisis Emosi".
type journalSeed struct {
	DaysAgo  int
	Title    string
	Content  string
	Analyzed bool
}

// dassSeed memakai skor MENTAH per subskala (0..21, yaitu jumlah 7 item).
// Severity tidak ditulis tangan — seeder membangun 21 jawaban lalu menskornya
// dengan service.ScoreDass21, sehingga ambang klinis di data demo tidak bisa
// menyimpang dari ambang yang dipakai aplikasi.
type dassSeed struct {
	DaysAgo                   int
	DepressionRaw, AnxietyRaw int
	StressRaw                 int
}

// ------------------------------------------------------------------
// Profil
// ------------------------------------------------------------------

// profileIntervention memicu keempat indikator + DASS severe.
var profileIntervention = conditionProfile{
	Key:                   "intervention",
	ShareLevel:            constants.ShareLevelSummaryTrend,
	AllowEarlyWarning:     true,
	AllowProgramStatistic: true,
	Moods:                 []int{3, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 1, 2},
	Stress:                []int{4, 4, 5, 5, 5, 5, 4, 5, 5, 5, 4, 5, 5, 5},
	Sleep:                 []float64{6.0, 5.5, 4.5, 4.0, 4.5, 4.0, 5.0, 4.5, 4.0, 4.5, 5.0, 4.0, 4.5, 4.0},
	Emotions: []string{
		constants.EmotionTired, constants.EmotionAnxious, constants.EmotionSad, constants.EmotionSad,
		constants.EmotionAnxious, constants.EmotionSad, constants.EmotionTired, constants.EmotionAnxious,
		constants.EmotionSad, constants.EmotionSad, constants.EmotionNeutral, constants.EmotionAnxious,
		constants.EmotionSad, constants.EmotionTired,
	},
	BaselineDays:     metricHistoryDays,
	BaselineMood:     3,
	BaselineStress:   4,
	BaselineSleep:    6.0,
	BaselineFillRate: 0.8,
	BaselineEmotions: []string{
		constants.EmotionNeutral, constants.EmotionTired, constants.EmotionAnxious, constants.EmotionCalm,
	},
	Journals: []journalSeed{
		{
			DaysAgo:  1,
			Title:    "Skripsi terasa berat",
			Content:  "Aku cemas sekali menghadapi bimbingan minggu ini. Rasanya lelah dan sulit tidur, khawatir revisi tidak selesai tepat waktu.",
			Analyzed: true,
		},
		{
			DaysAgo:  3,
			Title:    "Hari yang panjang",
			Content:  "Seharian di kampus, pulang malam, dan masih ada tugas kelompok yang belum selesai. Capek dan kewalahan.",
			Analyzed: true,
		},
		{
			DaysAgo:  6,
			Title:    "Sendirian lagi",
			Content:  "Teman-teman sudah maju sidang. Aku merasa sedih dan tertinggal, kadang merasa hampa memikirkannya.",
			Analyzed: true,
		},
		{
			DaysAgo: 9,
			Title:   "Belum sempat menulis",
			Content: "Hanya ingin mencatat bahwa hari ini berlalu begitu saja.",
		},
		{
			DaysAgo:  12,
			Title:    "Panik saat presentasi",
			Content:  "Tangan gemetar dan deg-degan sepanjang presentasi. Overthinking soal pertanyaan dosen penguji.",
			Analyzed: true,
		},
	},
	Dass: []dassSeed{
		{DaysAgo: 30, DepressionRaw: 7, AnxietyRaw: 6, StressRaw: 8},
		{DaysAgo: 3, DepressionRaw: 12, AnxietyRaw: 11, StressRaw: 14},
	},
	ChatSample:    true,
	ExpectedLevel: constants.EWSLevelIntervention,
}

// profileRisk memicu 2 indikator (emosi negatif + kurang tidur).
var profileRisk = conditionProfile{
	Key:                   "risk",
	ShareLevel:            constants.ShareLevelSummaryTrend,
	AllowEarlyWarning:     true,
	AllowProgramStatistic: true,
	Moods:                 []int{3, 2, 3, 3, 2, 3, 3, 2, 3, 3, 2, 3, 3, 3},
	Stress:                []int{4, 4, 3, 4, 4, 3, 4, 4, 4, 3, 4, 4, 3, 4},
	Sleep:                 []float64{6.5, 4.5, 6.0, 7.0, 4.0, 6.5, 7.0, 6.0, 6.5, 7.0, 4.5, 6.5, 7.0, 6.0},
	Emotions: []string{
		constants.EmotionAnxious, constants.EmotionSad, constants.EmotionAnxious, constants.EmotionNeutral,
		constants.EmotionTired, constants.EmotionAnxious, constants.EmotionCalm, constants.EmotionSad,
		constants.EmotionAnxious, constants.EmotionNeutral, constants.EmotionTired, constants.EmotionAnxious,
		constants.EmotionCalm, constants.EmotionSad,
	},
	BaselineDays:     metricHistoryDays,
	BaselineMood:     3,
	BaselineStress:   3,
	BaselineSleep:    6.5,
	BaselineFillRate: 0.75,
	BaselineEmotions: []string{
		constants.EmotionNeutral, constants.EmotionCalm, constants.EmotionAnxious, constants.EmotionJoy,
	},
	Journals: []journalSeed{
		{
			DaysAgo:  2,
			Title:    "Deadline menumpuk",
			Content:  "Tiga tugas besar jatuh di minggu yang sama. Aku kesal pada diri sendiri karena menunda terus.",
			Analyzed: true,
		},
		{
			DaysAgo:  5,
			Title:    "Susah tidur",
			Content:  "Sudah dua malam ini gelisah dan sulit tidur. Khawatir tidak sempat mengejar materi ujian.",
			Analyzed: true,
		},
		{
			DaysAgo:  11,
			Title:    "Akhirnya lega",
			Content:  "Presentasi selesai dan hasilnya cukup baik. Aku merasa lega dan bersyukur.",
			Analyzed: true,
		},
	},
	Dass: []dassSeed{
		{DaysAgo: 20, DepressionRaw: 4, AnxietyRaw: 5, StressRaw: 6},
	},
	ExpectedLevel: constants.EWSLevelRisk,
}

// profileWatch memicu 1 indikator (kurang tidur 2 malam).
var profileWatch = conditionProfile{
	Key:                   "watch",
	ShareLevel:            constants.ShareLevelSummary,
	AllowEarlyWarning:     true,
	AllowProgramStatistic: true,
	Moods:                 []int{4, 3, 4, 3, 4, 4, 3, 4, 4, 3, 4, 4, 3, 4},
	Stress:                []int{3, 3, 2, 3, 3, 2, 3, 3, 2, 3, 3, 2, 3, 3},
	Sleep:                 []float64{7.0, 4.5, 7.5, 7.0, 6.5, 4.0, 7.0, 7.5, 6.5, 7.0, 7.5, 6.5, 7.0, 7.5},
	Emotions: []string{
		constants.EmotionNeutral, constants.EmotionTired, constants.EmotionCalm, constants.EmotionNeutral,
		constants.EmotionJoy, constants.EmotionTired, constants.EmotionCalm, constants.EmotionNeutral,
		constants.EmotionCalm, constants.EmotionNeutral, constants.EmotionJoy, constants.EmotionCalm,
		constants.EmotionNeutral, constants.EmotionCalm,
	},
	BaselineDays:     metricHistoryDays,
	BaselineMood:     4,
	BaselineStress:   3,
	BaselineSleep:    7.0,
	BaselineFillRate: 0.7,
	BaselineEmotions: []string{
		constants.EmotionCalm, constants.EmotionNeutral, constants.EmotionJoy, constants.EmotionTired,
	},
	Journals: []journalSeed{
		{
			DaysAgo:  4,
			Title:    "Begadang lagi",
			Content:  "Semalam hanya tidur empat jam karena mengerjakan laporan. Badan capek tapi masih semangat.",
			Analyzed: true,
		},
		{
			DaysAgo:  8,
			Title:    "Hari yang tenang",
			Content:  "Kuliah hari ini santai. Sempat jalan sore dan merasa damai.",
			Analyzed: true,
		},
	},
	Dass: []dassSeed{
		{DaysAgo: 15, DepressionRaw: 2, AnxietyRaw: 3, StressRaw: 4},
	},
	ExpectedLevel: constants.EWSLevelWatch,
}

// profileNormal: seluruh indikator aman, dan satu-satunya akun yang check-in
// hari ini — dipakai memverifikasi state "sudah check-in" pada Beranda.
var profileNormal = conditionProfile{
	Key:                   "normal",
	ShareLevel:            constants.ShareLevelSummaryTrend,
	AllowEarlyWarning:     false, // demo: berbagi indikator, tetapi menolak peringatan dini
	AllowProgramStatistic: true,
	Moods:                 []int{4, 4, 5, 4, 4, 5, 4, 5, 4, 4, 5, 4, 4, 5},
	Stress:                []int{2, 2, 1, 2, 2, 2, 1, 2, 2, 1, 2, 2, 2, 1},
	Sleep:                 []float64{7.5, 8.0, 7.0, 7.5, 8.0, 7.5, 7.0, 8.0, 7.5, 7.5, 8.0, 7.0, 7.5, 8.0},
	Emotions: []string{
		constants.EmotionCalm, constants.EmotionJoy, constants.EmotionCalm, constants.EmotionNeutral,
		constants.EmotionJoy, constants.EmotionCalm, constants.EmotionJoy, constants.EmotionCalm,
		constants.EmotionNeutral, constants.EmotionJoy, constants.EmotionCalm, constants.EmotionJoy,
		constants.EmotionCalm, constants.EmotionJoy,
	},
	FilledToday:      true,
	BaselineDays:     metricHistoryDays,
	BaselineMood:     4,
	BaselineStress:   2,
	BaselineSleep:    7.5,
	BaselineFillRate: 0.85,
	BaselineEmotions: []string{
		constants.EmotionJoy, constants.EmotionCalm, constants.EmotionNeutral, constants.EmotionCalm,
	},
	Journals: []journalSeed{
		{
			DaysAgo:  1,
			Title:    "Presentasi lancar",
			Content:  "Presentasi kelompok berjalan baik. Aku bangga bisa menyampaikan bagianku dengan tenang.",
			Analyzed: true,
		},
		{
			DaysAgo:  7,
			Title:    "Rutinitas yang enak",
			Content:  "Bangun pagi, olahraga sebentar, lalu belajar. Hari ini terasa santai dan aku bersyukur.",
			Analyzed: true,
		},
		{
			DaysAgo:  14,
			Title:    "Sedikit kesal",
			Content:  "Jadwal kuliah mendadak diubah dan aku jengkel karena rencana hari ini berantakan.",
			Analyzed: true,
		},
	},
	Dass: []dassSeed{
		{DaysAgo: 10, DepressionRaw: 1, AnxietyRaw: 2, StressRaw: 3},
	},
	ExpectedLevel: constants.EWSLevelNormal,
}

// profileNormalSummaryOnly: level berbagi Ringkasan (tanpa tren).
var profileNormalSummaryOnly = conditionProfile{
	Key:                   "normal-summary",
	ShareLevel:            constants.ShareLevelSummary,
	AllowEarlyWarning:     true,
	AllowProgramStatistic: true,
	Moods:                 profileNormal.Moods,
	Stress:                profileNormal.Stress,
	Sleep:                 profileNormal.Sleep,
	Emotions:              profileNormal.Emotions,
	BaselineDays:          metricHistoryDays,
	BaselineMood:          4,
	BaselineStress:        2,
	BaselineSleep:         7.5,
	BaselineFillRate:      0.6,
	BaselineEmotions:      profileNormal.BaselineEmotions,
	Journals: []journalSeed{
		{
			DaysAgo:  3,
			Title:    "Catatan singkat",
			Content:  "Hari ini biasa saja. Tidak ada yang istimewa, tapi juga tidak ada masalah.",
			Analyzed: true,
		},
	},
	Dass:          profileNormal.Dass,
	ExpectedLevel: constants.EWSLevelNormal,
}

// profileClosed: mahasiswa mengunci seluruh berbagi data.
// Data pribadinya tetap lengkap, namun dosen harus menerima indikator kosong.
var profileClosed = conditionProfile{
	Key:                   "closed",
	ShareLevel:            constants.ShareLevelClosed,
	AllowEarlyWarning:     false,
	AllowProgramStatistic: false,
	Moods:                 []int{3, 2, 3, 2, 3, 3, 2, 3, 3, 2, 3, 3, 2, 3},
	Stress:                []int{4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 3, 4, 4, 3},
	Sleep:                 []float64{6.0, 5.5, 6.5, 6.0, 5.0, 6.5, 6.0, 6.5, 5.5, 6.0, 6.5, 6.0, 5.5, 6.5},
	Emotions: []string{
		constants.EmotionAnxious, constants.EmotionSad, constants.EmotionNeutral, constants.EmotionAnxious,
		constants.EmotionTired, constants.EmotionNeutral, constants.EmotionCalm, constants.EmotionAnxious,
		constants.EmotionNeutral, constants.EmotionSad, constants.EmotionCalm, constants.EmotionNeutral,
		constants.EmotionAnxious, constants.EmotionCalm,
	},
	BaselineDays:     metricHistoryDays,
	BaselineMood:     3,
	BaselineStress:   3,
	BaselineSleep:    6.5,
	BaselineFillRate: 0.65,
	BaselineEmotions: []string{
		constants.EmotionNeutral, constants.EmotionAnxious, constants.EmotionCalm, constants.EmotionTired,
	},
	Journals: []journalSeed{
		{
			DaysAgo:  2,
			Title:    "Catatan pribadi",
			Content:  "Hari ini aku hanya ingin menulis untuk diriku sendiri. Tidak ingin dibagikan ke siapa pun.",
			Analyzed: true,
		},
		{
			DaysAgo:  9,
			Title:    "Ragu",
			Content:  "Sering khawatir apakah pilihan jurusanku tepat. Kadang gelisah memikirkan setelah lulus.",
			Analyzed: true,
		},
	},
	ExpectedLevel: constants.EWSLevelNormal,
}

// profileWatchWithRequest: mahasiswa aktif meminta dihubungi pembimbing.
var profileWatchWithRequest = conditionProfile{
	Key:                   "watch-contact",
	ShareLevel:            constants.ShareLevelSummaryTrend,
	AllowEarlyWarning:     true,
	AllowProgramStatistic: true,
	Moods:                 profileWatch.Moods,
	Stress:                profileWatch.Stress,
	Sleep:                 profileWatch.Sleep,
	Emotions:              profileWatch.Emotions,
	BaselineDays:          metricHistoryDays,
	BaselineMood:          4,
	BaselineStress:        3,
	BaselineSleep:         7.0,
	BaselineFillRate:      0.7,
	BaselineEmotions:      profileWatch.BaselineEmotions,
	Journals: []journalSeed{
		{
			DaysAgo:  1,
			Title:    "Ingin bicara",
			Content:  "Rasanya berat menahan semuanya sendiri. Aku ingin bercerita ke pembimbing tapi bingung memulainya.",
			Analyzed: true,
		},
		{
			DaysAgo:  6,
			Title:    "Kelelahan",
			Content:  "Kuliah, asisten praktikum, dan organisasi bersamaan. Aku merasa burnout dan kewalahan.",
			Analyzed: true,
		},
	},
	Dass:           profileWatch.Dass,
	ContactRequest: true,
	ExpectedLevel:  constants.EWSLevelWatch,
}

// profileInsufficient: sengaja hanya dua check-in dan tanpa data latar, agar
// state "Data belum cukup" dapat diverifikasi di sisi mahasiswa maupun dosen.
var profileInsufficient = conditionProfile{
	Key:                   "insufficient",
	ShareLevel:            constants.ShareLevelSummary,
	AllowEarlyWarning:     true,
	AllowProgramStatistic: false,
	Moods:                 []int{4, 3},
	Stress:                []int{2, 3},
	Sleep:                 []float64{7.0, 6.5},
	Emotions:              []string{constants.EmotionCalm, constants.EmotionNeutral},
	BaselineDays:          0,
	ExpectedLevel:         constants.EWSLevelInsufficient,
}

// demoProfiles dipasangkan dengan studentSpecs berdasarkan urutan.
var demoProfiles = []conditionProfile{
	profileIntervention,
	profileRisk,
	profileWatch,
	profileNormal,
	profileNormalSummaryOnly,
	profileClosed,
	profileWatchWithRequest,
	profileInsufficient,
}
