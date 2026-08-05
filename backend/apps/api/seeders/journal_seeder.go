package seeders

import (
	"context"
	"fmt"
	"time"

	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

// seedJournals mengisi jurnal beserta hasil analisisnya.
//
// Analisis TIDAK ditulis tangan: seeder memanggil analyzer yang sama dengan
// yang dipakai aplikasi. Konsekuensinya, label emosi, skor keyakinan, sentimen,
// dan penandaan krisis pada data demo mustahil menyimpang dari perilaku
// sesungguhnya — dan bila analyzer diganti (mock → IndoBERT), data demo ikut
// mengikuti tanpa perlu disunting.
func (s *Seeder) seedJournals(ctx context.Context, studentID string, profile conditionProfile) error {
	if len(profile.Journals) == 0 {
		return nil
	}

	analyzer := service.NewEmotionAnalyzer()

	for i, seed := range profile.Journals {
		journalDate := apptime.DaysAgo(seed.DaysAgo)

		journal := studentmodels.StudentJournal{
			UserID:      studentID,
			Title:       seed.Title,
			Content:     seed.Content,
			JournalDate: journalDate,
		}
		journal.ID = deterministicID(fmt.Sprintf("journal:%s:%d", studentID, i))

		if seed.Analyzed {
			result := analyzer.Analyze(seed.Content)
			// Waktu analisis diikat ke tanggal jurnalnya, bukan ke saat seeder
			// dijalankan, supaya grafik tren riwayat tetap masuk akal.
			analyzedAt := journalDate.Add(20 * time.Hour) // 20:00 pada hari itu

			journal.EmotionLabel = result.EmotionLabel
			journal.EmotionConfidence = &result.EmotionConfidence
			journal.SentimentScore = &result.SentimentScore
			journal.IsCrisisFlagged = result.IsCrisisFlagged
			journal.AnalyzedAt = &analyzedAt
		}

		if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "id"}},
			DoUpdates: clause.AssignmentColumns([]string{
				"title", "content", "journal_date", "emotion_label", "emotion_confidence",
				"sentiment_score", "is_crisis_flagged", "analyzed_at", "updated_at",
			}),
		}).Create(&journal).Error; err != nil {
			return err
		}
	}
	return nil
}
