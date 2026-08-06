package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/mapper"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

// JournalUsecase menangani jurnal bebas — KONTEN PRIVAT.
// Setiap method menerima userID dari klaim JWT dan meneruskannya ke repository,
// sehingga tidak ada jalur kode yang dapat membaca jurnal milik orang lain.
type JournalUsecase interface {
	Create(ctx context.Context, userID string, req dto.CreateJournalRequest) (dto.JournalResponse, *dto.AnalysisResponse, error)
	List(ctx context.Context, userID string, p utils.Pagination) ([]dto.JournalListItemResponse, int64, error)
	Detail(ctx context.Context, userID, journalID string) (dto.JournalResponse, error)
	Analyze(ctx context.Context, userID, journalID string) (dto.AnalysisResponse, error)
	Delete(ctx context.Context, userID, journalID string) error
	// EmotionHistory melayani menu "Riwayat Analisis Emosi" di tab Profil.
	EmotionHistory(ctx context.Context, userID string) (dto.EmotionHistoryResponse, error)
	// EmotionDistribution melayani "Sebaran Emosi" di tab Mood (M-MOOD-04).
	// Perhitungannya berbagi kode dengan EmotionHistory lewat
	// mapper.BuildEmotionDistribution — tidak ada logika label emosi kedua.
	EmotionDistribution(ctx context.Context, userID string, periodDays int) (dto.EmotionDistributionResponse, error)
}

// EmotionHistoryLimit membatasi jumlah hasil analisis yang dikirim sekaligus.
// Grafik tren tidak menjadi lebih terbaca di atas angka ini.
const EmotionHistoryLimit = 50

type journalUsecase struct {
	repo     repositories.JournalRepository
	analyzer service.EmotionAnalyzer
	cfg      config.StudentConfig
}

func NewJournalUsecase(repo repositories.JournalRepository, analyzer service.EmotionAnalyzer, cfg config.StudentConfig) JournalUsecase {
	return &journalUsecase{repo: repo, analyzer: analyzer, cfg: cfg}
}

func (u *journalUsecase) Create(ctx context.Context, userID string, req dto.CreateJournalRequest) (dto.JournalResponse, *dto.AnalysisResponse, error) {
	journalDate, err := u.resolveJournalDate(req.JournalDate)
	if err != nil {
		return dto.JournalResponse{}, nil, err
	}

	journal := &models.StudentJournal{
		UserID:      userID,
		Title:       req.Title,
		Content:     req.Content,
		JournalDate: journalDate,
	}
	if err := u.repo.Create(ctx, journal); err != nil {
		return dto.JournalResponse{}, nil, err
	}

	if !req.AnalyzeNow {
		return mapper.ToJournalResponse(journal), nil, nil
	}

	analysis, err := u.applyAnalysis(ctx, journal)
	if err != nil {
		// Jurnal sudah tersimpan; kegagalan analisis tidak boleh menghilangkan tulisan.
		return mapper.ToJournalResponse(journal), nil, err
	}
	return mapper.ToJournalResponse(journal), &analysis, nil
}

func (u *journalUsecase) List(ctx context.Context, userID string, p utils.Pagination) ([]dto.JournalListItemResponse, int64, error) {
	journals, total, err := u.repo.ListByUser(ctx, userID, p)
	if err != nil {
		return nil, 0, err
	}
	return mapper.ToJournalListItems(journals), total, nil
}

func (u *journalUsecase) Detail(ctx context.Context, userID, journalID string) (dto.JournalResponse, error) {
	journal, err := u.repo.FindByIDForUser(ctx, journalID, userID)
	if err != nil {
		return dto.JournalResponse{}, err
	}
	return mapper.ToJournalResponse(journal), nil
}

func (u *journalUsecase) Analyze(ctx context.Context, userID, journalID string) (dto.AnalysisResponse, error) {
	journal, err := u.repo.FindByIDForUser(ctx, journalID, userID)
	if err != nil {
		return dto.AnalysisResponse{}, err
	}
	return u.applyAnalysis(ctx, journal)
}

func (u *journalUsecase) Delete(ctx context.Context, userID, journalID string) error {
	return u.repo.DeleteForUser(ctx, journalID, userID)
}

func (u *journalUsecase) EmotionHistory(ctx context.Context, userID string) (dto.EmotionHistoryResponse, error) {
	journals, err := u.repo.ListAnalyzedByUser(ctx, userID, EmotionHistoryLimit)
	if err != nil {
		return dto.EmotionHistoryResponse{}, err
	}
	return mapper.ToEmotionHistory(journals), nil
}

func (u *journalUsecase) EmotionDistribution(ctx context.Context, userID string, periodDays int) (dto.EmotionDistributionResponse, error) {
	if periodDays <= 0 {
		periodDays = u.cfg.MoodStatsDefaultPeriod
	}
	if periodDays > u.cfg.MoodStatsMaxPeriod {
		periodDays = u.cfg.MoodStatsMaxPeriod
	}

	to := apptime.Today()
	from := apptime.DaysAgo(periodDays - 1)

	counts, err := u.repo.EmotionDistributionForUser(ctx, userID, from, to)
	if err != nil {
		return dto.EmotionDistributionResponse{}, err
	}

	crisisCount, err := u.repo.CountCrisisFlaggedForUserRange(ctx, userID, from, to)
	if err != nil {
		return dto.EmotionDistributionResponse{}, err
	}

	return mapper.ToEmotionDistribution(periodDays, from, to, counts, crisisCount), nil
}

// resolveJournalDate memvalidasi tanggal jurnal terhadap dua batas: tidak boleh
// ke masa depan, dan tidak lebih lama dari MaxBackdateDays (D-8).
//
// Sebelumnya hanya batas "masa depan" yang ditegakkan di sini, sementara D-8
// sudah berlaku untuk check-in mood. Akibatnya jurnal dapat diberi tanggal
// mundur sejauh apa pun — dan karena EWS #2 membaca jurnal, entri lama yang
// dikarang belakangan ikut menggeser indikator. Aturan ini disamakan dengan
// dailyMetricUsecase.resolveMetricDate agar keduanya memakai batas yang sama.
func (u *journalUsecase) resolveJournalDate(raw string) (time.Time, error) {
	today := apptime.Today()
	if raw == "" {
		return today, nil
	}

	parsed, err := apptime.ParseDate(raw)
	if err != nil {
		return time.Time{}, utils.NewError(utils.CodeInvalidDate)
	}
	if parsed.After(today) {
		return time.Time{}, utils.NewError(utils.CodeFutureDateNotAllowed)
	}

	earliest := today.AddDate(0, 0, -u.cfg.MaxBackdateDays)
	if parsed.Before(earliest) {
		return time.Time{}, utils.NewErrorWithMessage(
			utils.CodeBackdateLimitExceeded,
			fmt.Sprintf("Jurnal hanya dapat diberi tanggal mundur maksimal %d hari", u.cfg.MaxBackdateDays),
		)
	}
	return parsed, nil
}

// applyAnalysis menjalankan analisis emosi lalu menyimpan hasilnya.
func (u *journalUsecase) applyAnalysis(ctx context.Context, journal *models.StudentJournal) (dto.AnalysisResponse, error) {
	result := u.analyzer.Analyze(journal.Content)
	now := apptime.Now()

	journal.EmotionLabel = result.EmotionLabel
	journal.EmotionConfidence = ptr(result.EmotionConfidence)
	journal.SentimentScore = ptr(result.SentimentScore)
	journal.IsCrisisFlagged = result.IsCrisisFlagged
	journal.AnalyzedAt = &now

	if err := u.repo.UpdateAnalysis(ctx, journal); err != nil {
		return dto.AnalysisResponse{}, err
	}

	return dto.AnalysisResponse{
		JournalID:         journal.ID,
		EmotionLabel:      result.EmotionLabel,
		EmotionLabelText:  service.EmotionLabelText(result.EmotionLabel),
		EmotionConfidence: result.EmotionConfidence,
		SentimentScore:    result.SentimentScore,
		IsCrisisFlagged:   result.IsCrisisFlagged,
		CopingSuggestions: result.CopingSuggestions,
		CrisisMessage:     result.CrisisMessage,
		AnalyzedAt:        apptime.FormatDateTime(now),
		ModelVersion:      service.ModelVersion,
	}, nil
}

func ptr[T any](v T) *T { return &v }
