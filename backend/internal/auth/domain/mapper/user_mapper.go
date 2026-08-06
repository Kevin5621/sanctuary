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

// ToManagedUserResponse dipakai halaman kelola akun Admin.
func ToManagedUserResponse(m *models.User) dto.ManagedUserResponse {
	role := constants.Role(m.RoleCode())

	res := dto.ManagedUserResponse{
		ID:             m.ID,
		FullName:       m.FullName,
		Email:          m.Email,
		Phone:          m.Phone,
		Role:           role.String(),
		RoleLabel:      role.DisplayName(),
		LecturerNumber: m.LecturerNumber,
		StudyProgramID: m.StudyProgramID,
		IsActive:       m.IsActive,
		LastLoginAt:    apptime.FormatDateTimePtr(m.LastLoginAt),
		CreatedAt:      apptime.FormatDateTime(m.CreatedAt),
	}
	if m.StudyProgram != nil {
		name := m.StudyProgram.Name
		res.StudyProgram = &name
	}
	return res
}

func ToManagedUserResponses(items []models.User) []dto.ManagedUserResponse {
	out := make([]dto.ManagedUserResponse, 0, len(items))
	for i := range items {
		out = append(out, ToManagedUserResponse(&items[i]))
	}
	return out
}

func ToStudyProgramResponse(m *models.StudyProgram) dto.StudyProgramResponse {
	return dto.StudyProgramResponse{
		ID:      m.ID,
		Code:    m.Code,
		Name:    m.Name,
		Faculty: m.Faculty,
	}
}

func ToStudyProgramResponses(items []models.StudyProgram) []dto.StudyProgramResponse {
	out := make([]dto.StudyProgramResponse, 0, len(items))
	for i := range items {
		out = append(out, ToStudyProgramResponse(&items[i]))
	}
	return out
}

// StaffRoleOptions adalah daftar peran yang boleh dibuat Admin.
func StaffRoleOptions() []dto.RoleOptionResponse {
	out := make([]dto.RoleOptionResponse, 0, len(constants.StaffRoles))
	for _, r := range constants.StaffRoles {
		out = append(out, dto.RoleOptionResponse{Value: r.String(), Label: r.DisplayName()})
	}
	return out
}
