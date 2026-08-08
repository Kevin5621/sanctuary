package usecase

import (
	"context"

	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

// explanationText tampil di kartu sebelum tombol ditekan. Kalimatnya sengaja
// menyebut batasnya secara eksplisit: mahasiswa yang tahu persis apa yang
// dilihat dosen lebih mungkin menekan tombol ini saat benar membutuhkannya.
const explanationText = "Pembimbingmu hanya akan melihat namamu dan waktu permintaan. " +
	"tanpa isi jurnal, tanpa alasan, dan tanpa skor apa pun. Catatan yang kamu tulis " +
	"di sini hanya untuk pengingat dirimu sendiri."

// ContactRequestUsecase melayani tombol "minta dihubungi" milik mahasiswa.
type ContactRequestUsecase interface {
	State(ctx context.Context, userID string) (dto.ContactRequestStateResponse, error)
	Create(ctx context.Context, userID string, req dto.CreateContactRequestRequest) (dto.ContactRequestResponse, error)
	Cancel(ctx context.Context, userID string) error
}

type contactRequestUsecase struct {
	repo  repositories.ContactRequestRepository
	users authrepo.UserRepository
}

func NewContactRequestUsecase(
	repo repositories.ContactRequestRepository,
	users authrepo.UserRepository,
) ContactRequestUsecase {
	return &contactRequestUsecase{repo: repo, users: users}
}

func (u *contactRequestUsecase) State(ctx context.Context, userID string) (dto.ContactRequestStateResponse, error) {
	student, err := u.users.FindByID(ctx, userID)
	if err != nil {
		return dto.ContactRequestStateResponse{}, err
	}

	open, err := u.repo.FindOpenByStudent(ctx, userID)
	if err != nil {
		return dto.ContactRequestStateResponse{}, err
	}

	state := dto.ContactRequestStateResponse{
		Explanation: explanationText,
		CanRequest:  student.AdvisorID != nil && open == nil,
	}
	if student.Advisor != nil {
		state.AdvisorName = student.Advisor.FullName
	}
	if open != nil {
		state.HasOpenRequest = true
		response := toContactRequestResponse(*open)
		state.Request = &response
	}
	return state, nil
}

func (u *contactRequestUsecase) Create(ctx context.Context, userID string, req dto.CreateContactRequestRequest) (dto.ContactRequestResponse, error) {
	student, err := u.users.FindByID(ctx, userID)
	if err != nil {
		return dto.ContactRequestResponse{}, err
	}
	if student.AdvisorID == nil {
		return dto.ContactRequestResponse{}, utils.NewError(utils.CodeAdvisorNotAssigned)
	}

	// Permintaan kedua tidak membuat dosen datang dua kali lebih cepat; yang
	// terjadi hanya daftar yang berisik. Satu permintaan terbuka sudah cukup.
	existing, err := u.repo.FindOpenByStudent(ctx, userID)
	if err != nil {
		return dto.ContactRequestResponse{}, err
	}
	if existing != nil {
		return dto.ContactRequestResponse{}, utils.NewError(utils.CodeContactRequestExists)
	}

	request := models.StudentContactRequest{
		StudentID: userID,
		AdvisorID: *student.AdvisorID,
		Status:    models.ContactRequestOpen,
		Note:      req.Note,
	}
	if err := u.repo.Create(ctx, &request); err != nil {
		return dto.ContactRequestResponse{}, err
	}
	return toContactRequestResponse(request), nil
}

func (u *contactRequestUsecase) Cancel(ctx context.Context, userID string) error {
	return u.repo.CancelOpenByStudent(ctx, userID)
}

func toContactRequestResponse(m models.StudentContactRequest) dto.ContactRequestResponse {
	return dto.ContactRequestResponse{
		ID:        m.ID,
		Status:    m.Status,
		Note:      m.Note,
		CreatedAt: apptime.FormatDateTime(m.CreatedAt),
		IsOpen:    m.Status == models.ContactRequestOpen,
	}
}
