package usecase

import (
	"context"
	"log"
	"strings"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/auth/domain/dto"
	"github.com/gilabs/sanctuary/internal/auth/domain/mapper"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// ActorMeta adalah identitas Admin yang melakukan aksi, dipakai audit log.
type ActorMeta struct {
	ActorID   string
	IPAddress string
	RequestID string
}

// UserManagementUsecase — pembuatan & pemeliharaan akun dosen dan kaprodi
// oleh Admin (A-AKN-01..03).
//
// Batasnya ditegakkan di sini, bukan hanya di UI: peran di luar
// constants.StaffRoles ditolak, sehingga endpoint ini tidak dapat dipakai
// membuat akun Admin baru maupun menyelipkan akun mahasiswa palsu yang
// melewati alur pendaftaran.
type UserManagementUsecase interface {
	List(ctx context.Context, p utils.Pagination, roleFilter string, activeOnly *bool) ([]dto.ManagedUserResponse, int64, error)
	Get(ctx context.Context, id string) (dto.ManagedUserResponse, error)
	Create(ctx context.Context, req dto.CreateStaffUserRequest, actor ActorMeta) (dto.ManagedUserResponse, error)
	Update(ctx context.Context, id string, req dto.UpdateStaffUserRequest, actor ActorMeta) (dto.ManagedUserResponse, error)
	RoleOptions() []dto.RoleOptionResponse
	StudyPrograms(ctx context.Context) ([]dto.StudyProgramResponse, error)
}

type userManagementUsecase struct {
	users    repositories.UserRepository
	roles    repositories.RoleRepository
	programs repositories.StudyProgramRepository
	tokens   repositories.RefreshTokenRepository
	audits   repositories.AuditRepository
}

func NewUserManagementUsecase(
	users repositories.UserRepository,
	roles repositories.RoleRepository,
	programs repositories.StudyProgramRepository,
	tokens repositories.RefreshTokenRepository,
	audits repositories.AuditRepository,
) UserManagementUsecase {
	return &userManagementUsecase{
		users:    users,
		roles:    roles,
		programs: programs,
		tokens:   tokens,
		audits:   audits,
	}
}

func (u *userManagementUsecase) List(
	ctx context.Context,
	p utils.Pagination,
	roleFilter string,
	activeOnly *bool,
) ([]dto.ManagedUserResponse, int64, error) {
	filter := repositories.UserFilter{
		RoleCodes:  staffRoleCodes(),
		Search:     p.Search,
		ActiveOnly: activeOnly,
	}

	// Filter peran dari klien hanya boleh mempersempit daftar, tidak pernah
	// memperluasnya ke peran di luar kelola akun.
	if roleFilter != "" {
		if !constants.IsStaffRole(roleFilter) {
			return nil, 0, utils.NewError(utils.CodeInvalidEnum).WithDetails(map[string]any{
				"field":   "role",
				"allowed": staffRoleCodes(),
			})
		}
		filter.RoleCodes = []string{roleFilter}
	}

	users, total, err := u.users.List(ctx, p, filter)
	if err != nil {
		return nil, 0, err
	}
	return mapper.ToManagedUserResponses(users), total, nil
}

func (u *userManagementUsecase) Get(ctx context.Context, id string) (dto.ManagedUserResponse, error) {
	user, err := u.loadStaff(ctx, id)
	if err != nil {
		return dto.ManagedUserResponse{}, err
	}
	return mapper.ToManagedUserResponse(user), nil
}

func (u *userManagementUsecase) Create(
	ctx context.Context,
	req dto.CreateStaffUserRequest,
	actor ActorMeta,
) (dto.ManagedUserResponse, error) {
	if !constants.IsStaffRole(req.Role) {
		return dto.ManagedUserResponse{}, utils.NewError(utils.CodeRoleNotAssignable).WithDetails(map[string]any{
			"field":   "role",
			"allowed": staffRoleCodes(),
		})
	}

	email := strings.ToLower(strings.TrimSpace(req.Email))
	if taken, err := u.users.EmailTaken(ctx, email, ""); err != nil {
		return dto.ManagedUserResponse{}, err
	} else if taken {
		return dto.ManagedUserResponse{}, utils.NewError(utils.CodeEmailAlreadyRegistered)
	}

	lecturerNumber := strings.TrimSpace(req.LecturerNumber)
	if lecturerNumber != "" {
		if taken, err := u.users.LecturerNumberTaken(ctx, lecturerNumber, ""); err != nil {
			return dto.ManagedUserResponse{}, err
		} else if taken {
			return dto.ManagedUserResponse{}, utils.NewError(utils.CodeLecturerNumberRegistered)
		}
	}

	program, err := u.programs.FindByID(ctx, req.StudyProgramID)
	if err != nil {
		return dto.ManagedUserResponse{}, err
	}

	role, err := u.roles.FindByCode(ctx, constants.Role(req.Role))
	if err != nil {
		return dto.ManagedUserResponse{}, err
	}

	hash, err := utils.HashPassword(req.Password)
	if err != nil {
		return dto.ManagedUserResponse{}, utils.WrapInternal(err)
	}

	user := &models.User{
		RoleID:         role.ID,
		Role:           role,
		FullName:       strings.TrimSpace(req.FullName),
		Email:          email,
		PasswordHash:   hash,
		Phone:          strings.TrimSpace(req.Phone),
		LecturerNumber: optionalString(lecturerNumber),
		StudyProgramID: &program.ID,
		StudyProgram:   program,
		IsActive:       *req.IsActive,
	}

	if err := u.users.Create(ctx, user); err != nil {
		return dto.ManagedUserResponse{}, translateIdentityConflict(err)
	}

	u.recordAudit(ctx, repositories.AuditEntry{
		ActorID:    actor.ActorID,
		ActorRole:  constants.RoleAdmin.String(),
		Action:     models.ActionCreateUser,
		Resource:   "user",
		ResourceID: user.ID,
		Metadata:   map[string]any{"role": role.Code},
		IPAddress:  actor.IPAddress,
		RequestID:  actor.RequestID,
	})
	return mapper.ToManagedUserResponse(user), nil
}

func (u *userManagementUsecase) Update(
	ctx context.Context,
	id string,
	req dto.UpdateStaffUserRequest,
	actor ActorMeta,
) (dto.ManagedUserResponse, error) {
	existing, err := u.loadStaff(ctx, id)
	if err != nil {
		return dto.ManagedUserResponse{}, err
	}

	lecturerNumber := strings.TrimSpace(req.LecturerNumber)
	if lecturerNumber != "" {
		if taken, err := u.users.LecturerNumberTaken(ctx, lecturerNumber, id); err != nil {
			return dto.ManagedUserResponse{}, err
		} else if taken {
			return dto.ManagedUserResponse{}, utils.NewError(utils.CodeLecturerNumberRegistered)
		}
	}

	program, err := u.programs.FindByID(ctx, req.StudyProgramID)
	if err != nil {
		return dto.ManagedUserResponse{}, err
	}

	// Email sengaja tidak dapat diubah: ia adalah identitas login sekaligus
	// kunci jejak audit yang sudah tercatat atas nama akun tersebut.
	fields := map[string]any{
		"full_name":        strings.TrimSpace(req.FullName),
		"phone":            strings.TrimSpace(req.Phone),
		"lecturer_number":  optionalString(lecturerNumber),
		"study_program_id": program.ID,
		"is_active":        *req.IsActive,
	}

	passwordChanged := req.Password != ""
	if passwordChanged {
		hash, err := utils.HashPassword(req.Password)
		if err != nil {
			return dto.ManagedUserResponse{}, utils.WrapInternal(err)
		}
		fields["password_hash"] = hash
	}

	if err := u.users.Update(ctx, existing, fields); err != nil {
		return dto.ManagedUserResponse{}, translateIdentityConflict(err)
	}

	// Menonaktifkan akun atau menyetel ulang kata sandi harus benar-benar
	// mengusir sesi yang sedang berjalan. Tanpa ini, access token yang sudah
	// terbit tetap sah sampai kedaluwarsa — akun "dinonaktifkan" yang masih
	// bisa membuka data bimbingan adalah kegagalan keamanan, bukan sekadar
	// keterlambatan tampilan.
	if passwordChanged || !*req.IsActive {
		if err := u.tokens.RevokeAllForUser(ctx, nil, id, apptime.Now()); err != nil {
			return dto.ManagedUserResponse{}, err
		}
	}

	updated, err := u.loadStaff(ctx, id)
	if err != nil {
		return dto.ManagedUserResponse{}, err
	}

	u.recordAudit(ctx, repositories.AuditEntry{
		ActorID:    actor.ActorID,
		ActorRole:  constants.RoleAdmin.String(),
		Action:     models.ActionUpdateUser,
		Resource:   "user",
		ResourceID: id,
		Metadata: map[string]any{
			"is_active":        *req.IsActive,
			"password_changed": passwordChanged,
		},
		IPAddress: actor.IPAddress,
		RequestID: actor.RequestID,
	})
	return mapper.ToManagedUserResponse(updated), nil
}

func (u *userManagementUsecase) RoleOptions() []dto.RoleOptionResponse {
	return mapper.StaffRoleOptions()
}

func (u *userManagementUsecase) StudyPrograms(ctx context.Context) ([]dto.StudyProgramResponse, error) {
	programs, err := u.programs.List(ctx)
	if err != nil {
		return nil, err
	}
	return mapper.ToStudyProgramResponses(programs), nil
}

// loadStaff menolak id milik mahasiswa maupun admin lain, sehingga endpoint
// kelola akun tidak dapat dipakai menyunting akun di luar cakupannya.
func (u *userManagementUsecase) loadStaff(ctx context.Context, id string) (*models.User, error) {
	user, err := u.users.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if !constants.IsStaffRole(user.RoleCode()) {
		// Sengaja NOT_FOUND, bukan FORBIDDEN: membedakan keduanya akan
		// memberitahu peran akun yang tidak boleh disentuh dari halaman ini.
		return nil, utils.NewError(utils.CodeUserNotFound)
	}
	return user, nil
}

func (u *userManagementUsecase) recordAudit(ctx context.Context, entry repositories.AuditEntry) {
	if err := u.audits.Record(ctx, entry); err != nil {
		log.Printf("[audit] failed action=%s actor=%s err=%v", entry.Action, entry.ActorID, err)
	}
}

func staffRoleCodes() []string {
	out := make([]string, 0, len(constants.StaffRoles))
	for _, r := range constants.StaffRoles {
		out = append(out, r.String())
	}
	return out
}

func optionalString(value string) *string {
	if value == "" {
		return nil
	}
	return &value
}
