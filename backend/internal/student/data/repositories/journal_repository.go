package repositories

import (
	"context"

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

func (r *journalRepository) CountCrisisFlaggedForUser(ctx context.Context, userID string) (int64, error) {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var count int64
	err := r.db.WithContext(ctx).Model(&models.StudentJournal{}).
		Where("user_id = ? AND is_crisis_flagged = true", userID).
		Count(&count).Error
	return count, utils.TranslateDBError(err, "")
}
