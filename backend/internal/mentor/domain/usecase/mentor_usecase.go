package usecase

import (
	"context"
	"log"
	"sort"
	"time"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
	mentorrepo "github.com/gilabs/sanctuary/internal/mentor/data/repositories"
	mentordto "github.com/gilabs/sanctuary/internal/mentor/domain/dto"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
	studentrepo "github.com/gilabs/sanctuary/internal/student/data/repositories"
)

// AccessContext membawa identitas pemanggil untuk keperluan audit.
type AccessContext struct {
	AdvisorID string
	RequestID string
	IPAddress string
}

// MentorUsecase melayani 3 tab Dosen Pembimbing: Bimbingan, Kondisi, Profil.
//
// Aturan tetap di seluruh method:
//   - Tidak ada satu pun jalur yang membaca teks jurnal / chat AI.
//   - Setiap data kondisi disaring oleh StudentPrivacySetting mahasiswa.
//   - Angka agregat kelompok tunduk pada k-anonymity.
type MentorUsecase interface {
	ListAdvisees(ctx context.Context, access AccessContext, p utils.Pagination) ([]mentordto.AdviseeListItemResponse, int64, error)
	StudentIndicator(ctx context.Context, access AccessContext, studentID string) (mentordto.StudentIndicatorResponse, error)
	GroupCondition(ctx context.Context, access AccessContext, periodDays int) (mentordto.GroupConditionResponse, error)
	// ListContactRequests mengembalikan nama + waktu saja (L-BIM-03 / D-6).
	ListContactRequests(ctx context.Context, access AccessContext) ([]mentordto.ContactRequestItemResponse, error)
	// Profile mengisi tab Profil dosen (L-PRO-02..03).
	Profile(ctx context.Context, access AccessContext) (mentordto.MentorProfileResponse, error)
}

type mentorUsecase struct {
	advisees mentorrepo.AdviseeRepository
	privacy  studentrepo.PrivacyRepository
	metrics  studentrepo.DailyMetricRepository
	ews      EWSUsecase
	audits   authrepo.AuditRepository
}

func NewMentorUsecase(
	advisees mentorrepo.AdviseeRepository,
	privacy studentrepo.PrivacyRepository,
	metrics studentrepo.DailyMetricRepository,
	ews EWSUsecase,
	audits authrepo.AuditRepository,
) MentorUsecase {
	return &mentorUsecase{advisees: advisees, privacy: privacy, metrics: metrics, ews: ews, audits: audits}
}

var shareLevelLabel = map[constants.ShareLevel]string{
	constants.ShareLevelClosed:       "Tertutup",
	constants.ShareLevelSummary:      "Ringkasan",
	constants.ShareLevelSummaryTrend: "Ringkasan + Tren",
}

const noticeClosed = "Mahasiswa memilih untuk tidak membagikan data kondisi."
const noticeAlertOff = "Mahasiswa menonaktifkan peringatan dini ke pembimbing."

func (u *mentorUsecase) ListAdvisees(
	ctx context.Context,
	access AccessContext,
	p utils.Pagination,
) ([]mentordto.AdviseeListItemResponse, int64, error) {
	students, err := u.advisees.ListByAdvisor(ctx, access.AdvisorID)
	if err != nil {
		return nil, 0, err
	}
	if len(students) == 0 {
		return []mentordto.AdviseeListItemResponse{}, 0, nil
	}

	ids := make([]string, 0, len(students))
	for i := range students {
		ids = append(ids, students[i].ID)
	}

	privacyMap, err := u.privacy.FindManyByUserIDs(ctx, ids)
	if err != nil {
		return nil, 0, err
	}
	contactRequests, err := u.advisees.OpenContactRequests(ctx, access.AdvisorID)
	if err != nil {
		return nil, 0, err
	}
	lastCheckins, err := u.metrics.LastCheckinDates(ctx, ids)
	if err != nil {
		return nil, 0, err
	}

	// EWS hanya dihitung untuk mahasiswa yang mengizinkan peringatan dini.
	alertIDs := make([]string, 0, len(ids))
	for _, id := range ids {
		if privacyMap[id].CanSendEarlyWarning() {
			alertIDs = append(alertIDs, id)
		}
	}
	ewsMap, err := u.ews.EvaluateMany(ctx, alertIDs, &access.AdvisorID)
	if err != nil {
		return nil, 0, err
	}

	items := make([]mentordto.AdviseeListItemResponse, 0, len(students))
	for i := range students {
		items = append(items, u.buildListItem(&students[i], privacyMap[students[i].ID], ewsMap, contactRequests, lastCheckins))
	}

	sortAdvisees(items)

	// Daftar bimbingan berukuran kecil dan sudah tersaring privasi, sehingga
	// pengurutan berbasis EWS dilakukan in-memory lalu dipotong per halaman.
	total := int64(len(items))
	start := p.Offset()
	if start >= len(items) {
		return []mentordto.AdviseeListItemResponse{}, total, nil
	}
	end := min(start+p.PerPage, len(items))
	return items[start:end], total, nil
}

// buildListItem menerapkan aturan privasi per mahasiswa:
//   - Tertutup            -> tanpa indikator, tanpa EWS, hanya identitas.
//   - Ringkasan (+Tren)   -> aktivitas check-in terakhir tampil.
//   - Peringatan dini off -> EWS tetap null walau level berbagi memadai.
func (u *mentorUsecase) buildListItem(
	student *authmodels.User,
	setting *studentmodels.StudentPrivacySetting,
	ewsMap map[string]EWSResult,
	contactRequests map[string]mentorrepo.ContactRequestSummary,
	lastCheckins map[string]time.Time,
) mentordto.AdviseeListItemResponse {
	item := mentordto.AdviseeListItemResponse{
		StudentID:       student.ID,
		FullName:        student.FullName,
		StudentNumber:   student.StudentNumber,
		CohortYear:      student.CohortYear,
		ShareLevel:      setting.ShareLevel.String(),
		ShareLevelLabel: shareLevelLabel[setting.ShareLevel],
	}

	// D-7: menekan "minta dihubungi" adalah persetujuan eksplisit dan spesifik
	// yang mengalahkan share_level, sehingga baris ini tetap tampil bahkan saat
	// mahasiswa memilih Tertutup — namun tetap hanya nama + waktu, tanpa alasan
	// (D-6) dan tanpa indikator apa pun.
	if request, ok := contactRequests[student.ID]; ok {
		item.HasOpenContactRequest = true
		requestedAt := apptime.FormatDateTime(request.RequestedAt)
		item.ContactRequestedAt = &requestedAt
	}

	if !setting.CanShareIndicator() {
		item.PrivacyNotice = noticeClosed
		return item
	}

	if date, ok := lastCheckins[student.ID]; ok {
		formatted := apptime.FormatDate(date)
		item.LastCheckinDate = &formatted
	}

	if !setting.CanSendEarlyWarning() {
		item.PrivacyNotice = noticeAlertOff
		return item
	}
	if result, ok := ewsMap[student.ID]; ok {
		item.EWS = toEWSSummary(result)
	}
	return item
}

func (u *mentorUsecase) StudentIndicator(
	ctx context.Context,
	access AccessContext,
	studentID string,
) (mentordto.StudentIndicatorResponse, error) {
	student, err := u.advisees.FindAdvisee(ctx, access.AdvisorID, studentID)
	if err != nil {
		return mentordto.StudentIndicatorResponse{}, err
	}

	setting, err := u.privacy.GetOrDefault(ctx, studentID)
	if err != nil {
		return mentordto.StudentIndicatorResponse{}, err
	}

	// Audit dicatat untuk SETIAP pembukaan detail mahasiswa, termasuk saat
	// hasilnya kosong karena privasi tertutup.
	u.audit(ctx, access, authmodels.ActionViewStudentIndicator, studentID, map[string]any{
		"share_level": setting.ShareLevel,
	})

	res := mentordto.StudentIndicatorResponse{
		StudentID:       student.ID,
		FullName:        student.FullName,
		StudentNumber:   student.StudentNumber,
		ShareLevel:      setting.ShareLevel.String(),
		ShareLevelLabel: shareLevelLabel[setting.ShareLevel],
	}

	// Dibaca sebelum gerbang privasi karena permintaan dihubungi adalah
	// persetujuan eksplisit mahasiswa yang berdiri sendiri (D-7).
	requests, err := u.advisees.OpenContactRequests(ctx, access.AdvisorID)
	if err != nil {
		return mentordto.StudentIndicatorResponse{}, err
	}
	if request, ok := requests[studentID]; ok {
		res.HasOpenContactRequest = true
		requestedAt := apptime.FormatDateTime(request.RequestedAt)
		res.ContactRequestedAt = &requestedAt
	}

	if !setting.CanShareIndicator() {
		res.PrivacyNotice = noticeClosed
		return res, nil
	}

	window := 30
	from, to := apptime.DaysAgo(window), apptime.Today()

	agg, err := u.metrics.AggregateForUsers(ctx, []string{studentID}, from, to)
	if err != nil {
		return mentordto.StudentIndicatorResponse{}, err
	}
	res.Summary = &mentordto.ConditionSummaryResponse{
		AvgMood:       round2(agg.AvgMood),
		AvgStress:     round2(agg.AvgStress),
		AvgSleepHours: round2(agg.AvgSleepHours),
		CheckinCount:  agg.DataPoints,
		WindowDays:    window,
	}

	if setting.CanShareTrend() {
		points, err := u.metrics.WeeklyTrend(ctx, studentID, from, to)
		if err != nil {
			return mentordto.StudentIndicatorResponse{}, err
		}
		res.Trend = make([]mentordto.WeeklyTrendPointResponse, 0, len(points))
		for _, pt := range points {
			res.Trend = append(res.Trend, mentordto.WeeklyTrendPointResponse{
				WeekStart: apptime.FormatDate(pt.WeekStart),
				AvgMood:   round2(pt.AvgMood),
				AvgStress: round2(pt.AvgStress),
				AvgSleep:  round2(pt.AvgSleep),
				Entries:   pt.Entries,
			})
		}
	}

	if setting.CanSendEarlyWarning() {
		result, err := u.ews.Evaluate(ctx, studentID, &access.AdvisorID)
		if err != nil {
			return mentordto.StudentIndicatorResponse{}, err
		}
		res.EWS = toEWSSummary(result)
	} else {
		res.PrivacyNotice = noticeAlertOff
	}

	return res, nil
}

func (u *mentorUsecase) GroupCondition(
	ctx context.Context,
	access AccessContext,
	periodDays int,
) (mentordto.GroupConditionResponse, error) {
	students, err := u.advisees.ListByAdvisor(ctx, access.AdvisorID)
	if err != nil {
		return mentordto.GroupConditionResponse{}, err
	}

	ids := make([]string, 0, len(students))
	for i := range students {
		ids = append(ids, students[i].ID)
	}
	privacyMap, err := u.privacy.FindManyByUserIDs(ctx, ids)
	if err != nil {
		return mentordto.GroupConditionResponse{}, err
	}

	// Hanya mahasiswa yang membagikan indikator yang masuk hitungan agregat.
	included := make([]string, 0, len(ids))
	for _, id := range ids {
		if privacyMap[id].CanShareIndicator() {
			included = append(included, id)
		}
	}

	guard := utils.NewAggregateGuard(len(included))
	res := mentordto.GroupConditionResponse{
		IsSufficient:     guard.IsSufficient,
		GroupSize:        guard.GroupSize,
		MinimumGroupSize: guard.MinimumGroup,
		Message:          guard.InsufficientMsg,
		PeriodDays:       periodDays,
	}
	if !guard.IsSufficient {
		// Di bawah ambang: tidak ada satu angka pun yang dikeluarkan.
		return res, nil
	}

	u.audit(ctx, access, authmodels.ActionViewAggregate, "", map[string]any{
		"scope":       "advisee_group",
		"period_days": periodDays,
		"group_size":  len(included),
	})

	from, to := apptime.DaysAgo(periodDays), apptime.Today()

	agg, err := u.metrics.AggregateForUsers(ctx, included, from, to)
	if err != nil {
		return mentordto.GroupConditionResponse{}, err
	}
	res.AvgMood = ptrFloat(round2(agg.AvgMood))
	res.AvgStress = ptrFloat(round2(agg.AvgStress))
	res.AvgSleepHours = ptrFloat(round2(agg.AvgSleepHours))

	emotions, err := u.metrics.EmotionDistribution(ctx, included, from, to)
	if err != nil {
		return mentordto.GroupConditionResponse{}, err
	}
	res.EmotionDistribution = toEmotionShares(emotions)

	// Sebaran EWS dihitung hanya dari mahasiswa yang mengizinkan peringatan dini.
	alertIDs := make([]string, 0, len(included))
	for _, id := range included {
		if privacyMap[id].CanSendEarlyWarning() {
			alertIDs = append(alertIDs, id)
		}
	}
	if utils.IsGroupSufficient(len(alertIDs)) {
		ewsMap, err := u.ews.EvaluateMany(ctx, alertIDs, &access.AdvisorID)
		if err != nil {
			return mentordto.GroupConditionResponse{}, err
		}
		distribution := map[string]int{}
		for _, result := range ewsMap {
			distribution[result.Level.String()]++
		}
		res.EWSDistribution = distribution
	}

	return res, nil
}

// ListContactRequests mengisi layar "minta dihubungi" (L-BIM-03).
//
// SENGAJA TIDAK DISERTAKAN pada response:
//   - `note` (alasan mahasiswa) — D-6, sudah dihentikan di lapisan repository.
//   - indikator kondisi & EWS — permintaan dihubungi bukan izin membuka data.
//
// Tidak ada penyaringan share_level di sini, dan itu disengaja (D-7): mahasiswa
// Tertutup yang menekan tombol ini tetap harus terlihat, karena justru itu
// maksudnya menekan tombol tersebut.
func (u *mentorUsecase) ListContactRequests(
	ctx context.Context,
	access AccessContext,
) ([]mentordto.ContactRequestItemResponse, error) {
	requests, err := u.advisees.ListOpenContactRequests(ctx, access.AdvisorID)
	if err != nil {
		return nil, err
	}

	items := make([]mentordto.ContactRequestItemResponse, 0, len(requests))
	for _, req := range requests {
		items = append(items, mentordto.ContactRequestItemResponse{
			RequestID:     req.RequestID,
			StudentID:     req.StudentID,
			FullName:      req.FullName,
			StudentNumber: req.StudentNumber,
			RequestedAt:   apptime.FormatDateTime(req.RequestedAt),
		})
	}
	return items, nil
}

// mentorAccessLimits adalah batas akses yang ditampilkan apa adanya di tab Profil
// dosen (L-PRO-03).
//
// Teksnya sengaja tegas dan berasal dari server: mahasiswa yang ragu apakah
// tulisannya terbaca akan berhenti menulis jujur, dan itu mematikan sumber data
// produk ini. Menyatakan batasnya terang-terangan ke dosen adalah cara termurah
// menurunkan kecurigaan tersebut.
var mentorAccessLimits = []string{
	"Anda tidak dapat membaca jurnal mahasiswa — tanpa pengecualian.",
	"Anda tidak dapat membaca percakapan Terapis AI mahasiswa.",
	"Anda hanya melihat indikator mahasiswa bimbingan Anda sendiri, sebatas izin yang mereka pilih.",
	"Mahasiswa yang memilih Tertutup tidak menampilkan indikator apa pun kepada Anda.",
	"Pada daftar \"minta dihubungi\", Anda hanya menerima nama dan waktu — bukan alasannya.",
	"Aplikasi ini bukan kanal pesan: hubungi mahasiswa melalui jalur yang biasa Anda pakai.",
	"Setiap kali Anda membuka indikator seorang mahasiswa, akses tersebut tercatat pada log audit.",
}

func (u *mentorUsecase) Profile(
	ctx context.Context,
	access AccessContext,
) (mentordto.MentorProfileResponse, error) {
	students, err := u.advisees.ListByAdvisor(ctx, access.AdvisorID)
	if err != nil {
		return mentordto.MentorProfileResponse{}, err
	}

	requests, err := u.advisees.ListOpenContactRequests(ctx, access.AdvisorID)
	if err != nil {
		return mentordto.MentorProfileResponse{}, err
	}

	// Jumlah bimbingan adalah data administratif (bukan data kondisi), sehingga
	// tidak tunduk k-anonymity — sama alasannya dengan beban bimbingan kaprodi.
	return mentordto.MentorProfileResponse{
		AdviseeCount:       len(students),
		OpenContactRequest: len(requests),
		AccessLimits:       mentorAccessLimits,
	}, nil
}

func (u *mentorUsecase) audit(ctx context.Context, access AccessContext, action, resourceID string, meta map[string]any) {
	err := u.audits.Record(ctx, authrepo.AuditEntry{
		ActorID:    access.AdvisorID,
		ActorRole:  constants.RoleLecturer.String(),
		Action:     action,
		Resource:   "student_condition",
		ResourceID: resourceID,
		Metadata:   meta,
		IPAddress:  access.IPAddress,
		RequestID:  access.RequestID,
	})
	if err != nil {
		log.Printf("[audit] failed action=%s actor=%s err=%v", action, access.AdvisorID, err)
	}
}

// ------------------------------------------------------------------
// Helper
// ------------------------------------------------------------------

func sortAdvisees(items []mentordto.AdviseeListItemResponse) {
	sort.SliceStable(items, func(i, j int) bool {
		// 1) Permintaan "minta dihubungi" selalu di paling atas.
		if items[i].HasOpenContactRequest != items[j].HasOpenContactRequest {
			return items[i].HasOpenContactRequest
		}
		// 2) Prioritas level EWS (Perlu Intervensi > Risiko > Waspada > Normal).
		pi, pj := ewsPriority(items[i].EWS), ewsPriority(items[j].EWS)
		if pi != pj {
			return pi > pj
		}
		// 3) Nama sebagai tie-breaker agar urutan stabil.
		return items[i].FullName < items[j].FullName
	})
}

func ewsPriority(summary *mentordto.EWSSummaryResponse) int {
	if summary == nil {
		return 0
	}
	return constants.EWSLevel(summary.Level).Priority()
}

func toEWSSummary(result EWSResult) *mentordto.EWSSummaryResponse {
	indicators := make([]mentordto.IndicatorResponse, 0, len(result.Indicators))
	for _, ind := range result.Indicators {
		indicators = append(indicators, mentordto.IndicatorResponse{
			Code:      ind.Code,
			Label:     ind.Label,
			Triggered: ind.Triggered,
			Value:     ind.Value,
			Threshold: ind.Threshold,
			Detail:    ind.Detail,
		})
	}
	return &mentordto.EWSSummaryResponse{
		Level:        result.Level.String(),
		LevelLabel:   result.Level.Label(),
		Score:        result.Score,
		IsSufficient: result.IsSufficient,
		DataPoints:   result.DataPoints,
		WindowDays:   result.WindowDays,
		EvaluatedAt:  apptime.FormatDateTime(result.EvaluatedAt),
		Indicators:   indicators,
	}
}

func toEmotionShares(rows []studentrepo.EmotionCount) []mentordto.EmotionShareResponse {
	total := 0
	for _, row := range rows {
		total += row.Total
	}
	out := make([]mentordto.EmotionShareResponse, 0, len(rows))
	for _, row := range rows {
		percentage := 0.0
		if total > 0 {
			percentage = round2(float64(row.Total) / float64(total) * 100)
		}
		out = append(out, mentordto.EmotionShareResponse{
			EmotionLabel: row.EmotionLabel,
			Total:        row.Total,
			Percentage:   percentage,
		})
	}
	return out
}

func ptrFloat(v float64) *float64 { return &v }
