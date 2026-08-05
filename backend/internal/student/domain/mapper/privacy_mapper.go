package mapper

import (
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

var shareLevelLabel = map[constants.ShareLevel]string{
	constants.ShareLevelClosed:       "Tertutup",
	constants.ShareLevelSummary:      "Ringkasan",
	constants.ShareLevelSummaryTrend: "Ringkasan + Tren",
}

var shareLevelEffect = map[constants.ShareLevel]string{
	constants.ShareLevelClosed:       "Pembimbing tidak melihat data kondisimu sama sekali.",
	constants.ShareLevelSummary:      "Pembimbing hanya melihat indikator kondisi, tanpa grafik tren.",
	constants.ShareLevelSummaryTrend: "Pembimbing melihat indikator kondisi dan grafik tren mingguan.",
}

func ToPrivacySettingResponse(m *models.StudentPrivacySetting) dto.PrivacySettingResponse {
	return dto.PrivacySettingResponse{
		ShareLevel:            m.ShareLevel.String(),
		ShareLevelLabel:       shareLevelLabel[m.ShareLevel],
		Effect:                shareLevelEffect[m.ShareLevel],
		AllowEarlyWarning:     m.AllowEarlyWarning,
		AllowProgramStatistic: m.AllowProgramStatistic,

		AdvisorCanSeeIndicator: m.CanShareIndicator(),
		AdvisorCanSeeTrend:     m.CanShareTrend(),
		AdvisorCanGetAlert:     m.CanSendEarlyWarning(),

		UpdatedAt: apptime.FormatDateTime(m.UpdatedAt),
	}
}

// ShareLevelOptions adalah sumber tunggal daftar pilihan untuk klien.
func ShareLevelOptions() []dto.PrivacyOptionResponse {
	options := make([]dto.PrivacyOptionResponse, 0, len(constants.AllShareLevels))
	for _, level := range constants.AllShareLevels {
		options = append(options, dto.PrivacyOptionResponse{
			Value:       level.String(),
			Label:       shareLevelLabel[level],
			Description: shareLevelEffect[level],
		})
	}
	return options
}
