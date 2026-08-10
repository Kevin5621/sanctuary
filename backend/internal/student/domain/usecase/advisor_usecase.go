package usecase

import (
	"context"
	"strconv"

	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/dto"
)

// AdvisorUsecase menjawab satu pertanyaan mahasiswa: "siapa saja yang membimbing
// saya, dan karenanya siapa saja yang bisa melihat data yang saya izinkan?"
type AdvisorUsecase interface {
	ListMine(ctx context.Context, studentID string) (dto.MyAdvisorsResponse, error)
}

type advisorUsecase struct {
	advisors authrepo.StudentAdvisorRepository
}

func NewAdvisorUsecase(advisors authrepo.StudentAdvisorRepository) AdvisorUsecase {
	return &advisorUsecase{advisors: advisors}
}

func (u *advisorUsecase) ListMine(ctx context.Context, studentID string) (dto.MyAdvisorsResponse, error) {
	advisors, err := u.advisors.ListForStudent(ctx, studentID)
	if err != nil {
		return dto.MyAdvisorsResponse{}, err
	}

	items := make([]dto.AdvisorResponse, 0, len(advisors))
	for _, a := range advisors {
		items = append(items, dto.AdvisorResponse{
			AdvisorID:      a.AdvisorID,
			FullName:       a.FullName,
			LecturerNumber: a.LecturerNumber,
			Email:          a.Email,
		})
	}

	return dto.MyAdvisorsResponse{
		Advisors: items,
		Total:    len(items),
		Notice:   advisorNotice(len(items)),
	}, nil
}

// advisorNotice menyebut jumlahnya secara eksplisit.
//
// Mahasiswa yang mengira punya satu pembimbing padahal punya tiga akan menilai
// pilihan privasinya dengan asumsi yang salah — dan itu persis jenis kejutan
// yang membuat orang berhenti menulis jujur di aplikasi seperti ini.
func advisorNotice(total int) string {
	switch {
	case total == 0:
		return "Kamu belum memiliki dosen pembimbing. Program studi akan menetapkannya."
	case total == 1:
		return "Pembimbingmu hanya melihat data sesuai tingkat berbagi yang kamu pilih."
	default:
		return "Kamu dibimbing " + strconv.Itoa(total) + " dosen. Semuanya memiliki akses yang sama — " +
			"sebatas tingkat berbagi yang kamu pilih, tanpa isi jurnal maupun percakapan Terapis AI."
	}
}
