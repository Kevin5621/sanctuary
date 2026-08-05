package mapper

import (
	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/auth/domain/dto"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
)

func ToUserResponse(m *models.User) dto.UserResponse {
	role := constants.Role(m.RoleCode())

	res := dto.UserResponse{
		ID:             m.ID,
		FullName:       m.FullName,
		Email:          m.Email,
		Phone:          m.Phone,
		AvatarURL:      m.AvatarURL,
		Role:           role.String(),
		RoleLabel:      role.DisplayName(),
		TabCount:       role.TabCount(),
		StudentNumber:  m.StudentNumber,
		LecturerNumber: m.LecturerNumber,
		CohortYear:     m.CohortYear,
		AdvisorID:      m.AdvisorID,
		StudyProgramID: m.StudyProgramID,
		IsActive:       m.IsActive,
		LastLoginAt:    apptime.FormatDateTimePtr(m.LastLoginAt),
	}
	if m.StudyProgram != nil {
		name := m.StudyProgram.Name
		res.StudyProgram = &name
	}
	return res
}
