package repositories

import (
	"context"
	"time"

	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
)

// JournalRepository sengaja TIDAK memiliki satu pun method yang dapat membaca
// jurnal lintas pengguna. Setiap query wajib menerima userID (berasal dari
// klaim JWT), sehingga kebocoran lintas peran tidak mungkin terjadi walau
// ada bug di layer handler.
type JournalRepository interface {
	Create(ctx context.Context, journal *models.StudentJournal) error
	ListByUser(ctx context.Context, userID string, p utils.Pagination) ([]models.StudentJournal, int64, error)
	FindByIDForUser(ctx context.Context, id, userID string) (*models.StudentJournal, error)
	UpdateAnalysis(ctx context.Context, journal *models.StudentJournal) error
	DeleteForUser(ctx context.Context, id, userID string) error
	// CountCrisisFlaggedForUser dipakai layar profil mahasiswa (riwayat analisis).
	CountCrisisFlaggedForUser(ctx context.Context, userID string) (int64, error)
	// ListAnalyzedByUser dipakai layar "Riwayat Analisis Emosi" milik pemilik
	// akun. Sama seperti method lain di sini, userID wajib — tidak ada jalur
	// yang dapat membaca hasil analisis milik orang lain.
	ListAnalyzedByUser(ctx context.Context, userID string, limit int) ([]models.StudentJournal, error)
	// EmotionDistributionForUser menghitung sebaran label emosi (M-MOOD-04)
	// langsung di basis data.
	//
	// Dua hal yang disengaja:
	//   - Yang kembali HANYA pasangan label + jumlah. Tidak ada satu pun kolom
	//     teks jurnal yang ikut ter-select, sehingga layar yang cuma butuh
	//     angka tidak pernah menarik tulisan pribadi ke memori proses.
	//   - Rentang disaring pada journal_date, bukan analyzed_at: yang ingin
	//     dilihat mahasiswa adalah "perasaanku 30 hari terakhir", bukan "kapan
	//     aku menekan tombol analisis".
	EmotionDistributionForUser(ctx context.Context, userID string, from, to time.Time) ([]EmotionCount, error)
	// EmotionDistributionForUsers adalah versi kelompok dari query di atas,
	// dipakai indikator EWS #2 (D-3) dan sebaran emosi kelompok dosen (L-KON-03).
	//
	// Ini SATU-SATUNYA query jurnal yang menerima banyak user id, dan ia tetap
	// menuruti aturan keras repository ini: yang ter-select hanya label emosi
	// dan jumlahnya. Tidak ada judul, tidak ada isi, tidak ada id jurnal —
	// sehingga tulisan pribadi tidak pernah ikut terbawa ke jalur dosen.
	// Penyaringan k-anonymity dan izin berbagi dilakukan pemanggil sebelum
	// daftar id sampai ke sini.
	EmotionDistributionForUsers(ctx context.Context, userIDs []string, from, to time.Time) ([]EmotionCount, error)
	// CountAnalyzedForUserRange melengkapi sebaran di atas dengan jumlah jurnal
	// yang berpenanda krisis pada rentang yang sama.
	CountCrisisFlaggedForUserRange(ctx context.Context, userID string, from, to time.Time) (int64, error)
}

type journalRepository struct{ db *gorm.DB }

func NewJournalRepository(db *gorm.DB) JournalRepository { return &journalRepository{db: db} }

var journalSortWhitelist = map[string]string{
	"date":    "journal_date",
	"created": "created_at",
	"emotion": "emotion_label",
}

func (r *journalRepository) Create(ctx context.Context, journal *models.StudentJournal) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	return utils.TranslateDBError(r.db.WithContext(ctx).Create(journal).Error, "")
}

func (r *journalRepository) ListByUser(ctx context.Context, userID string, p utils.Pagination) ([]models.StudentJournal, int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	query := r.db.WithContext(ctx).Model(&models.StudentJournal{}).Where("user_id = ?", userID)
	if p.Search != "" {
		// Pencarian tetap terkurung pada jurnal milik pengguna itu sendiri.
		query = query.Where("title ILIKE ?", "%"+p.Search+"%")
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, utils.TranslateDBError(err, "")
	}

	var journals []models.StudentJournal
	err := query.
		Order(utils.SafeOrderBy(p.SortBy, "desc", journalSortWhitelist, "journal_date")).
		Limit(p.PerPage).Offset(p.Offset()).
		Find(&journals).Error
	return journals, total, utils.TranslateDBError(err, "")
}

func (r *journalRepository) FindByIDForUser(ctx context.Context, id, userID string) (*models.StudentJournal, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var journal models.StudentJournal
	err := r.db.WithContext(ctx).
		Where("id = ? AND user_id = ?", id, userID).
		First(&journal).Error
	if err != nil {
		return nil, utils.TranslateDBError(err, utils.CodeNotFound)
	}
	return &journal, nil
}

func (r *journalRepository) UpdateAnalysis(ctx context.Context, journal *models.StudentJournal) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	err := r.db.WithContext(ctx).Model(&models.StudentJournal{}).
		Where("id = ? AND user_id = ?", journal.ID, journal.UserID).
		Updates(map[string]any{
			"emotion_label":      journal.EmotionLabel,
			"emotion_confidence": journal.EmotionConfidence,
			"sentiment_score":    journal.SentimentScore,
			"is_crisis_flagged":  journal.IsCrisisFlagged,
			"analyzed_at":        journal.AnalyzedAt,
		}).Error
	return utils.TranslateDBError(err, "")
}

func (r *journalRepository) DeleteForUser(ctx context.Context, id, userID string) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	res := r.db.WithContext(ctx).
		Where("id = ? AND user_id = ?", id, userID).
		Delete(&models.StudentJournal{})
	if res.Error != nil {
		return utils.TranslateDBError(res.Error, "")
	}
	if res.RowsAffected == 0 {
		return utils.NewError(utils.CodeNotFound)
	}
	return nil
}

func (r *journalRepository) ListAnalyzedByUser(ctx context.Context, userID string, limit int) ([]models.StudentJournal, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var journals []models.StudentJournal
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND analyzed_at IS NOT NULL", userID).
		Order("analyzed_at DESC").
		Limit(limit).
		Find(&journals).Error
	return journals, utils.TranslateDBError(err, "")
}

func (r *journalRepository) EmotionDistributionForUser(ctx context.Context, userID string, from, to time.Time) ([]EmotionCount, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var counts []EmotionCount
	// D-3: sumbernya HANYA student_journals. Tabel check-in mood manual
	// (student_daily_metrics) sengaja tidak disentuh di sini — mencampurnya
	// akan membuat satu hari buruk terhitung dua kali pada EWS #2.
	err := r.db.WithContext(ctx).
		Model(&models.StudentJournal{}).
		Select("emotion_label, COUNT(*) AS total").
		Where("user_id = ? AND analyzed_at IS NOT NULL AND emotion_label <> ''", userID).
		Where("journal_date BETWEEN ? AND ?", from, to).
		Group("emotion_label").
		Scan(&counts).Error
	return counts, utils.TranslateDBError(err, "")
}

func (r *journalRepository) EmotionDistributionForUsers(ctx context.Context, userIDs []string, from, to time.Time) ([]EmotionCount, error) {
	if len(userIDs) == 0 {
		return nil, nil
	}

	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var counts []EmotionCount
	err := r.db.WithContext(ctx).
		Model(&models.StudentJournal{}).
		Select("emotion_label, COUNT(*) AS total").
		Where("user_id IN ? AND analyzed_at IS NOT NULL AND emotion_label <> ''", userIDs).
		Where("journal_date BETWEEN ? AND ?", from, to).
		Group("emotion_label").
		Scan(&counts).Error
	return counts, utils.TranslateDBError(err, "")
}

func (r *journalRepository) CountCrisisFlaggedForUserRange(ctx context.Context, userID string, from, to time.Time) (int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var count int64
	err := r.db.WithContext(ctx).Model(&models.StudentJournal{}).
		Where("user_id = ? AND is_crisis_flagged = true", userID).
		Where("journal_date BETWEEN ? AND ?", from, to).
		Count(&count).Error
	return count, utils.TranslateDBError(err, "")
}

func (r *journalRepository) CountCrisisFlaggedForUser(ctx context.Context, userID string) (int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var count int64
	err := r.db.WithContext(ctx).Model(&models.StudentJournal{}).
		Where("user_id = ? AND is_crisis_flagged = true", userID).
		Count(&count).Error
	return count, utils.TranslateDBError(err, "")
}
