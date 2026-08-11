package usecase

import (
	"context"
	"strings"
	"testing"

	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

func oneAdvisor() *fakeStudentAdvisorRepo {
	return &fakeStudentAdvisorRepo{advisors: []authrepo.AdvisorBrief{
		{AdvisorID: "advisor-1", FullName: "Dr. Sinta Pembimbing"},
	}}
}

func twoAdvisors() *fakeStudentAdvisorRepo {
	return &fakeStudentAdvisorRepo{advisors: []authrepo.AdvisorBrief{
		{AdvisorID: "advisor-1", FullName: "Dr. Sinta Pembimbing"},
		{AdvisorID: "advisor-2", FullName: "Ahmad Pembimbing, M.Psi."},
	}}
}

func TestContactRequestState_ExplainsWhatAdvisorSees(t *testing.T) {
	uc := NewContactRequestUsecase(&fakeContactRepo{}, oneAdvisor())

	state, err := uc.State(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !state.CanRequest {
		t.Fatal("mahasiswa dengan pembimbing dan tanpa permintaan terbuka harus bisa meminta")
	}
	if len(state.Advisors) != 1 || state.Advisors[0].FullName == "" {
		t.Error("nama pembimbing harus tampil supaya jelas siapa yang dihubungi")
	}
	// Mahasiswa perlu tahu batasnya SEBELUM menekan tombol.
	if state.Explanation == "" {
		t.Fatal("penjelasan apa yang dilihat dosen wajib ada")
	}
}

// Satu permintaan terbaca oleh SEMUA pembimbing. Mahasiswa yang mengira sedang
// menghubungi satu orang padahal empat akan merasa dikhianati oleh aplikasinya —
// jadi jumlahnya harus tertulis di kartu, bukan tersirat.
func TestContactRequestState_ListsEveryAdvisorThatWillSeeIt(t *testing.T) {
	uc := NewContactRequestUsecase(&fakeContactRepo{}, twoAdvisors())

	state, err := uc.State(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(state.Advisors) != 2 {
		t.Fatalf("jumlah pembimbing pada state = %d, want 2", len(state.Advisors))
	}
	if !strings.Contains(state.Explanation, "2") {
		t.Errorf("penjelasan harus menyebut jumlah pembimbing yang menerima permintaan, got %q",
			state.Explanation)
	}
}

func TestContactRequest_CreatesOpenRequest(t *testing.T) {
	repo := &fakeContactRepo{}
	uc := NewContactRequestUsecase(repo, twoAdvisors())

	request, err := uc.Create(context.Background(), "student-1", dto.CreateContactRequestRequest{
		Note: "Ingin berdiskusi soal beban tugas.",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !request.IsOpen {
		t.Fatal("permintaan baru harus berstatus terbuka")
	}
	// Satu baris untuk berapa pun jumlah pembimbing: tujuannya dibaca lewat
	// student_advisors, bukan dibekukan per dosen.
	if len(repo.created) != 1 {
		t.Fatalf("jumlah tersimpan = %d, want 1", len(repo.created))
	}
	if repo.created[0].StudentID != "student-1" {
		t.Fatalf("student = %s, want student-1", repo.created[0].StudentID)
	}
}

// Permintaan kedua tidak membuat dosen datang lebih cepat; yang bertambah
// hanya kebisingan pada daftarnya.
func TestContactRequest_RejectsSecondOpenRequest(t *testing.T) {
	repo := &fakeContactRepo{open: &models.StudentContactRequest{Status: models.ContactRequestOpen}}
	uc := NewContactRequestUsecase(repo, oneAdvisor())

	_, err := uc.Create(context.Background(), "student-1", dto.CreateContactRequestRequest{})
	if errorCode(err) != utils.CodeContactRequestExists {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeContactRequestExists)
	}
}

func TestContactRequest_RequiresAdvisor(t *testing.T) {
	uc := NewContactRequestUsecase(&fakeContactRepo{}, &fakeStudentAdvisorRepo{})

	_, err := uc.Create(context.Background(), "student-1", dto.CreateContactRequestRequest{})
	if errorCode(err) != utils.CodeAdvisorNotAssigned {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeAdvisorNotAssigned)
	}
}

func TestContactRequest_StateBlocksWhenAlreadyOpen(t *testing.T) {
	repo := &fakeContactRepo{open: &models.StudentContactRequest{Status: models.ContactRequestOpen}}
	uc := NewContactRequestUsecase(repo, oneAdvisor())

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
	uc := NewContactRequestUsecase(repo, oneAdvisor())

	if err := uc.Cancel(context.Background(), "student-1"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !repo.cancelled {
		t.Fatal("pembatalan harus tercatat")
	}
}

func TestContactRequest_CancelWithoutOpenRequestIsNotFound(t *testing.T) {
	uc := NewContactRequestUsecase(&fakeContactRepo{}, oneAdvisor())

	err := uc.Cancel(context.Background(), "student-1")
	if errorCode(err) != utils.CodeNotFound {
		t.Fatalf("kode error = %q, want %s", errorCode(err), utils.CodeNotFound)
	}
}

// Kartu "Pembimbingmu" harus menyebut jumlahnya secara eksplisit — mahasiswa
// yang salah mengira punya satu pembimbing akan salah pula menilai pilihan
// privasinya.
func TestMyAdvisors_NoticeStatesTheCount(t *testing.T) {
	uc := NewAdvisorUsecase(twoAdvisors())

	res, err := uc.ListMine(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if res.Total != 2 || len(res.Advisors) != 2 {
		t.Fatalf("total = %d, advisors = %d, want 2 dan 2", res.Total, len(res.Advisors))
	}
	if !strings.Contains(res.Notice, "2") {
		t.Errorf("notice harus menyebut jumlah pembimbing, got %q", res.Notice)
	}
}

func TestMyAdvisors_EmptyStateExplainsWhy(t *testing.T) {
	uc := NewAdvisorUsecase(&fakeStudentAdvisorRepo{})

	res, err := uc.ListMine(context.Background(), "student-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res.Total != 0 {
		t.Fatalf("total = %d, want 0", res.Total)
	}
	if res.Notice == "" {
		t.Error("mahasiswa tanpa pembimbing tetap perlu tahu penyebabnya")
	}
}
