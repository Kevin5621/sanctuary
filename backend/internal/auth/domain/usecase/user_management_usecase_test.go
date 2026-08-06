package usecase

import (
	"context"
	"testing"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/auth/domain/dto"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

func boolPtr(v bool) *bool { return &v }

func newUserManagement(users *fakeUserRepo) (UserManagementUsecase, *fakeTokenRepo, *fakeAuditRepo) {
	tokens := &fakeTokenRepo{}
	audits := &fakeAuditRepo{}
	uc := NewUserManagementUsecase(users, &fakeRoleRepo{}, &fakeProgramRepo{}, tokens, audits)
	return uc, tokens, audits
}

func validStaffRequest() dto.CreateStaffUserRequest {
	return dto.CreateStaffUserRequest{
		FullName:       "Dr. Sinta Pembimbing",
		Email:          "sinta@sanctuary.ac.id",
		Password:       "rahasia123",
		Role:           constants.RoleLecturer.String(),
		LecturerNumber: "0011224402",
		StudyProgramID: testProgramID,
		IsActive:       boolPtr(true),
	}
}

func staffUser(id string, role constants.Role) *models.User {
	user := &models.User{
		FullName: "Akun " + id,
		Email:    id + "@sanctuary.ac.id",
		Role:     &models.Role{Code: role.String()},
		IsActive: true,
	}
	user.ID = id
	return user
}

func TestCreateStaff_CreatesLecturerWithHashedPassword(t *testing.T) {
	users := newFakeUserRepo()
	uc, _, audits := newUserManagement(users)

	res, err := uc.Create(context.Background(), validStaffRequest(), ActorMeta{ActorID: "admin-1"})
	if err != nil {
		t.Fatalf("create gagal: %v", err)
	}

	if len(users.created) != 1 {
		t.Fatalf("jumlah akun dibuat = %d, want 1", len(users.created))
	}
	created := users.created[0]
	if created.PasswordHash == "" || created.PasswordHash == "rahasia123" {
		t.Error("kata sandi wajib tersimpan sebagai hash")
	}
	if created.StudentNumber != nil || created.CohortYear != nil {
		t.Error("akun dosen tidak boleh membawa atribut mahasiswa")
	}
	if res.Role != constants.RoleLecturer.String() {
		t.Errorf("peran hasil = %q, want %s", res.Role, constants.RoleLecturer)
	}
	if len(audits.entries) != 1 || audits.entries[0].Action != models.ActionCreateUser {
		t.Error("pembuatan akun wajib terekam pada audit log")
	}
}

// Batas peran ditegakkan di usecase, bukan hanya di UI: satu akun admin yang
// bocor tidak boleh dapat memperbanyak dirinya sendiri lewat API.
func TestCreateStaff_RejectsNonStaffRoles(t *testing.T) {
	for _, role := range []constants.Role{constants.RoleAdmin, constants.RoleStudent} {
		t.Run(role.String(), func(t *testing.T) {
			users := newFakeUserRepo()
			uc, _, _ := newUserManagement(users)

			req := validStaffRequest()
			req.Role = role.String()

			_, err := uc.Create(context.Background(), req, ActorMeta{ActorID: "admin-1"})

			if errorCode(err) != utils.CodeRoleNotAssignable {
				t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeRoleNotAssignable)
			}
			if len(users.created) != 0 {
				t.Error("tidak boleh ada akun terbuat untuk peran di luar kelola akun")
			}
		})
	}
}

func TestCreateStaff_RejectsDuplicateLecturerNumber(t *testing.T) {
	users := newFakeUserRepo()
	users.numberTaken = true
	uc, _, _ := newUserManagement(users)

	_, err := uc.Create(context.Background(), validStaffRequest(), ActorMeta{ActorID: "admin-1"})

	if errorCode(err) != utils.CodeLecturerNumberRegistered {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeLecturerNumberRegistered)
	}
}

// Akun "dinonaktifkan" yang token-nya masih sah adalah kegagalan keamanan,
// bukan sekadar keterlambatan tampilan.
func TestUpdateStaff_DeactivationRevokesActiveSessions(t *testing.T) {
	users := newFakeUserRepo()
	users.byID["dosen-1"] = staffUser("dosen-1", constants.RoleLecturer)
	uc, tokens, _ := newUserManagement(users)

	_, err := uc.Update(context.Background(), "dosen-1", dto.UpdateStaffUserRequest{
		FullName:       "Dr. Sinta Pembimbing",
		StudyProgramID: testProgramID,
		IsActive:       boolPtr(false),
	}, ActorMeta{ActorID: "admin-1"})
	if err != nil {
		t.Fatalf("update gagal: %v", err)
	}

	if len(tokens.revokedFor) != 1 || tokens.revokedFor[0] != "dosen-1" {
		t.Error("menonaktifkan akun harus mencabut seluruh sesi aktifnya")
	}
}

func TestUpdateStaff_PasswordResetRevokesActiveSessions(t *testing.T) {
	users := newFakeUserRepo()
	users.byID["dosen-1"] = staffUser("dosen-1", constants.RoleLecturer)
	uc, tokens, _ := newUserManagement(users)

	_, err := uc.Update(context.Background(), "dosen-1", dto.UpdateStaffUserRequest{
		FullName:       "Dr. Sinta Pembimbing",
		StudyProgramID: testProgramID,
		IsActive:       boolPtr(true),
		Password:       "sandibaru123",
	}, ActorMeta{ActorID: "admin-1"})
	if err != nil {
		t.Fatalf("update gagal: %v", err)
	}

	if users.updated["password_hash"] == nil {
		t.Error("kata sandi baru harus ikut tersimpan")
	}
	if len(tokens.revokedFor) != 1 {
		t.Error("menyetel ulang kata sandi harus mencabut sesi lama")
	}
}

// Membedakan "bukan staf" dari "tidak ada" akan membocorkan peran akun yang
// memang tidak boleh disentuh dari halaman ini.
func TestUpdateStaff_RejectsNonStaffTargetAsNotFound(t *testing.T) {
	users := newFakeUserRepo()
	users.byID["mhs-1"] = staffUser("mhs-1", constants.RoleStudent)
	uc, _, _ := newUserManagement(users)

	_, err := uc.Update(context.Background(), "mhs-1", dto.UpdateStaffUserRequest{
		FullName:       "Nama Baru",
		StudyProgramID: testProgramID,
		IsActive:       boolPtr(true),
	}, ActorMeta{ActorID: "admin-1"})

	if errorCode(err) != utils.CodeUserNotFound {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeUserNotFound)
	}
}

func TestList_RejectsRoleFilterOutsideStaffRoles(t *testing.T) {
	uc, _, _ := newUserManagement(newFakeUserRepo())

	_, _, err := uc.List(context.Background(), utils.Pagination{Page: 1, PerPage: 20},
		constants.RoleStudent.String(), nil)

	if errorCode(err) != utils.CodeInvalidEnum {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeInvalidEnum)
	}
}
