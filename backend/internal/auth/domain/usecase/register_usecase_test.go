package usecase

import (
	"context"
	"testing"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/auth/domain/dto"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

func validRegisterRequest() dto.RegisterStudentRequest {
	return dto.RegisterStudentRequest{
		FullName:             "Alya Prameswari",
		Email:                "  Alya@Sanctuary.ac.id ",
		Password:             "rahasia123",
		PasswordConfirmation: "rahasia123",
		StudentNumber:        "220001",
		CohortYear:           2022,
		StudyProgramID:       testProgramID,
	}
}

func newRegisterUsecase(users *fakeUserRepo, limiter RateLimiter) (AuthUsecase, *fakeAuditRepo) {
	audits := &fakeAuditRepo{}
	uc := NewAuthUsecase(
		nil, users, &fakeTokenRepo{}, audits, &fakeRoleRepo{}, &fakeProgramRepo{},
		testJWT(), limiter, testConfig(),
	)
	return uc, audits
}

func TestRegister_CreatesStudentAndIssuesSession(t *testing.T) {
	users := newFakeUserRepo()
	uc, audits := newRegisterUsecase(users, allowAllLimiter{})

	result, err := uc.Register(context.Background(), validRegisterRequest(), LoginMeta{})
	if err != nil {
		t.Fatalf("register gagal: %v", err)
	}

	if len(users.created) != 1 {
		t.Fatalf("jumlah akun dibuat = %d, want 1", len(users.created))
	}
	created := users.created[0]

	// Peran pendaftar tidak boleh berasal dari input: satu-satunya jalan
	// menjadi dosen/kaprodi adalah dibuatkan Admin.
	if created.RoleID != "role-"+constants.RoleStudent.String() {
		t.Errorf("role akun baru = %q, want peran mahasiswa", created.RoleID)
	}
	// Pembimbing adalah keputusan prodi — menebaknya berarti mengalirkan data
	// mahasiswa ke dosen yang belum tentu berhak.
	if created.AdvisorID != nil {
		t.Error("pendaftar baru tidak boleh langsung punya dosen pembimbing")
	}
	if created.Email != "alya@sanctuary.ac.id" {
		t.Errorf("email = %q, want ternormalisasi huruf kecil tanpa spasi", created.Email)
	}
	if created.PasswordHash == "" || created.PasswordHash == "rahasia123" {
		t.Error("kata sandi wajib tersimpan sebagai hash")
	}
	if !created.IsActive {
		t.Error("akun baru harus aktif")
	}

	if result.Tokens.AccessToken == "" || result.Tokens.RefreshToken == "" {
		t.Error("pendaftaran berhasil harus langsung menerbitkan sesi")
	}
	if result.Session.User.Role != constants.RoleStudent.String() {
		t.Errorf("peran pada sesi = %q, want %s",
			result.Session.User.Role, constants.RoleStudent)
	}

	if len(audits.entries) != 1 || audits.entries[0].Action != models.ActionRegister {
		t.Error("pendaftaran wajib terekam pada audit log")
	}
}

func TestRegister_RejectsPasswordConfirmationMismatch(t *testing.T) {
	users := newFakeUserRepo()
	uc, _ := newRegisterUsecase(users, allowAllLimiter{})

	req := validRegisterRequest()
	req.PasswordConfirmation = "rahasia456"

	_, err := uc.Register(context.Background(), req, LoginMeta{})

	if errorCode(err) != utils.CodePasswordMismatch {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodePasswordMismatch)
	}
	if len(users.created) != 0 {
		t.Error("tidak boleh ada akun terbuat saat konfirmasi tidak sama")
	}
}

func TestRegister_RejectsDuplicateEmail(t *testing.T) {
	users := newFakeUserRepo()
	users.emailTaken = true
	uc, _ := newRegisterUsecase(users, allowAllLimiter{})

	_, err := uc.Register(context.Background(), validRegisterRequest(), LoginMeta{})

	if errorCode(err) != utils.CodeEmailAlreadyRegistered {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeEmailAlreadyRegistered)
	}
}

func TestRegister_RejectsDuplicateStudentNumber(t *testing.T) {
	users := newFakeUserRepo()
	users.numberTaken = true
	uc, _ := newRegisterUsecase(users, allowAllLimiter{})

	_, err := uc.Register(context.Background(), validRegisterRequest(), LoginMeta{})

	if errorCode(err) != utils.CodeStudentNumberRegistered {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeStudentNumberRegistered)
	}
}

// Program studi asal membuat mahasiswa tidak pernah muncul di dashboard prodi
// mana pun — kesalahan yang baru ketahuan berbulan-bulan kemudian.
func TestRegister_RejectsUnknownStudyProgram(t *testing.T) {
	users := newFakeUserRepo()
	audits := &fakeAuditRepo{}
	uc := NewAuthUsecase(
		nil, users, &fakeTokenRepo{}, audits, &fakeRoleRepo{}, &fakeProgramRepo{missing: true},
		testJWT(), allowAllLimiter{}, testConfig(),
	)

	_, err := uc.Register(context.Background(), validRegisterRequest(), LoginMeta{})

	if errorCode(err) != utils.CodeStudyProgramNotFound {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeStudyProgramNotFound)
	}
	if len(users.created) != 0 {
		t.Error("akun tidak boleh terbuat dengan prodi yang tidak dikenal")
	}
}

func TestRegister_StopsAtRateLimit(t *testing.T) {
	users := newFakeUserRepo()
	uc, _ := newRegisterUsecase(users, blockingLimiter{})

	_, err := uc.Register(context.Background(), validRegisterRequest(), LoginMeta{})

	if errorCode(err) != utils.CodeRateLimitExceeded {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeRateLimitExceeded)
	}
	if len(users.created) != 0 {
		t.Error("permintaan yang kena limit tidak boleh menyisakan akun")
	}
}
