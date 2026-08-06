package seeders

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/crisis"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
)

// consentStatusForProfile memetakan profil demo ke status persetujuan awal.
func consentStatusForProfile(profile conditionProfile) string {
	switch profile.Key {
	case "intervention", "risk", "watch", "watch-contact":
		return studentmodels.ConsentStatusGranted
	case "normal":
		return studentmodels.ConsentStatusDenied
	default:
		// "normal-summary", "closed", "insufficient" belum memutuskan (layar consent muncul)
		return ""
	}
}

// seedAIConsent mengisi keputusan persetujuan Terapis AI.
func (s *Seeder) seedAIConsent(ctx context.Context, studentID string, status string) error {
	now := apptime.DaysAgo(5) // diputuskan 5 hari lalu agar tidak berbenturan dengan hari ini

	consent := studentmodels.AIChatConsent{
		UserID:        studentID,
		Status:        status,
		NoticeVersion: studentmodels.CurrentNoticeVersion,
		DecidedAt:     now,
	}

	if status == studentmodels.ConsentStatusGranted {
		consent.ConsentedAt = &now
	}

	consent.ID = deterministicID(fmt.Sprintf("ai-consent:%s", studentID))
	consent.CreatedAt = now
	consent.UpdatedAt = now

	return s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_id"}},
		DoUpdates: clause.AssignmentColumns([]string{"status", "notice_version", "consented_at", "decided_at", "updated_at"}),
	}).Create(&consent).Error
}

// seedChatSample mengisi percakapan Terapis AI dengan variasi realistis berdasarkan profil mahasiswa.
func (s *Seeder) seedChatSample(ctx context.Context, studentID string, profile conditionProfile) error {
	sessionID := uuid.NewSHA1(uuid.NameSpaceURL, []byte("sanctuary:chat-session:"+studentID)).String()

	var conversation []struct {
		Sender  string
		Content string
	}

	switch profile.Key {
	case "intervention":
		conversation = []struct {
			Sender  string
			Content string
		}{
			{studentmodels.ChatSenderUser, "Aku merasa lelah sekali akhir-akhir ini."},
			{studentmodels.ChatSenderAI, "Halo! Wajar sekali merasa lelah jika aktivitas kuliah sedang padat. Apa yang biasanya menyerap banyak energimu?"},
			{studentmodels.ChatSenderUser, "Tugas akhir dan revisi yang tidak pernah selesai. Dosen pembimbingku sangat perfeksionis."},
			{studentmodels.ChatSenderAI, "Menghadapi revisi tiada akhir dan dosen yang perfeksionis pasti sangat melelahkan. Bagaimana kamu biasanya membagi waktu pengerjaannya?"},
			{studentmodels.ChatSenderUser, "Aku sudah mencoba membuat jadwal, tapi sulit sekali fokus. Rasanya kepalaku mau pecah."},
			{studentmodels.ChatSenderAI, "Saat kepala terasa penuh, fokus memang akan menurun. Apakah kamu sempat mengambil jeda sejenak untuk istirahat?"},
			{studentmodels.ChatSenderUser, "Tidak sempat, kalau aku istirahat aku merasa bersalah. Teman-teman yang lain sudah jauh di depan."},
			{studentmodels.ChatSenderAI, "Membandingkan diri dengan orang lain sering kali menambah beban pikiran. Ingatlah bahwa setiap orang punya jalurnya sendiri."},
			{studentmodels.ChatSenderUser, "Tapi aku merasa tidak ada gunanya hidup kalau terus tertinggal seperti ini."},
			{studentmodels.ChatSenderAI, "Aku mendengar keputusasaan dalam suaramu. Rasanya berat sekali ya? Sanctuary punya Layanan Bantuan Darurat jika kamu butuh berbicara."},
			{studentmodels.ChatSenderUser, "Kadang rasanya lebih baik aku hilang saja dari dunia ini."},
			{studentmodels.ChatSenderAI, "Kamu tidak harus melewati masa sulit ini sendirian. Aku sangat menyarankanmu membuka Layanan Bantuan Darurat untuk terhubung dengan profesional."},
			{studentmodels.ChatSenderUser, "Aku berniat mengakhiri hidup malam ini."}, // Memicu deteksi krisis
			{studentmodels.ChatSenderAI, "Aku sangat mengkhawatirkan keselamatanmu. Tolong segera hubungi Layanan Bantuan Darurat atau datangi fasilitas kesehatan terdekat."},
		}

	case "risk":
		conversation = []struct {
			Sender  string
			Content string
		}{
			{studentmodels.ChatSenderUser, "Aku cemas sekali menghadapi ujian komprehensif minggu depan."},
			{studentmodels.ChatSenderAI, "Halo! Wajar sekali merasa cemas menghadapi ujian penting. Apa yang biasanya membantumu merasa sedikit lebih tenang?"},
			{studentmodels.ChatSenderUser, "Biasanya belajar bareng teman, tapi sekarang semua sibuk masing-masing."},
			{studentmodels.ChatSenderAI, "Kehilangan kelompok belajar memang bisa membuat persiapan terasa lebih sepi dan berat. Bagaimana kalau mencoba belajar mandiri dengan metode Pomodoro?"},
			{studentmodels.ChatSenderUser, "Sudah kucoba, tapi baru 10 menit belajar pikiranku sudah melayang ke mana-mana."},
			{studentmodels.ChatSenderAI, "Fokus memang sulit dipertahankan saat cemas. Tidak apa-apa, mulai saja dengan target kecil, misalnya 5 atau 10 menit dulu."},
			{studentmodels.ChatSenderUser, "Aku takut sekali kalau tidak lulus. Orang tuaku sudah berharap banyak."},
			{studentmodels.ChatSenderAI, "Ekspektasi orang tua bisa menjadi beban yang cukup berat. Ingatlah bahwa usahamu saat ini sudah sangat berharga."},
			{studentmodels.ChatSenderUser, "Aku sampai susah tidur. Semalam hanya tidur 2 jam."},
			{studentmodels.ChatSenderAI, "Kurang tidur akan memperburuk rasa cemasmu. Cobalah matikan layar HP 30 menit sebelum tidur malam ini."},
			{studentmodels.ChatSenderUser, "Terima kasih sarannya, aku akan mencoba tidur lebih cepat malam ini."},
			{studentmodels.ChatSenderAI, "Sama-sama. Semoga malam ini kamu bisa beristirahat dengan lebih baik. Kabari lagi perkembangannya ya."},
		}

	case "watch":
		conversation = []struct {
			Sender  string
			Content string
		}{
			{studentmodels.ChatSenderUser, "Kegiatan organisasi dan kuliahku tabrakan terus minggu ini."},
			{studentmodels.ChatSenderAI, "Halo! Menyeimbangkan organisasi dan kuliah memang membutuhkan energi ekstra. Kegiatan mana yang paling mendesak minggu ini?"},
			{studentmodels.ChatSenderUser, "Rapat proker besar organisasi, padahal lusa ada kuis kalkulus."},
			{studentmodels.ChatSenderAI, "Dua tanggung jawab besar di waktu yang hampir bersamaan. Apakah ada bagian proker yang bisa kamu delegasikan ke teman organisasi?"},
			{studentmodels.ChatSenderUser, "Harusnya bisa, tapi aku tidak enak hati meminta bantuan orang lain."},
			{studentmodels.ChatSenderAI, "Merasa sungkan itu wajar. Namun, delegasi adalah bagian dari kerja tim dan bisa membantumu fokus belajar kuis."},
			{studentmodels.ChatSenderUser, "Betul juga. Aku akan coba bicara dengan wakil ketuaku."},
			{studentmodels.ChatSenderAI, "Langkah yang sangat baik. Semoga pembicaraannya lancar dan kamu punya waktu untuk mempersiapkan kuis kalkulus."},
			{studentmodels.ChatSenderUser, "Terima kasih, rasanya beban pikiran sedikit berkurang."},
			{studentmodels.ChatSenderAI, "Sama-sama! Senang mendengarnya. Fokuslah pada satu hal dulu, kamu pasti bisa melewatinya."},
		}

	case "watch-contact":
		conversation = []struct {
			Sender  string
			Content string
		}{
			{studentmodels.ChatSenderUser, "Aku bingung bagaimana cara menghubungi dosen pembimbing akademisku."},
			{studentmodels.ChatSenderAI, "Halo! Bingung menghubungi dosen pembimbing akademis adalah hal yang umum dirasakan. Apa yang membuatmu ragu?"},
			{studentmodels.ChatSenderUser, "Aku takut mengganggu waktu beliau, dan aku tidak tahu bahasa yang sopan."},
			{studentmodels.ChatSenderAI, "Dosen pembimbing ada untuk membantumu. Biasanya, format chat yang sopan dimulai dengan salam, perkenalan diri, dan maksud yang jelas."},
			{studentmodels.ChatSenderUser, "Apakah kamu bisa memberikan contoh template chat yang baik?"},
			{studentmodels.ChatSenderAI, "Tentu! Contoh: 'Selamat pagi Bapak/Ibu, saya [Nama] NIM [Nomor], mahasiswa bimbingan Bapak/Ibu. Jika berkenan, saya ingin berkonsultasi mengenai rencana studi semester ini. Kapan kira-kira Bapak/Ibu memiliki waktu luang? Terima kasih.'."},
			{studentmodels.ChatSenderUser, "Wah, terima kasih banyak! Template ini sangat membantu."},
			{studentmodels.ChatSenderAI, "Sama-sama! Cobalah kirimkan pesan tersebut. Dosen pembimbing akademismu pasti akan menghargai inisiatifmu."},
			{studentmodels.ChatSenderUser, "Baik, aku akan mengirimi beliau pesan sekarang juga."},
			{studentmodels.ChatSenderAI, "Hebat! Semoga mendapat respon yang baik dan konsultasimu berjalan lancar ya."},
		}

	default:
		// Profil lain tidak memiliki chat sample default
		return nil
	}

	// Percakapan dimulai dari 3 hari yang lalu, berurutan maju setiap 5 menit
	baseTime := apptime.DaysAgo(3)

	for i, message := range conversation {
		msgTime := baseTime.Add(time.Duration(i*5) * time.Minute)

		chat := studentmodels.StudentChatMessage{
			UserID:          studentID,
			SessionID:       sessionID,
			Sender:          message.Sender,
			Content:         message.Content,
			IsCrisisFlagged: crisis.Detect(message.Content).IsFlagged,
		}
		chat.ID = deterministicID(fmt.Sprintf("chat:%s:%d", studentID, i))
		chat.CreatedAt = msgTime
		chat.UpdatedAt = msgTime

		if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "id"}},
			DoUpdates: clause.AssignmentColumns([]string{
				"content", "is_crisis_flagged", "updated_at",
			}),
		}).Create(&chat).Error; err != nil {
			return err
		}
	}
	return nil
}
