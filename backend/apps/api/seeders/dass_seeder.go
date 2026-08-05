package seeders

import (
	"context"
	"fmt"

	"gorm.io/gorm/clause"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

// seedDassResults mengisi riwayat skrining DASS-21.
//
// Severity tidak ditulis tangan. Seeder membangun 21 jawaban yang menghasilkan
// skor mentah yang diminta profil, lalu menskornya dengan service.ScoreDass21 —
// fungsi yang sama dengan yang dipakai endpoint. Dengan begitu data demo tidak
// bisa memuat kombinasi skor dan kategori yang tidak mungkin terjadi di
// aplikasi (kesalahan yang mudah lolos bila severity diketik manual).
func (s *Seeder) seedDassResults(ctx context.Context, studentID string, profile conditionProfile) error {
	for i, seed := range profile.Dass {
		answers := buildDassAnswers(seed)
		score := service.ScoreDass21(answers)

		result := studentmodels.Dass21Result{
			UserID:             studentID,
			DepressionScore:    score.Depression.Score,
			AnxietyScore:       score.Anxiety.Score,
			StressScore:        score.Stress.Score,
			DepressionSeverity: score.Depression.Severity,
			AnxietySeverity:    score.Anxiety.Severity,
			StressSeverity:     score.Stress.Severity,
			TakenAt:            apptime.DaysAgo(seed.DaysAgo),
		}
		result.ID = deterministicID(fmt.Sprintf("dass:%s:%d", studentID, i))

		if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "id"}},
			DoUpdates: clause.AssignmentColumns([]string{
				"depression_score", "anxiety_score", "stress_score",
				"depression_severity", "anxiety_severity", "stress_severity",
				"taken_at", "updated_at",
			}),
		}).Create(&result).Error; err != nil {
			return err
		}
	}
	return nil
}

// buildDassAnswers menyebar skor mentah per subskala ke 7 item miliknya.
// Setiap item bernilai 0..3, sehingga skor mentah 0..21 selalu tercapai persis.
func buildDassAnswers(seed dassSeed) []int {
	remaining := map[service.DassSubscale]int{
		service.SubscaleDepression: seed.DepressionRaw,
		service.SubscaleAnxiety:    seed.AnxietyRaw,
		service.SubscaleStress:     seed.StressRaw,
	}

	answers := make([]int, service.DassQuestionCount)
	for i, question := range service.DassQuestions() {
		value := min(remaining[question.Subscale], 3)
		answers[i] = value
		remaining[question.Subscale] -= value
	}
	return answers
}
