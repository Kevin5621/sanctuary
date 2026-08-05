package seeders

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"gorm.io/gorm/clause"

	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
)

// seedChatSample mengisi percakapan Terapis AI.
//
// Fitur ini belum dirilis (menunggu keputusan persetujuan pihak ketiga), jadi
// baris ini hanya memastikan tabel dan aturan privasinya teruji — bukan
// pratinjau perilaku model.
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
