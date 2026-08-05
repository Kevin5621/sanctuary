package usecase

import (
	"context"
	"testing"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

func studentWithAdvisor() *authmodels.User {
	advisorID := "advisor-1"
	return &authmodels.User{
		FullName:  "Alya Prameswari",
		AdvisorID: &advisorID,
		Advisor:   &authmodels.User{FullName: "Dr. Sinta Pembimbing"},
	}
}

func TestContactRequestState_ExplainsWhatAdvisorSees(t *testing.T) {
	uc := NewContactRequestUsecase(&fakeContactRepo{}, &fakeUserRepo{user: studentWithAdvisor()})

	state, err := uc.State(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !state.CanRequest {
		t.Fatal("mahasiswa dengan pembimbing dan tanpa permintaan terbuka harus bisa meminta")
	}
	if state.AdvisorName == "" {
		t.Error("nama pembimbing harus tampil supaya jelas siapa yang dihubungi")
	}
	// Mahasiswa perlu tahu batasnya SEBELUM menekan tombol.
	if state.Explanation == "" {
		t.Fatal("penjelasan apa yang dilihat dosen wajib ada")
	}
}

func TestContactRequest_CreatesOpenRequest(t *testing.T) {
	repo := &fakeContactRepo{}
	uc := NewContactRequestUsecase(repo, &fakeUserRepo{user: studentWithAdvisor()})

	request, err := uc.Create(context.Background(), "student-1", dto.CreateContactRequestRequest{
		Note: "Ingin berdiskusi soal beban tugas.",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !request.IsOpen {
		t.Fatal("permintaan baru harus berstatus terbuka")
	}
	if len(repo.created) != 1 {
		t.Fatalf("jumlah tersimpan = %d, want 1", len(repo.created))
	}
	if repo.created[0].AdvisorID != "advisor-1" {
		t.Fatalf("advisor = %s, want advisor-1", repo.created[0].AdvisorID)
	}
}

// Permintaan kedua tidak membuat dosen datang lebih cepat; yang bertambah
// hanya kebisingan pada daftarnya.
func TestContactRequest_RejectsSecondOpenRequest(t *testing.T) {
	repo := &fakeContactRepo{open: &models.StudentContactRequest{Status: models.ContactRequestOpen}}
	uc := NewContactRequestUsecase(repo, &fakeUserRepo{user: studentWithAdvisor()})

	_, err := uc.Create(context.Background(), "student-1", dto.CreateContactRequestRequest{})
	if errorCode(err) != utils.CodeContactRequestExists {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeContactRequestExists)
	}
}

func TestContactRequest_RequiresAdvisor(t *testing.T) {
	uc := NewContactRequestUsecase(
		&fakeContactRepo{},
		&fakeUserRepo{user: &authmodels.User{FullName: "Tanpa Pembimbing"}},
	)

	_, err := uc.Create(context.Background(), "student-1", dto.CreateContactRequestRequest{})
	if errorCode(err) != utils.CodeAdvisorNotAssigned {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeAdvisorNotAssigned)
	}
}

func TestContactRequest_StateBlocksWhenAlreadyOpen(t *testing.T) {
	repo := &fakeContactRepo{open: &models.StudentContactRequest{Status: models.ContactRequestOpen}}
	uc := NewContactRequestUsecase(repo, &fakeUserRepo{user: studentWithAdvisor()})

	state, err := uc.State(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if state.CanRequest {
		t.Fatal("permintaan yang masih terbuka harus mencegah permintaan baru")
	}
	if !state.HasOpenRequest || state.Request == nil {
		t.Fatal("permintaan terbuka harus dikembalikan agar klien bisa menampilkannya")
	}
}

func TestContactRequest_CancelClearsOpenRequest(t *testing.T) {
	repo := &fakeContactRepo{open: &models.StudentContactRequest{Status: models.ContactRequestOpen}}
	uc := NewContactRequestUsecase(repo, &fakeUserRepo{user: studentWithAdvisor()})

	if err := uc.Cancel(context.Background(), "student-1"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !repo.cancelled {
		t.Fatal("pembatalan harus tercatat")
	}
}

func TestContactRequest_CancelWithoutOpenRequestIsNotFound(t *testing.T) {
	uc := NewContactRequestUsecase(&fakeContactRepo{}, &fakeUserRepo{user: studentWithAdvisor()})

	err := uc.Cancel(context.Background(), "student-1")
	if errorCode(err) != utils.CodeNotFound {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeNotFound)
	}
}
