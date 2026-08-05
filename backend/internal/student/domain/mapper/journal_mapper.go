package mapper

import (
	"sort"
	"strings"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
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
			ID:               items[i].ID,
			Title:            items[i].Title,
			Preview:          preview(items[i].Content),
			JournalDate:      apptime.FormatDate(items[i].JournalDate),
			EmotionLabel:     items[i].EmotionLabel,
			EmotionLabelText: emotionText(items[i].EmotionLabel),
			IsCrisisFlagged:  items[i].IsCrisisFlagged,
			AnalyzedAt:       apptime.FormatDateTimePtr(items[i].AnalyzedAt),
		})
	}
	return out
}

// emotionText mengosongkan teks bila jurnal belum dianalisis, sehingga klien
// tidak menampilkan "Netral" untuk catatan yang sebenarnya belum diperiksa.
func emotionText(label string) string {
	if label == "" {
		return ""
	}
	return service.EmotionLabelText(label)
}

// ToEmotionHistory menyusun layar "Riwayat Analisis Emosi".
//
// journals diterima terbaru-lebih-dulu. Trend dibalik agar klien menggambar
// grafik dari kiri (lama) ke kanan (baru) tanpa memproses ulang.
func ToEmotionHistory(journals []models.StudentJournal) dto.EmotionHistoryResponse {
	response := dto.EmotionHistoryResponse{
		Items:         make([]dto.EmotionHistoryItemResponse, 0, len(journals)),
		Trend:         make([]dto.EmotionTrendPointResponse, 0, len(journals)),
		TotalAnalyzed: len(journals),
		ModelVersion:  service.ModelVersion,
	}

	if len(journals) == 0 {
		response.Message = "Belum ada jurnal yang dianalisis. Tulis catatan lalu tekan Analisis Emosi."
		return response
	}

	counts := map[string]int{}
	negative := 0

	for i := range journals {
		j := journals[i]

		confidence, sentiment := 0.0, 0.0
		if j.EmotionConfidence != nil {
			confidence = *j.EmotionConfidence
		}
		if j.SentimentScore != nil {
			sentiment = *j.SentimentScore
		}

		response.Items = append(response.Items, dto.EmotionHistoryItemResponse{
			JournalID:         j.ID,
			Title:             j.Title,
			Preview:           preview(j.Content),
			JournalDate:       apptime.FormatDate(j.JournalDate),
			AnalyzedAt:        apptime.FormatDateTime(*j.AnalyzedAt),
			EmotionLabel:      j.EmotionLabel,
			EmotionLabelText:  emotionText(j.EmotionLabel),
			EmotionConfidence: confidence,
			SentimentScore:    sentiment,
			IsCrisisFlagged:   j.IsCrisisFlagged,
			CopingSuggestions: service.CopingFor(j.EmotionLabel),
		})

		if j.EmotionLabel != "" {
			counts[j.EmotionLabel]++
			if constants.IsNegativeEmotion(j.EmotionLabel) {
				negative++
			}
		}
		if j.IsCrisisFlagged {
			response.CrisisFlaggedCount++
		}
	}

	for i := len(response.Items) - 1; i >= 0; i-- {
		item := response.Items[i]
		response.Trend = append(response.Trend, dto.EmotionTrendPointResponse{
			Date:             item.JournalDate,
			SentimentScore:   item.SentimentScore,
			EmotionLabel:     item.EmotionLabel,
			EmotionLabelText: item.EmotionLabelText,
		})
	}

	labeled := 0
	for _, count := range counts {
		labeled += count
	}
	if labeled == 0 {
		response.Message = "Hasil analisis belum memiliki label emosi."
		return response
	}

	distribution := make([]dto.EmotionShareResponse, 0, len(counts))
	for emotion, count := range counts {
		distribution = append(distribution, dto.EmotionShareResponse{
			Emotion:    emotion,
			Label:      service.EmotionLabelText(emotion),
			Count:      count,
			Percentage: percentage(count, labeled),
			IsNegative: constants.IsNegativeEmotion(emotion),
		})
	}
	sort.Slice(distribution, func(i, j int) bool {
		if distribution[i].Count != distribution[j].Count {
			return distribution[i].Count > distribution[j].Count
		}
		return distribution[i].Emotion < distribution[j].Emotion
	})

	response.Distribution = distribution
	response.DominantEmotion = distribution[0].Emotion
	response.DominantEmotionText = distribution[0].Label
	response.NegativeRatio = percentage(negative, labeled) / 100

	// Ambang yang sama dipakai statistik mood: satu-dua hasil belum membentuk
	// pola, dan menyebutnya "tren" akan melebih-lebihkan apa yang diketahui.
	if len(journals) < service.MoodStatsMinPoints {
		response.Message = "Analisis masih sedikit — pola emosimu akan terlihat setelah beberapa catatan lagi."
		return response
	}

	response.IsSufficient = true
	return response
}

func percentage(part, total int) float64 {
	if total == 0 {
		return 0
	}
	return float64(int(float64(part)/float64(total)*10000+0.5)) / 100
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
