package repositories

import (
	"context"
	"errors"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
)

// ChatRepository melayani percakapan Terapis AI — KONTEN PRIVAT (I-1).
//
// Bentuk antarmuka ini mengikuti JournalRepository dengan alasan yang sama:
// TIDAK ADA satu pun method yang bisa membaca pesan tanpa userID. Akibatnya,
// bahkan bila kelak seseorang menulis handler untuk peran lain, tidak tersedia
// jalur repository yang dapat ia panggil untuk mengambil isi chat orang lain —
// kebocoran harus melewati penulisan query baru dari nol, yang jauh lebih
// terlihat pada saat review.
type ChatRepository interface {
	Append(ctx context.Context, message *models.StudentChatMessage) error
	// AppendAll menyimpan pesan mahasiswa dan balasan AI dalam satu transaksi,
	// sehingga riwayat tidak pernah berisi pertanyaan tanpa jawaban akibat
	// kegagalan di tengah jalan.
	AppendAll(ctx context.Context, messages []*models.StudentChatMessage) error
	// ListRecentForUser mengembalikan `limit` pesan TERBARU pada sebuah sesi,
	// diurutkan dari yang paling lama. Pemangkasan dilakukan di SQL agar
	// percakapan panjang tidak pernah ditarik seluruhnya ke memori.
	ListRecentForUser(ctx context.Context, userID, sessionID string, limit int) ([]models.StudentChatMessage, error)
	// LatestSessionID mengembalikan "" bila mahasiswa belum pernah chat.
	LatestSessionID(ctx context.Context, userID string) (string, error)
	CountForSession(ctx context.Context, userID, sessionID string) (int64, error)
	// DeleteAllForUser dipakai mahasiswa yang menarik persetujuannya —
	// menolak D-5 setelah pernah setuju harus benar-benar menghapus jejaknya.
	DeleteAllForUser(ctx context.Context, userID string) error
}

type chatRepository struct{ db *gorm.DB }

func NewChatRepository(db *gorm.DB) ChatRepository { return &chatRepository{db: db} }

func (r *chatRepository) Append(ctx context.Context, message *models.StudentChatMessage) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	return utils.TranslateDBError(r.db.WithContext(ctx).Create(message).Error, "")
}

func (r *chatRepository) AppendAll(ctx context.Context, messages []*models.StudentChatMessage) error {
	if len(messages) == 0 {
		return nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		for _, message := range messages {
			if err := tx.Create(message).Error; err != nil {
				return err
			}
		}
		return nil
	})
	return utils.TranslateDBError(err, "")
}

func (r *chatRepository) ListRecentForUser(ctx context.Context, userID, sessionID string, limit int) ([]models.StudentChatMessage, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var messages []models.StudentChatMessage
	// Ambil yang terbaru dulu (memanfaatkan idx_chat_user_session), lalu balik
	// urutannya di Go supaya klien menerima percakapan dari lama ke baru.
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND session_id = ?", userID, sessionID).
		Order("created_at DESC, id DESC").
		Limit(limit).
		Find(&messages).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, "")
	}

	for i, j := 0, len(messages)-1; i < j; i, j = i+1, j-1 {
		messages[i], messages[j] = messages[j], messages[i]
	}
	return messages, nil
}

func (r *chatRepository) LatestSessionID(ctx context.Context, userID string) (string, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var message models.StudentChatMessage
	err := r.db.WithContext(ctx).
		Select("session_id", "created_at").
		Where("user_id = ?", userID).
		Order("created_at DESC").
		First(&message).Error
	if err != nil {
		// Belum pernah chat adalah keadaan sah, bukan error.
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", nil
		}
		return "", utils.TranslateDBError(err, "")
	}
	return message.SessionID, nil
}

func (r *chatRepository) CountForSession(ctx context.Context, userID, sessionID string) (int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var count int64
	err := r.db.WithContext(ctx).Model(&models.StudentChatMessage{}).
		Where("user_id = ? AND session_id = ?", userID, sessionID).
		Count(&count).Error
	return count, utils.TranslateDBError(err, "")
}

func (r *chatRepository) DeleteAllForUser(ctx context.Context, userID string) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Delete(&models.StudentChatMessage{}).Error
	return utils.TranslateDBError(err, "")
}
