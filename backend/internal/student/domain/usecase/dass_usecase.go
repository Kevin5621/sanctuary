package usecase

import (
	"context"
	"fmt"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/mapper"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

// DassHistoryLimit membatasi jumlah riwayat yang dikirim ke klien.
// Grafik tren tidak menjadi lebih informatif di atas angka ini, sementara
// payload dan waktu render bertambah.
const DassHistoryLimit = 20

// DassUsecase melayani skrining DASS-21 milik mahasiswa sendiri.
//
// Skoring dilakukan di server (service.ScoreDass21), bukan di klien: ambang
// klinis tidak boleh berbeda antar versi aplikasi, dan klien tidak boleh bisa
// mengirim severity karangannya sendiri.
type DassUsecase interface {
	Questionnaire(ctx context.Context) dto.DassQuestionnaireResponse
	Submit(ctx context.Context, userID string, req dto.SubmitDassRequest) (dto.DassResultResponse, error)
	History(ctx context.Context, userID string) (dto.DassHistoryResponse, error)
}

type dassUsecase struct {
	repo repositories.DassRepository
}

func NewDassUsecase(repo repositories.DassRepository) DassUsecase {
	return &dassUsecase{repo: repo}
}

func (u *dassUsecase) Questionnaire(context.Context) dto.DassQuestionnaireResponse {
	return mapper.ToDassQuestionnaire()
}

func (u *dassUsecase) Submit(ctx context.Context, userID string, req dto.SubmitDassRequest) (dto.DassResultResponse, error) {
	if err := validateDassAnswers(req.Answers); err != nil {
		return dto.DassResultResponse{}, err
	}

	score := service.ScoreDass21(req.Answers)

	result := models.Dass21Result{
		UserID:             userID,
		DepressionScore:    score.Depression.Score,
		AnxietyScore:       score.Anxiety.Score,
		StressScore:        score.Stress.Score,
		DepressionSeverity: score.Depression.Severity,
		AnxietySeverity:    score.Anxiety.Severity,
		StressSeverity:     score.Stress.Severity,
		TakenAt:            apptime.Now(),
	}

	if err := u.repo.Create(ctx, &result); err != nil {
		return dto.DassResultResponse{}, err
	}
	return mapper.ToDassResult(result), nil
}

func (u *dassUsecase) History(ctx context.Context, userID string) (dto.DassHistoryResponse, error) {
	results, err := u.repo.ListByUser(ctx, userID, DassHistoryLimit)
	if err != nil {
		return dto.DassHistoryResponse{}, err
	}
	return mapper.ToDassHistory(results), nil
}

// validateDassAnswers menolak pengisian parsial.
//
// Skor DASS-21 hanya bermakna bila seluruh 21 item terjawab — menerima
// jawaban sebagian akan menghasilkan severity yang terlihat sah padahal
// dihitung dari data yang kurang.
func validateDassAnswers(answers []int) error {
	if len(answers) != service.DassQuestionCount {
		return utils.NewFieldErrors([]utils.FieldError{{
			Field:   "answers",
			Code:    utils.CodeValidationError,
			Message: fmt.Sprintf("Skrining harus diisi lengkap: %d jawaban", service.DassQuestionCount),
			Constraint: map[string]any{
				"required_length": service.DassQuestionCount,
				"received_length": len(answers),
			},
		}})
	}

	for i, value := range answers {
		if value < 0 || value > 3 {
			return utils.NewFieldErrors([]utils.FieldError{{
				Field:   fmt.Sprintf("answers[%d]", i),
				Code:    utils.CodeInvalidEnum,
				Message: "Jawaban hanya boleh bernilai 0 sampai 3",
				Constraint: map[string]any{
					"min": 0,
					"max": 3,
				},
			}})
		}
	}
	return nil
}
