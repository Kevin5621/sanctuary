package seeders

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"gorm.io/gorm/clause"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
)

// conditionProfile mendeskripsikan profil kondisi satu mahasiswa demo.
// Pola sengaja deterministik agar hasil EWS dapat diprediksi saat pengujian.
type conditionProfile struct {
	Key string

	ShareLevel            constants.ShareLevel
	AllowEarlyWarning     bool
	AllowProgramStatistic bool

	// Deret berikut dibaca dari index 0 = hari paling lama, terakhir = kemarin.
	Moods    []int
	Stress   []int
	Sleep    []float64
	Emotions []string

	Journals       []journalSeed
	Dass           []dassSeed
	ContactRequest bool
	ChatSample     bool

	// ExpectedLevel didokumentasikan agar QA dapat memverifikasi engine EWS.
	ExpectedLevel constants.EWSLevel
}

type journalSeed struct {
	Title    string
	Content  string
	Analyzed bool
	Emotion  string
}

type dassSeed struct {
	DaysAgo                                   int
	Depression, Anxiety, Stress               int
	DepressionSev, AnxietySev, StressSeverity constants.DassSeverity
}

// ------------------------------------------------------------------
// Profil demo
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
	Journals: []journalSeed{
		{
			Title:    "Skripsi terasa berat",
			Content:  "Aku cemas sekali menghadapi bimbingan minggu ini. Rasanya lelah dan sulit tidur, khawatir revisi tidak selesai tepat waktu.",
			Analyzed: true,
			Emotion:  constants.EmotionAnxious,
		},
		{
			Title:   "Hari yang panjang",
			Content: "Seharian di kampus, pulang malam, dan masih ada tugas kelompok yang belum selesai. Capek.",
		},
	},
	Dass: []dassSeed{
		{DaysAgo: 30, Depression: 14, Anxiety: 12, Stress: 16,
			DepressionSev: constants.DassModerate, AnxietySev: constants.DassModerate, StressSeverity: constants.DassMild},
		{DaysAgo: 3, Depression: 24, Anxiety: 22, Stress: 28,
			DepressionSev: constants.DassSevere, AnxietySev: constants.DassSevere, StressSeverity: constants.DassSevere},
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
	Journals: []journalSeed{
		{Title: "Deadline menumpuk", Content: "Tiga tugas besar jatuh di minggu yang sama. Aku kesal pada diri sendiri karena menunda."},
	},
	Dass: []dassSeed{
		{DaysAgo: 20, Depression: 8, Anxiety: 10, Stress: 12,
			DepressionSev: constants.DassMild, AnxietySev: constants.DassModerate, StressSeverity: constants.DassMild},
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
	Dass: []dassSeed{
		{DaysAgo: 15, Depression: 4, Anxiety: 6, Stress: 8,
			DepressionSev: constants.DassNormal, AnxietySev: constants.DassMild, StressSeverity: constants.DassNormal},
	},
	ExpectedLevel: constants.EWSLevelWatch,
}

// profileNormal: seluruh indikator aman.
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
	Journals: []journalSeed{
		{Title: "Presentasi lancar", Content: "Presentasi kelompok berjalan baik. Aku bangga bisa menyampaikan bagianku dengan tenang."},
	},
	Dass: []dassSeed{
		{DaysAgo: 10, Depression: 2, Anxiety: 3, Stress: 5,
			DepressionSev: constants.DassNormal, AnxietySev: constants.DassNormal, StressSeverity: constants.DassNormal},
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
	Dass:                  profileNormal.Dass,
	ExpectedLevel:         constants.EWSLevelNormal,
}

// profileClosed: mahasiswa mengunci seluruh berbagi data, TETAPI menekan
// tombol "minta dihubungi".
//
// Kombinasi inilah kasus uji D-7: menekan tombol itu adalah persetujuan
// eksplisit dan spesifik yang mengalahkan share_level, sehingga barisnya wajib
// muncul di daftar dosen — dengan nama dan waktu saja, tanpa satu indikator pun
// dan tanpa alasannya (D-6). Tanpa mahasiswa demo seperti ini, aturan D-7 tidak
// pernah benar-benar terlihat dijalankan.
var profileClosed = conditionProfile{
	Key:                   "closed",
	ShareLevel:            constants.ShareLevelClosed,
	AllowEarlyWarning:     false,
	AllowProgramStatistic: false,
	ContactRequest:        true,
	Moods:                 []int{3, 2, 3, 2, 3, 3, 2, 3, 3, 2, 3, 3, 2, 3},
	Stress:                []int{4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 3, 4, 4, 3},
	Sleep:                 []float64{6.0, 5.5, 6.5, 6.0, 5.0, 6.5, 6.0, 6.5, 5.5, 6.0, 6.5, 6.0, 5.5, 6.5},
	Emotions: []string{
		constants.EmotionAnxious, constants.EmotionSad, constants.EmotionNeutral, constants.EmotionAnxious,
		constants.EmotionTired, constants.EmotionNeutral, constants.EmotionCalm, constants.EmotionAnxious,
		constants.EmotionNeutral, constants.EmotionSad, constants.EmotionCalm, constants.EmotionNeutral,
		constants.EmotionAnxious, constants.EmotionCalm,
	},
	Journals: []journalSeed{
		{Title: "Catatan pribadi", Content: "Hari ini aku hanya ingin menulis untuk diriku sendiri. Tidak ingin dibagikan ke siapa pun."},
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
	Dass:                  profileWatch.Dass,
	ContactRequest:        true,
	ExpectedLevel:         constants.EWSLevelWatch,
}

// profileNormalAlerting & profileWatchAlerting: dua mahasiswa yang berbagi
// indikator DAN mengizinkan peringatan dini.
//
// Keduanya ada murni untuk memenuhi ambang k-anonymity pada sebaran tingkat
// perhatian tab Kondisi (L-KON-02): sebaran itu hanya dihitung dari mahasiswa
// yang allow_early_warning = true, dan tanpa keduanya jumlahnya hanya 4.
// Levelnya sengaja berbeda agar grafik sebaran menampilkan lebih dari satu
// batang — sebaran yang seragam tidak membuktikan apa pun saat diverifikasi.
var profileNormalAlerting = conditionProfile{
	Key:                   "normal-alerting",
	ShareLevel:            constants.ShareLevelSummaryTrend,
	AllowEarlyWarning:     true,
	AllowProgramStatistic: true,
	Moods:                 profileNormal.Moods,
	Stress:                profileNormal.Stress,
	Sleep:                 profileNormal.Sleep,
	Emotions:              profileNormal.Emotions,
	Dass:                  profileNormal.Dass,
	ExpectedLevel:         constants.EWSLevelNormal,
}

var profileWatchAlerting = conditionProfile{
	Key:                   "watch-alerting",
	ShareLevel:            constants.ShareLevelSummaryTrend,
	AllowEarlyWarning:     true,
	AllowProgramStatistic: true,
	Moods:                 profileWatch.Moods,
	Stress:                profileWatch.Stress,
	Sleep:                 profileWatch.Sleep,
	Emotions:              profileWatch.Emotions,
	Dass:                  profileWatch.Dass,
	ExpectedLevel:         constants.EWSLevelWatch,
}

// profileInsufficient: data harian di bawah ambang minimum evaluasi.
var profileInsufficient = conditionProfile{
	Key:                   "insufficient",
	ShareLevel:            constants.ShareLevelSummary,
	AllowEarlyWarning:     true,
	AllowProgramStatistic: false,
	Moods:                 []int{4, 3},
	Stress:                []int{2, 3},
	Sleep:                 []float64{7.0, 6.5},
	Emotions:              []string{constants.EmotionCalm, constants.EmotionNeutral},
	ExpectedLevel:         constants.EWSLevelInsufficient,
}

// ------------------------------------------------------------------
// Seeding data mahasiswa
// ------------------------------------------------------------------

func (s *Seeder) seedStudentData(ctx context.Context, users SeededUsers) error {
	// Profil dibaca dari SeededUsers, bukan dari daftar kedua di file ini —
	// dua daftar sejajar yang harus dijaga sinkron manual adalah cara termudah
	// membuat mahasiswa demo mendapat profil kondisi milik orang lain.
	if len(users.Profiles) != len(users.Students) {
		return fmt.Errorf("profil (%d) tidak sejajar dengan mahasiswa (%d)",
			len(users.Profiles), len(users.Students))
	}

	for i, student := range users.Students {
		profile := users.Profiles[i]

		if err := s.seedPrivacySetting(ctx, student.ID, profile); err != nil {
			return err
		}
		if err := s.seedDailyMetrics(ctx, student.ID, profile); err != nil {
			return err
		}
		if err := s.seedJournals(ctx, student.ID, profile); err != nil {
			return err
		}
		if err := s.seedDassResults(ctx, student.ID, profile); err != nil {
			return err
		}
		if profile.ChatSample {
			if err := s.seedChatSample(ctx, student.ID); err != nil {
				return err
			}
		}
		if profile.ContactRequest && student.AdvisorID != nil {
			if err := s.seedContactRequest(ctx, student, *student.AdvisorID); err != nil {
				return err
			}
		}
	}
	return nil
}

func (s *Seeder) seedPrivacySetting(ctx context.Context, studentID string, profile conditionProfile) error {
	setting := studentmodels.StudentPrivacySetting{
		UserID:                studentID,
		ShareLevel:            profile.ShareLevel,
		AllowEarlyWarning:     profile.AllowEarlyWarning,
		AllowProgramStatistic: profile.AllowProgramStatistic,
	}
	setting.ID = deterministicID("privacy:" + studentID)

	return s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "user_id"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"share_level", "allow_early_warning", "allow_program_statistic", "updated_at",
		}),
	}).Create(&setting).Error
}

func (s *Seeder) seedDailyMetrics(ctx context.Context, studentID string, profile conditionProfile) error {
	days := len(profile.Moods)
	metrics := make([]studentmodels.StudentDailyMetric, 0, days)

	triggers := []string{"TUGAS", "UJIAN", "SKRIPSI", "PRESENTASI", ""}

	for i := range days {
		// index 0 = hari terlama, index terakhir = kemarin.
		date := apptime.DaysAgo(days - i)

		metric := studentmodels.StudentDailyMetric{
			UserID:          studentID,
			MetricDate:      date,
			MoodScore:       profile.Moods[i],
			StressLevel:     profile.Stress[i],
			SleepHours:      profile.Sleep[i],
			EmotionLabel:    profile.Emotions[i],
			AcademicTrigger: triggers[i%len(triggers)],
		}
		metric.ID = deterministicID(fmt.Sprintf("metric:%s:%s", studentID, apptime.FormatDate(date)))
		metrics = append(metrics, metric)
	}

	return s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "user_id"}, {Name: "metric_date"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"mood_score", "stress_level", "sleep_hours", "academic_trigger", "emotion_label", "updated_at",
		}),
	}).Create(&metrics).Error
}

func (s *Seeder) seedJournals(ctx context.Context, studentID string, profile conditionProfile) error {
	for i, seed := range profile.Journals {
		journalDate := apptime.DaysAgo(i + 1)

		journal := studentmodels.StudentJournal{
			UserID:      studentID,
			Title:       seed.Title,
			Content:     seed.Content,
			JournalDate: journalDate,
		}
		journal.ID = deterministicID(fmt.Sprintf("journal:%s:%d", studentID, i))

		if seed.Analyzed {
			now := apptime.Now()
			confidence := 0.82
			sentiment := -0.62
			journal.EmotionLabel = seed.Emotion
			journal.EmotionConfidence = &confidence
			journal.SentimentScore = &sentiment
			journal.AnalyzedAt = &now
		}

		if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "id"}},
			DoNothing: true,
		}).Create(&journal).Error; err != nil {
			return err
		}
	}
	return nil
}

func (s *Seeder) seedDassResults(ctx context.Context, studentID string, profile conditionProfile) error {
	for i, seed := range profile.Dass {
		result := studentmodels.Dass21Result{
			UserID:             studentID,
			DepressionScore:    seed.Depression,
			AnxietyScore:       seed.Anxiety,
			StressScore:        seed.Stress,
			DepressionSeverity: seed.DepressionSev,
			AnxietySeverity:    seed.AnxietySev,
			StressSeverity:     seed.StressSeverity,
			TakenAt:            apptime.DaysAgo(seed.DaysAgo),
		}
		result.ID = deterministicID(fmt.Sprintf("dass:%s:%d", studentID, i))

		if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "id"}},
			DoNothing: true,
		}).Create(&result).Error; err != nil {
			return err
		}
	}
	return nil
}

// seedChatSample mengisi percakapan Terapis AI (mock) agar tab tidak kosong.
func (s *Seeder) seedChatSample(ctx context.Context, studentID string) error {
	sessionID := uuid.NewSHA1(uuid.NameSpaceURL, []byte("sanctuary:chat-session:"+studentID)).String()

	conversation := []struct {
		Sender  string
		Content string
	}{
		{studentmodels.ChatSenderUser, "Aku sulit fokus belajar akhir-akhir ini."},
		{studentmodels.ChatSenderAI, "Terima kasih sudah bercerita. Sejak kapan kamu merasa sulit fokus, dan apa yang biasanya mengganggu?"},
		{studentmodels.ChatSenderUser, "Sekitar dua minggu, biasanya karena memikirkan deadline skripsi."},
		{studentmodels.ChatSenderAI, "Wajar merasa terbebani. Mau coba memecah satu bagian skripsi menjadi langkah 25 menit hari ini?"},
	}

	for i, message := range conversation {
		chat := studentmodels.StudentChatMessage{
			UserID:    studentID,
			SessionID: sessionID,
			Sender:    message.Sender,
			Content:   message.Content,
		}
		chat.ID = deterministicID(fmt.Sprintf("chat:%s:%d", studentID, i))

		if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "id"}},
			DoNothing: true,
		}).Create(&chat).Error; err != nil {
			return err
		}
	}
	return nil
}

func (s *Seeder) seedContactRequest(ctx context.Context, student authmodels.User, advisorID string) error {
	request := studentmodels.StudentContactRequest{
		StudentID: student.ID,
		AdvisorID: advisorID,
		Status:    studentmodels.ContactRequestOpen,
		Note:      "Ingin berdiskusi soal beban tugas minggu ini.",
	}
	request.ID = deterministicID("contact-request:" + student.ID)

	return s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "id"}},
		DoNothing: true,
	}).Create(&request).Error
}
