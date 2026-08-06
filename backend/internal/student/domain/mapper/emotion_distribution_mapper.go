package mapper

import (
	"sort"
	"time"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
)

// ------------------------------------------------------------------
// Sebaran emosi — SATU perhitungan, dua layar.
//
// M-PRO-02 (Riwayat Analisis Emosi, tab Profil) dan M-MOOD-04 (Sebaran Emosi,
// tab Mood) menampilkan angka yang sama dari sumber yang sama. Karena itu
// keduanya memanggil BuildEmotionDistribution, bukan menghitung sendiri-sendiri.
//
// Kalau logikanya digandakan, dua layar dalam satu aplikasi bisa menyebutkan
// persentase yang berbeda untuk data yang identik — dan mahasiswa tidak punya
// cara untuk tahu mana yang benar.
//
// Yang TIDAK disatukan adalah bentuk endpoint-nya, dan itu disengaja:
// M-PRO-02 mengirim daftar item beserta preview tulisan, sedangkan M-MOOD-04
// hanya butuh angka. Memakai ulang endpoint riwayat untuk grafik akan mengirim
// cuplikan jurnal ke layar yang sama sekali tidak menampilkannya — teks privat
// yang dikirim tanpa keperluan adalah permukaan kebocoran yang bisa dihindari.
// ------------------------------------------------------------------

// EmotionDistributionSummary adalah hasil olahan yang dipakai bersama.
type EmotionDistributionSummary struct {
	Distribution        []dto.EmotionShareResponse
	DominantEmotion     string
	DominantEmotionText string
	// NegativeRatio dalam skala 0..1 (bukan persen), mengikuti ambang EWS #2.
	NegativeRatio float64
	// Labeled adalah jumlah jurnal yang benar-benar punya label.
	Labeled int
}

// BuildEmotionDistribution mengubah hitungan per label menjadi sebaran siap
// tampil, terurut dari yang terbanyak.
//
// D-2: label yang muncul di sini adalah label yang BENAR-BENAR dihasilkan
// analyzer atas tulisan jurnal. Tidak ada label yang disuntikkan dari opsi
// check-in mood manual, dan tidak ada penggabungan diam-diam — sebuah irisan
// pada grafik selalu berarti "sekian jurnal diberi label ini oleh model".
func BuildEmotionDistribution(counts map[string]int) EmotionDistributionSummary {
	summary := EmotionDistributionSummary{
		Distribution: []dto.EmotionShareResponse{},
	}

	negative := 0
	for label, count := range counts {
		if label == "" {
			continue
		}
		summary.Labeled += count
		if constants.IsNegativeEmotion(label) {
			negative += count
		}
	}
	if summary.Labeled == 0 {
		return summary
	}

	distribution := make([]dto.EmotionShareResponse, 0, len(counts))
	for label, count := range counts {
		if label == "" {
			continue
		}
		distribution = append(distribution, dto.EmotionShareResponse{
			Emotion:    label,
			Label:      service.EmotionLabelText(label),
			Count:      count,
			Percentage: percentage(count, summary.Labeled),
			IsNegative: constants.IsNegativeEmotion(label),
		})
	}

	// Urutan stabil: jumlah terbanyak dulu, lalu alfabetis agar dua label
	// berjumlah sama tidak bertukar posisi antar request.
	sort.Slice(distribution, func(i, j int) bool {
		if distribution[i].Count != distribution[j].Count {
			return distribution[i].Count > distribution[j].Count
		}
		return distribution[i].Emotion < distribution[j].Emotion
	})

	summary.Distribution = distribution
	summary.DominantEmotion = distribution[0].Emotion
	summary.DominantEmotionText = distribution[0].Label
	summary.NegativeRatio = percentage(negative, summary.Labeled) / 100
	return summary
}

// ToEmotionDistribution menyusun respons M-MOOD-04.
//
// Perhatikan bahwa fungsi ini menerima []EmotionCount (hasil GROUP BY di SQL),
// bukan daftar jurnal: tulisan mahasiswa tidak pernah ikut masuk ke jalur ini.
func ToEmotionDistribution(periodDays int, from, to time.Time, counts []repositories.EmotionCount, crisisCount int64) dto.EmotionDistributionResponse {
	grouped := make(map[string]int, len(counts))
	for _, c := range counts {
		grouped[c.EmotionLabel] += c.Total
	}

	summary := BuildEmotionDistribution(grouped)

	response := dto.EmotionDistributionResponse{
		PeriodDays:          periodDays,
		From:                from.Format(apptime.LayoutDate),
		To:                  to.Format(apptime.LayoutDate),
		Distribution:        summary.Distribution,
		TotalAnalyzed:       summary.Labeled,
		CrisisFlaggedCount:  int(crisisCount),
		DominantEmotion:     summary.DominantEmotion,
		DominantEmotionText: summary.DominantEmotionText,
		NegativeRatio:       summary.NegativeRatio,
		ModelVersion:        service.ModelVersion,
	}

	// Empty state yang jujur (bukan grafik kosong): bedakan "belum menulis
	// jurnal sama sekali" dari "sudah menulis tapi belum ditekan Analisis".
	if summary.Labeled == 0 {
		response.IsEmpty = true
		response.Message = "Belum ada jurnal yang dianalisis pada rentang ini. " +
			"Tulis catatan lalu tekan Analisis Emosi untuk mulai melihat sebarannya."
	}
	return response
}
