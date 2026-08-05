package mapper

import (
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

func ToDassQuestionnaire() dto.DassQuestionnaireResponse {
	questions := make([]dto.DassQuestionResponse, 0, service.DassQuestionCount)
	for _, q := range service.DassQuestions() {
		questions = append(questions, dto.DassQuestionResponse{
			Number:        q.Number,
			Text:          q.Text,
			Subscale:      string(q.Subscale),
			SubscaleLabel: service.DassSubscaleLabel(q.Subscale),
		})
	}

	options := make([]dto.DassAnswerOptionResponse, 0, len(service.DassAnswerOptions()))
	for _, o := range service.DassAnswerOptions() {
		options = append(options, dto.DassAnswerOptionResponse{Value: o.Value, Label: o.Label})
	}

	return dto.DassQuestionnaireResponse{
		Version:     service.DassInstrumentVersion,
		Instruction: service.DassInstruction,
		Disclaimer:  service.DassDisclaimer,
		Questions:   questions,
		Options:     options,
	}
}

func toDassSubscale(sub service.DassSubscale, score int, severity constants.DassSeverity) dto.DassSubscaleResponse {
	return dto.DassSubscaleResponse{
		Subscale:      string(sub),
		Label:         service.DassSubscaleLabel(sub),
		Score:         score,
		MaxScore:      21 * service.DassScoreMultiplier,
		Severity:      string(severity),
		SeverityLabel: service.DassSeverityLabel(severity),
		IsSevere:      severity.IsSevere(),
	}
}

// ToDassResult menyusun response dari baris tersimpan, sehingga hasil yang
// dibaca ulang dari riwayat identik dengan hasil yang baru dikirim.
func ToDassResult(m models.Dass21Result) dto.DassResultResponse {
	return dto.DassResultResponse{
		ID:         m.ID,
		TakenAt:    apptime.FormatDateTime(m.TakenAt),
		TakenDate:  apptime.FormatDate(m.TakenAt),
		Depression: toDassSubscale(service.SubscaleDepression, m.DepressionScore, m.DepressionSeverity),
		Anxiety:    toDassSubscale(service.SubscaleAnxiety, m.AnxietyScore, m.AnxietySeverity),
		Stress:     toDassSubscale(service.SubscaleStress, m.StressScore, m.StressSeverity),
		TotalScore: m.TotalScore(),
		HasSevere:  m.HasSevere(),
		Disclaimer: service.DassDisclaimer,
		CopingSuggestions: service.DassCopingSuggestions(
			m.DepressionSeverity, m.AnxietySeverity, m.StressSeverity,
		),
	}
}

// ToDassHistory menyusun riwayat + tren.
// results diterima terbaru-lebih-dulu (sesuai urutan repository); Trend
// dibalik agar klien dapat menggambar grafik dari kiri ke kanan.
func ToDassHistory(results []models.Dass21Result) dto.DassHistoryResponse {
	response := dto.DassHistoryResponse{
		Results: make([]dto.DassResultResponse, 0, len(results)),
		Trend:   make([]dto.DassTrendPoint, 0, len(results)),
		Count:   len(results),
	}

	if len(results) == 0 {
		response.ChangeLabel = "Belum ada hasil skrining"
		return response
	}

	for i := range results {
		response.Results = append(response.Results, ToDassResult(results[i]))
	}

	latest := response.Results[0]
	response.Latest = &latest

	for i := len(results) - 1; i >= 0; i-- {
		m := results[i]
		response.Trend = append(response.Trend, dto.DassTrendPoint{
			TakenDate:       apptime.FormatDate(m.TakenAt),
			DepressionScore: m.DepressionScore,
			AnxietyScore:    m.AnxietyScore,
			StressScore:     m.StressScore,
			TotalScore:      m.TotalScore(),
		})
	}

	if len(results) < 2 {
		response.ChangeLabel = "Belum ada pembanding — isi lagi beberapa minggu ke depan"
		return response
	}

	delta := results[0].TotalScore() - results[1].TotalScore()
	response.TotalDelta = &delta
	switch {
	case delta > 0:
		response.ChangeLabel = "Skor naik dibanding skrining sebelumnya"
	case delta < 0:
		response.ChangeLabel = "Skor turun dibanding skrining sebelumnya"
	default:
		response.ChangeLabel = "Skor sama dengan skrining sebelumnya"
	}
	return response
}
