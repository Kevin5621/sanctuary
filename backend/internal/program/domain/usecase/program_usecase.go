package usecase

import (
	"context"
	"log"
	"math"
	"strconv"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
	mentorusecase "github.com/gilabs/sanctuary/internal/mentor/domain/usecase"
	"github.com/gilabs/sanctuary/internal/program/data/repositories"
	"github.com/gilabs/sanctuary/internal/program/domain/dto"
	studentrepo "github.com/gilabs/sanctuary/internal/student/data/repositories"
)

// ProgramUsecase melayani 4 tab Kaprodi: Dashboard, Pembimbing, Laporan, Profil.
//
// Kaprodi TIDAK PERNAH melihat data individu — seluruh keluaran berupa angka
// agregat yang lolos ambang k-anonymity, dan hanya dari mahasiswa yang
// mengaktifkan izin "Ikut Statistik Prodi".
type ProgramUsecase interface {
	Dashboard(ctx context.Context, access Access, periodDays int) (dto.ProgramDashboardResponse, error)
	Advisors(ctx context.Context, access Access) ([]dto.AdvisorLoadResponse, error)
	Students(ctx context.Context, access Access) ([]dto.ProgramStudentResponse, error)
	// SetAdvisees menyetel daftar bimbingan seorang dosen (layar per-dosen).
	SetAdvisees(ctx context.Context, access Access, advisorID string, req dto.SetAdviseesRequest) error
	// SetStudentAdvisors menyetel daftar pembimbing seorang mahasiswa
	// (layar per-mahasiswa — satu-satunya cara memberi pembimbing kedua).
	SetStudentAdvisors(ctx context.Context, access Access, studentID string, req dto.SetStudentAdvisorsRequest) error
	CohortReport(ctx context.Context, access Access, periodDays int) ([]dto.CohortReportResponse, error)
	// Profile mengisi tab Profil kaprodi (K-PRO-01).
	Profile(ctx context.Context, access Access) (dto.ProgramProfileResponse, error)
}

// Access membawa cakupan prodi milik kaprodi (dari klaim JWT).
type Access struct {
	UserID    string
	ProgramID string
	RequestID string
	IPAddress string
}

type programUsecase struct {
	programs repositories.ProgramRepository
	metrics  studentrepo.DailyMetricRepository
	dass     studentrepo.DassRepository
	ews      mentorusecase.EWSUsecase
	audits   authrepo.AuditRepository
}

func NewProgramUsecase(
	programs repositories.ProgramRepository,
	metrics studentrepo.DailyMetricRepository,
	dass studentrepo.DassRepository,
	ews mentorusecase.EWSUsecase,
	audits authrepo.AuditRepository,
) ProgramUsecase {
	return &programUsecase{programs: programs, metrics: metrics, dass: dass, ews: ews, audits: audits}
}

const activeWindowDays = 7

func (u *programUsecase) Dashboard(ctx context.Context, access Access, periodDays int) (dto.ProgramDashboardResponse, error) {
	if access.ProgramID == "" {
		return dto.ProgramDashboardResponse{}, utils.NewError(utils.CodeForbidden).WithDetails(map[string]any{
			"reason": "akun kaprodi belum terhubung ke program studi",
		})
	}

	studentIDs, err := u.programs.ConsentedStudentIDs(ctx, access.ProgramID, nil)
	if err != nil {
		return dto.ProgramDashboardResponse{}, err
	}

	guard := utils.NewAggregateGuard(len(studentIDs))
	res := dto.ProgramDashboardResponse{
		IsSufficient:     guard.IsSufficient,
		GroupSize:        guard.GroupSize,
		MinimumGroupSize: guard.MinimumGroup,
		Message:          guard.InsufficientMsg,
		PeriodDays:       periodDays,
		Metrics:          emptyMetricCards(),
	}
	if !guard.IsSufficient {
		return res, nil
	}

	u.audit(ctx, access, map[string]any{
		"scope":       "program_dashboard",
		"program_id":  access.ProgramID,
		"period_days": periodDays,
		"group_size":  len(studentIDs),
	})

	from, to := apptime.DaysAgo(periodDays), apptime.Today()

	agg, err := u.metrics.AggregateForUsers(ctx, studentIDs, from, to)
	if err != nil {
		return dto.ProgramDashboardResponse{}, err
	}
	activeCount, err := u.metrics.CountActiveStudents(ctx, studentIDs, apptime.DaysAgo(activeWindowDays), to)
	if err != nil {
		return dto.ProgramDashboardResponse{}, err
	}
	screenedCount, err := u.dass.CountScreenedUsers(ctx, studentIDs)
	if err != nil {
		return dto.ProgramDashboardResponse{}, err
	}

	// Kalkulasi EWS dijalankan SETELAH AggregateGuard lolos (k >= 5), sehingga
	// tidak ada jalur yang menghitung — apalagi mengembalikan — angka intervensi
	// pada kelompok di bawah ambang.
	ewsMap, err := u.ews.EvaluateMany(ctx, studentIDs, nil)
	if err != nil {
		return dto.ProgramDashboardResponse{}, err
	}
	levelCounts := map[constants.EWSLevel]int{}
	for _, result := range ewsMap {
		levelCounts[result.Level]++
	}

	// D-9: pembagi adalah jumlah mahasiswa yang benar-benar terevaluasi, bukan
	// seluruh peserta statistik. Memakai len(studentIDs) akan mengecilkan
	// persentase setiap kali ada mahasiswa yang datanya belum cukup.
	evaluated := float64(len(ewsMap))
	total := float64(len(studentIDs))

	res.EWSDistribution = toEWSShares(levelCounts, evaluated)
	res.Metrics = []dto.MetricCardResponse{
		{Key: "avg_mood", Label: "Rata-rata mood", Value: ptr(round2(agg.AvgMood)), Unit: "skala 1-5"},

		// D-9: PERSENTASE, bukan hitungan mentah. Pada prodi kecil "3 mahasiswa
		// perlu intervensi" praktis menunjuk orang tertentu; kaprodi tetap
		// mendapat sinyal besaran masalah tanpa kemampuan menebak siapa.
		// Hitungan mentahnya tidak dikirim di field mana pun pada response ini.
		{Key: "need_intervention", Label: "Perlu intervensi",
			Value: ptr(percentOf(float64(levelCounts[constants.EWSLevelIntervention]), evaluated)),
			Unit:  "%", Hint: "dari mahasiswa yang datanya cukup dievaluasi"},

		{Key: "active_7_days", Label: "Aktif 7 hari terakhir", Value: ptr(float64(activeCount)), Unit: "mahasiswa",
			Hint: percentHint(float64(activeCount), total)},
		{Key: "avg_stress", Label: "Rata-rata stres", Value: ptr(round2(agg.AvgStress)), Unit: "skala 1-5"},
		{Key: "avg_sleep", Label: "Rata-rata tidur", Value: ptr(round2(agg.AvgSleepHours)), Unit: "jam"},
		{Key: "screened", Label: "Sudah skrining DASS-21", Value: ptr(float64(screenedCount)), Unit: "mahasiswa",
			Hint: percentHint(float64(screenedCount), total)},
	}
	return res, nil
}

func (u *programUsecase) Advisors(ctx context.Context, access Access) ([]dto.AdvisorLoadResponse, error) {
	loads, err := u.programs.AdvisorLoads(ctx, access.ProgramID)
	if err != nil {
		return nil, err
	}

	// Beban bimbingan & alokasi mahasiswa adalah data administratif (bukan data kondisi),
	// sehingga tidak tunduk pada k-anonymity.
	out := make([]dto.AdvisorLoadResponse, 0, len(loads))
	for _, load := range loads {
		advisees, err := u.programs.AdviseesByAdvisor(ctx, load.AdvisorID)
		if err != nil {
			return nil, err
		}

		adviseeList := make([]dto.AdviseeSummaryResponse, 0, len(advisees))
		for _, a := range advisees {
			adviseeList = append(adviseeList, dto.AdviseeSummaryResponse{
				ID:            a.ID,
				FullName:      a.FullName,
				StudentNumber: a.StudentNumber,
				Email:         a.Email,
			})
		}

		out = append(out, dto.AdvisorLoadResponse{
			AdvisorID:      load.AdvisorID,
			FullName:       load.FullName,
			LecturerNumber: load.LecturerNumber,
			Email:          load.Email,
			AdviseeCount:   load.AdviseeCount,
			Advisees:       adviseeList,
		})
	}
	return out, nil
}

func (u *programUsecase) Students(ctx context.Context, access Access) ([]dto.ProgramStudentResponse, error) {
	if access.ProgramID == "" {
		return nil, utils.NewError(utils.CodeForbidden).WithDetails(map[string]any{
			"reason": "akun kaprodi belum terhubung ke program studi",
		})
	}

	students, err := u.programs.StudentsInProgram(ctx, access.ProgramID)
	if err != nil {
		return nil, err
	}

	ids := make([]string, 0, len(students))
	for _, s := range students {
		ids = append(ids, s.ID)
	}
	advisorMap, err := u.programs.AdvisorsForStudents(ctx, ids)
	if err != nil {
		return nil, err
	}

	out := make([]dto.ProgramStudentResponse, 0, len(students))
	for _, s := range students {
		advisors := advisorMap[s.ID]
		items := make([]dto.AdvisorBriefResponse, 0, len(advisors))
		for _, a := range advisors {
			items = append(items, dto.AdvisorBriefResponse{
				AdvisorID:      a.AdvisorID,
				FullName:       a.FullName,
				LecturerNumber: a.LecturerNumber,
			})
		}

		out = append(out, dto.ProgramStudentResponse{
			ID:            s.ID,
			FullName:      s.FullName,
			StudentNumber: s.StudentNumber,
			Email:         s.Email,
			Advisors:      items,
		})
	}
	return out, nil
}

func (u *programUsecase) SetAdvisees(
	ctx context.Context,
	access Access,
	advisorID string,
	req dto.SetAdviseesRequest,
) error {
	if access.ProgramID == "" {
		return errProgramNotLinked()
	}
	return u.programs.SetAdviseesForAdvisor(ctx, access.ProgramID, advisorID, req.StudentIDs, access.UserID)
}

func (u *programUsecase) SetStudentAdvisors(
	ctx context.Context,
	access Access,
	studentID string,
	req dto.SetStudentAdvisorsRequest,
) error {
	if access.ProgramID == "" {
		return errProgramNotLinked()
	}
	return u.programs.SetAdvisorsForStudent(ctx, access.ProgramID, studentID, req.AdvisorIDs, access.UserID)
}

func errProgramNotLinked() error {
	return utils.NewError(utils.CodeForbidden).WithDetails(map[string]any{
		"reason": "akun kaprodi belum terhubung ke program studi",
	})
}

func (u *programUsecase) CohortReport(ctx context.Context, access Access, periodDays int) ([]dto.CohortReportResponse, error) {
	cohorts, err := u.programs.CohortCounts(ctx, access.ProgramID)
	if err != nil {
		return nil, err
	}

	from, to := apptime.DaysAgo(periodDays), apptime.Today()
	reports := make([]dto.CohortReportResponse, 0, len(cohorts))

	for _, cohort := range cohorts {
		year := cohort.CohortYear
		ids, err := u.programs.ConsentedStudentIDs(ctx, access.ProgramID, &year)
		if err != nil {
			return nil, err
		}

		guard := utils.NewAggregateGuard(len(ids))
		report := dto.CohortReportResponse{
			CohortYear:       year,
			IsSufficient:     guard.IsSufficient,
			GroupSize:        guard.GroupSize,
			MinimumGroupSize: guard.MinimumGroup,
			Message:          guard.InsufficientMsg,
		}
		if !guard.IsSufficient {
			reports = append(reports, report)
			continue
		}

		agg, err := u.metrics.AggregateForUsers(ctx, ids, from, to)
		if err != nil {
			return nil, err
		}
		active, err := u.metrics.CountActiveStudents(ctx, ids, apptime.DaysAgo(activeWindowDays), to)
		if err != nil {
			return nil, err
		}

		report.AvgMood = ptr(round2(agg.AvgMood))
		report.AvgStress = ptr(round2(agg.AvgStress))
		report.AvgSleepHours = ptr(round2(agg.AvgSleepHours))
		report.ActiveStudents = &active
		reports = append(reports, report)
	}
	return reports, nil
}

// programAccessLimits adalah batas akses kaprodi, ditampilkan apa adanya pada
// tab Profil (K-PRO-01).
var programAccessLimits = []string{
	"Anda tidak dapat membuka indikator kondisi per mahasiswa.",
	"Anda tidak melihat nama siapa pun pada data kondisi (seluruhnya agregat).",
	"Anda tidak dapat membaca jurnal maupun percakapan Terapis AI mahasiswa.",
	"Angka agregat hanya muncul bila kelompoknya minimal " +
		strconv.Itoa(utils.KAnonymityMinGroup()) + " mahasiswa.",
	"Hanya mahasiswa yang mengaktifkan izin \"Ikut Statistik Prodi\" yang ikut dihitung.",
	"Metrik \"perlu intervensi\" ditampilkan sebagai persentase, bukan jumlah orang.",
}

// Profile mengembalikan populasi prodi dan batas akses.
//
// Total mahasiswa terdaftar TIDAK tunduk k-anonymity: itu angka administratif
// (berapa orang ada di prodi), bukan data kondisi — sama seperti beban bimbingan.
func (u *programUsecase) Profile(ctx context.Context, access Access) (dto.ProgramProfileResponse, error) {
	if access.ProgramID == "" {
		return dto.ProgramProfileResponse{}, utils.NewError(utils.CodeForbidden).WithDetails(map[string]any{
			"reason": "akun kaprodi belum terhubung ke program studi",
		})
	}

	programName, err := u.programs.ProgramName(ctx, access.ProgramID)
	if err != nil {
		return dto.ProgramProfileResponse{}, err
	}
	totalStudents, err := u.programs.TotalStudents(ctx, access.ProgramID)
	if err != nil {
		return dto.ProgramProfileResponse{}, err
	}
	advisors, err := u.programs.AdvisorLoads(ctx, access.ProgramID)
	if err != nil {
		return dto.ProgramProfileResponse{}, err
	}

	return dto.ProgramProfileResponse{
		ProgramID:     access.ProgramID,
		ProgramName:   programName,
		TotalStudents: totalStudents,
		TotalAdvisors: len(advisors),
		AccessLimits:  programAccessLimits,
	}, nil
}

func (u *programUsecase) audit(ctx context.Context, access Access, meta map[string]any) {
	err := u.audits.Record(ctx, authrepo.AuditEntry{
		ActorID:    access.UserID,
		ActorRole:  constants.RoleHeadOfProgram.String(),
		Action:     authmodels.ActionViewAggregate,
		Resource:   "program_aggregate",
		ResourceID: access.ProgramID,
		Metadata:   meta,
		IPAddress:  access.IPAddress,
		RequestID:  access.RequestID,
	})
	if err != nil {
		log.Printf("[audit] failed program aggregate actor=%s err=%v", access.UserID, err)
	}
}

// emptyMetricCards menjaga bentuk response tetap sama saat data belum cukup,
// sehingga UI tidak perlu cabang render terpisah.
func emptyMetricCards() []dto.MetricCardResponse {
	return []dto.MetricCardResponse{
		{Key: "avg_mood", Label: "Rata-rata mood", Unit: "skala 1-5"},
		{Key: "need_intervention", Label: "Perlu intervensi", Unit: "%"},
		{Key: "active_7_days", Label: "Aktif 7 hari terakhir", Unit: "mahasiswa"},
		{Key: "avg_stress", Label: "Rata-rata stres", Unit: "skala 1-5"},
		{Key: "avg_sleep", Label: "Rata-rata tidur", Unit: "jam"},
		{Key: "screened", Label: "Sudah skrining DASS-21", Unit: "mahasiswa"},
	}
}

// toEWSShares mengubah hitungan per level menjadi persentase (K-DAS-07).
//
// Seluruh level selalu disertakan — termasuk yang bernilai 0 — supaya kaprodi
// tidak menyimpulkan "tidak ada yang perlu intervensi" hanya karena levelnya
// hilang dari response. Level INSUFFICIENT_DATA tidak pernah masuk peta ini
// karena EvaluateMany hanya mengembalikan hasil yang terevaluasi.
func toEWSShares(counts map[constants.EWSLevel]int, evaluated float64) []dto.EWSShareResponse {
	levels := []constants.EWSLevel{
		constants.EWSLevelNormal,
		constants.EWSLevelWatch,
		constants.EWSLevelRisk,
		constants.EWSLevelIntervention,
	}

	out := make([]dto.EWSShareResponse, 0, len(levels))
	for _, level := range levels {
		out = append(out, dto.EWSShareResponse{
			Level:      level.String(),
			LevelLabel: level.Label(),
			Percentage: percentOf(float64(counts[level]), evaluated),
		})
	}
	return out
}

func percentOf(part, total float64) float64 {
	if total <= 0 {
		return 0
	}
	return round2(part / total * 100)
}

func percentHint(part, total float64) string {
	if total <= 0 {
		return ""
	}
	percent := strconv.FormatFloat(percentOf(part, total), 'f', -1, 64)
	return percent + "% dari peserta statistik"
}

func ptr(v float64) *float64   { return &v }
func round2(v float64) float64 { return math.Round(v*100) / 100 }
