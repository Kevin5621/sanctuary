package mapper

import (
	"strings"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

const journalPreviewLength = 120

func ToJournalResponse(m *models.StudentJournal) dto.JournalResponse {
	return dto.JournalResponse{
		ID:                m.ID,
		Title:             m.Title,
		Content:           m.Content,
		JournalDate:       apptime.FormatDate(m.JournalDate),
		EmotionLabel:      m.EmotionLabel,
		EmotionConfidence: m.EmotionConfidence,
		SentimentScore:    m.SentimentScore,
		IsCrisisFlagged:   m.IsCrisisFlagged,
		AnalyzedAt:        apptime.FormatDateTimePtr(m.AnalyzedAt),
		CreatedAt:         apptime.FormatDateTime(m.CreatedAt),
	}
}

func ToJournalListItems(items []models.StudentJournal) []dto.JournalListItemResponse {
	out := make([]dto.JournalListItemResponse, 0, len(items))
	for i := range items {
		out = append(out, dto.JournalListItemResponse{
			ID:              items[i].ID,
			Title:           items[i].Title,
			Preview:         preview(items[i].Content),
			JournalDate:     apptime.FormatDate(items[i].JournalDate),
			EmotionLabel:    items[i].EmotionLabel,
			IsCrisisFlagged: items[i].IsCrisisFlagged,
			AnalyzedAt:      apptime.FormatDateTimePtr(items[i].AnalyzedAt),
		})
	}
	return out
}

// preview memotong konten pada batas kata agar daftar tetap ringan.
func preview(content string) string {
	trimmed := strings.TrimSpace(strings.ReplaceAll(content, "\n", " "))
	if len(trimmed) <= journalPreviewLength {
		return trimmed
	}
	cut := trimmed[:journalPreviewLength]
	if idx := strings.LastIndex(cut, " "); idx > 60 {
		cut = cut[:idx]
	}
	return cut + "…"
}
