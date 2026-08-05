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
	CohortReport(ctx context.Context, access Access, periodDays int) ([]dto.CohortReportResponse, error)
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

	ewsMap, err := u.ews.EvaluateMany(ctx, studentIDs, nil)
	if err != nil {
		return dto.ProgramDashboardResponse{}, err
	}
	distribution := map[string]int{}
	interventionCount := 0
	for _, result := range ewsMap {
		distribution[result.Level.String()]++
		if result.Level == constants.EWSLevelIntervention {
			interventionCount++
		}
	}

	total := float64(len(studentIDs))
	res.EWSDistribution = distribution
	res.Metrics = []dto.MetricCardResponse{
		{Key: "avg_mood", Label: "Rata-rata mood", Value: ptr(round2(agg.AvgMood)), Unit: "skala 1-5"},
		{Key: "need_intervention", Label: "Perlu intervensi", Value: ptr(float64(interventionCount)), Unit: "mahasiswa"},
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

	// Beban bimbingan adalah data administratif (bukan data kondisi),
	// sehingga tidak tunduk pada k-anonymity.
	out := make([]dto.AdvisorLoadResponse, 0, len(loads))
	for _, load := range loads {
		out = append(out, dto.AdvisorLoadResponse{
			AdvisorID:      load.AdvisorID,
			FullName:       load.FullName,
			LecturerNumber: load.LecturerNumber,
			Email:          load.Email,
			AdviseeCount:   load.AdviseeCount,
		})
	}
	return out, nil
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
		{Key: "need_intervention", Label: "Perlu intervensi", Unit: "mahasiswa"},
		{Key: "active_7_days", Label: "Aktif 7 hari terakhir", Unit: "mahasiswa"},
		{Key: "avg_stress", Label: "Rata-rata stres", Unit: "skala 1-5"},
		{Key: "avg_sleep", Label: "Rata-rata tidur", Unit: "jam"},
		{Key: "screened", Label: "Sudah skrining DASS-21", Unit: "mahasiswa"},
	}
}

func percentHint(part, total float64) string {
	if total <= 0 {
		return ""
	}
	percent := strconv.FormatFloat(round2(part/total*100), 'f', -1, 64)
	return percent + "% dari peserta statistik"
}

func ptr(v float64) *float64   { return &v }
func round2(v float64) float64 { return math.Round(v*100) / 100 }
