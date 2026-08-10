package usecase

import (
	"context"
	"strconv"

	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

// ContactRequestUsecase melayani tombol "minta dihubungi" milik mahasiswa.
type ContactRequestUsecase interface {
	State(ctx context.Context, userID string) (dto.ContactRequestStateResponse, error)
	Create(ctx context.Context, userID string, req dto.CreateContactRequestRequest) (dto.ContactRequestResponse, error)
	Cancel(ctx context.Context, userID string) error
}

type contactRequestUsecase struct {
	repo     repositories.ContactRequestRepository
	advisors authrepo.StudentAdvisorRepository
}

func NewContactRequestUsecase(
	repo repositories.ContactRequestRepository,
	advisors authrepo.StudentAdvisorRepository,
) ContactRequestUsecase {
	return &contactRequestUsecase{repo: repo, advisors: advisors}
}

// explanationText tampil di kartu sebelum tombol ditekan. Kalimatnya sengaja
// menyebut batasnya secara eksplisit: mahasiswa yang tahu persis apa yang
// dilihat dosen lebih mungkin menekan tombol ini saat benar membutuhkannya.
//
// Jumlah pembimbing ikut disebut. Satu permintaan terbaca oleh SEMUA pembimbing
// mahasiswa tersebut — menyembunyikan fakta itu akan membuat mahasiswa mengira
// ia menghubungi satu orang padahal tidak.
func explanationText(advisorCount int) string {
	subject := "Pembimbingmu hanya akan melihat"
	if advisorCount > 1 {
		subject = "Seluruh pembimbingmu (" + strconv.Itoa(advisorCount) + " dosen) hanya akan melihat"
	}
	return subject + " namamu dan waktu permintaan. " +
		"tanpa isi jurnal, tanpa alasan, dan tanpa skor apa pun. Catatan yang kamu tulis " +
		"di sini hanya untuk pengingat dirimu sendiri."
}

func (u *contactRequestUsecase) State(ctx context.Context, userID string) (dto.ContactRequestStateResponse, error) {
	advisors, err := u.advisors.ListForStudent(ctx, userID)
	if err != nil {
		return dto.ContactRequestStateResponse{}, err
	}

	open, err := u.repo.FindOpenByStudent(ctx, userID)
	if err != nil {
		return dto.ContactRequestStateResponse{}, err
	}

	state := dto.ContactRequestStateResponse{
		Explanation: explanationText(len(advisors)),
		CanRequest:  len(advisors) > 0 && open == nil,
		Advisors:    make([]dto.AdvisorResponse, 0, len(advisors)),
	}
	for _, a := range advisors {
		state.Advisors = append(state.Advisors, dto.AdvisorResponse{
			AdvisorID:      a.AdvisorID,
			FullName:       a.FullName,
			LecturerNumber: a.LecturerNumber,
			Email:          a.Email,
		})
	}

	if open != nil {
		state.HasOpenRequest = true
		response := toContactRequestResponse(*open)
		state.Request = &response
	}
	return state, nil
}

func (u *contactRequestUsecase) Create(ctx context.Context, userID string, req dto.CreateContactRequestRequest) (dto.ContactRequestResponse, error) {
	advisors, err := u.advisors.ListForStudent(ctx, userID)
	if err != nil {
		return dto.ContactRequestResponse{}, err
	}
	if len(advisors) == 0 {
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

	// Tujuan permintaan TIDAK dibekukan ke satu dosen. Baris ini dibaca lewat
	// student_advisors saat dosen membuka daftarnya, sehingga pembimbing yang
	// baru ditambahkan tetap melihat permintaan yang masih terbuka — dan
	// mahasiswa tidak perlu memilih siapa yang "paling mungkin membalas" pada
	// saat ia justru sedang butuh dihubungi.
	request := models.StudentContactRequest{
		StudentID: userID,
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
