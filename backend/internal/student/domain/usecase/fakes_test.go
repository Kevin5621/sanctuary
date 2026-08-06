package usecase

import (
	"context"
	"time"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
	"gorm.io/gorm"
)

// ------------------------------------------------------------------
// Repository palsu untuk pengujian usecase.
//
// Seluruhnya menyimpan data di memori. Yang diuji di sini adalah aturan
// bisnis (validasi tanggal, skoring, satu permintaan terbuka), bukan SQL —
// query sesungguhnya diuji lewat basis data pada lingkungan integrasi.
// ------------------------------------------------------------------

type fakeMetricRepo struct {
	saved   []models.StudentDailyMetric
	listing []models.StudentDailyMetric
	err     error
}

var _ repositories.DailyMetricRepository = (*fakeMetricRepo)(nil)

func (f *fakeMetricRepo) Upsert(_ context.Context, metric *models.StudentDailyMetric) error {
	if f.err != nil {
		return f.err
	}
	f.saved = append(f.saved, *metric)
	return nil
}

func (f *fakeMetricRepo) ExistsOnDate(context.Context, string, time.Time) (bool, error) {
	return false, nil
}

func (f *fakeMetricRepo) ListByUserRange(_ context.Context, _ string, from, to time.Time) ([]models.StudentDailyMetric, error) {
	if f.err != nil {
		return nil, f.err
	}
	out := make([]models.StudentDailyMetric, 0, len(f.listing))
	for _, m := range f.listing {
		date := apptime.StartOfDay(m.MetricDate)
		if !date.Before(from) && !date.After(to) {
			out = append(out, m)
		}
	}
	return out, nil
}

func (f *fakeMetricRepo) WeeklyTrend(context.Context, string, time.Time, time.Time) ([]repositories.WeeklyPoint, error) {
	return nil, nil
}

func (f *fakeMetricRepo) LastCheckinDates(context.Context, []string) (map[string]time.Time, error) {
	return nil, nil
}

func (f *fakeMetricRepo) AggregateForUsers(context.Context, []string, time.Time, time.Time) (repositories.GroupAggregate, error) {
	return repositories.GroupAggregate{}, nil
}

func (f *fakeMetricRepo) EmotionDistribution(context.Context, []string, time.Time, time.Time) ([]repositories.EmotionCount, error) {
	return nil, nil
}

func (f *fakeMetricRepo) CountActiveStudents(context.Context, []string, time.Time, time.Time) (int, error) {
	return 0, nil
}

// ------------------------------------------------------------------

type fakeDassRepo struct {
	created []models.Dass21Result
	listing []models.Dass21Result
	err     error
}

var _ repositories.DassRepository = (*fakeDassRepo)(nil)

func (f *fakeDassRepo) Create(_ context.Context, result *models.Dass21Result) error {
	if f.err != nil {
		return f.err
	}
	f.created = append(f.created, *result)
	return nil
}

func (f *fakeDassRepo) LatestTwoForUser(ctx context.Context, userID string) ([]models.Dass21Result, error) {
	return f.ListByUser(ctx, userID, 2)
}

func (f *fakeDassRepo) ListByUser(_ context.Context, _ string, limit int) ([]models.Dass21Result, error) {
	if f.err != nil {
		return nil, f.err
	}
	if limit > 0 && len(f.listing) > limit {
		return f.listing[:limit], nil
	}
	return f.listing, nil
}

func (f *fakeDassRepo) CountScreenedUsers(context.Context, []string) (int, error) { return 0, nil }

// ------------------------------------------------------------------

type fakeContactRepo struct {
	open      *models.StudentContactRequest
	created   []models.StudentContactRequest
	cancelled bool
	createErr error
}

var _ repositories.ContactRequestRepository = (*fakeContactRepo)(nil)

func (f *fakeContactRepo) FindOpenByStudent(context.Context, string) (*models.StudentContactRequest, error) {
	return f.open, nil
}

func (f *fakeContactRepo) Create(_ context.Context, request *models.StudentContactRequest) error {
	if f.createErr != nil {
		return f.createErr
	}
	f.created = append(f.created, *request)
	f.open = request
	return nil
}

func (f *fakeContactRepo) CancelOpenByStudent(context.Context, string) error {
	if f.open == nil {
		return utils.NewError(utils.CodeNotFound)
	}
	f.cancelled = true
	f.open = nil
	return nil
}

func (f *fakeContactRepo) ListOpenByAdvisor(context.Context, string) ([]models.StudentContactRequest, error) {
	return nil, nil
}

// ------------------------------------------------------------------

type fakeJournalRepo struct {
	created  []models.StudentJournal
	stored   []models.StudentJournal
	analyzed []models.StudentJournal
	err      error
}

var _ repositories.JournalRepository = (*fakeJournalRepo)(nil)

func (f *fakeJournalRepo) Create(_ context.Context, journal *models.StudentJournal) error {
	if f.err != nil {
		return f.err
	}
	journal.ID = "journal-" + journal.JournalDate.Format("20060102")
	f.created = append(f.created, *journal)
	return nil
}

func (f *fakeJournalRepo) ListByUser(context.Context, string, utils.Pagination) ([]models.StudentJournal, int64, error) {
	return f.stored, int64(len(f.stored)), f.err
}

func (f *fakeJournalRepo) FindByIDForUser(_ context.Context, id, _ string) (*models.StudentJournal, error) {
	for i := range f.stored {
		if f.stored[i].ID == id {
			return &f.stored[i], nil
		}
	}
	return nil, utils.NewError(utils.CodeNotFound)
}

func (f *fakeJournalRepo) UpdateAnalysis(_ context.Context, journal *models.StudentJournal) error {
	if f.err != nil {
		return f.err
	}
	f.analyzed = append(f.analyzed, *journal)
	return nil
}

func (f *fakeJournalRepo) DeleteForUser(context.Context, string, string) error { return f.err }

func (f *fakeJournalRepo) CountCrisisFlaggedForUser(context.Context, string) (int64, error) {
	return 0, nil
}

// EmotionDistributionForUser meniru GROUP BY di SQL: hanya jurnal yang sudah
// dianalisis, berlabel, dan berada di dalam rentang yang ikut dihitung.
func (f *fakeJournalRepo) EmotionDistributionForUser(_ context.Context, _ string, from, to time.Time) ([]repositories.EmotionCount, error) {
	if f.err != nil {
		return nil, f.err
	}

	counts := map[string]int{}
	for _, j := range f.stored {
		if j.AnalyzedAt == nil || j.EmotionLabel == "" {
			continue
		}
		date := apptime.StartOfDay(j.JournalDate)
		if date.Before(from) || date.After(to) {
			continue
		}
		counts[j.EmotionLabel]++
	}

	out := make([]repositories.EmotionCount, 0, len(counts))
	for label, total := range counts {
		out = append(out, repositories.EmotionCount{EmotionLabel: label, Total: total})
	}
	return out, nil
}

func (f *fakeJournalRepo) CountCrisisFlaggedForUserRange(_ context.Context, _ string, from, to time.Time) (int64, error) {
	if f.err != nil {
		return 0, f.err
	}

	var count int64
	for _, j := range f.stored {
		if !j.IsCrisisFlagged {
			continue
		}
		date := apptime.StartOfDay(j.JournalDate)
		if date.Before(from) || date.After(to) {
			continue
		}
		count++
	}
	return count, nil
}

func (f *fakeJournalRepo) ListAnalyzedByUser(_ context.Context, _ string, limit int) ([]models.StudentJournal, error) {
	if f.err != nil {
		return nil, f.err
	}
	if limit > 0 && len(f.stored) > limit {
		return f.stored[:limit], nil
	}
	return f.stored, nil
}

// ------------------------------------------------------------------

type fakeChatRepo struct {
	messages  []models.StudentChatMessage
	sessionID string
	deleted   bool
	err       error
	// lastLimit merekam limit yang diminta usecase, sehingga test dapat
	// membuktikan pemangkasan 100 giliran benar-benar terjadi di server.
	lastLimit int
}

var _ repositories.ChatRepository = (*fakeChatRepo)(nil)

func (f *fakeChatRepo) Append(_ context.Context, message *models.StudentChatMessage) error {
	if f.err != nil {
		return f.err
	}
	f.messages = append(f.messages, *message)
	return nil
}

func (f *fakeChatRepo) AppendAll(_ context.Context, messages []*models.StudentChatMessage) error {
	if f.err != nil {
		return f.err
	}
	for _, m := range messages {
		f.messages = append(f.messages, *m)
	}
	return nil
}

func (f *fakeChatRepo) ListRecentForUser(_ context.Context, _, _ string, limit int) ([]models.StudentChatMessage, error) {
	f.lastLimit = limit
	if f.err != nil {
		return nil, f.err
	}
	if limit > 0 && len(f.messages) > limit {
		return f.messages[len(f.messages)-limit:], nil
	}
	return f.messages, nil
}

func (f *fakeChatRepo) LatestSessionID(context.Context, string) (string, error) {
	return f.sessionID, f.err
}

func (f *fakeChatRepo) CountForSession(context.Context, string, string) (int64, error) {
	return int64(len(f.messages)), f.err
}

func (f *fakeChatRepo) DeleteAllForUser(context.Context, string) error {
	if f.err != nil {
		return f.err
	}
	f.deleted = true
	f.messages = nil
	return nil
}

// ------------------------------------------------------------------

type fakeConsentRepo struct {
	consent *models.AIChatConsent
	saved   []models.AIChatConsent
	err     error
}

var _ repositories.AIConsentRepository = (*fakeConsentRepo)(nil)

func (f *fakeConsentRepo) FindByUser(context.Context, string) (*models.AIChatConsent, error) {
	if f.err != nil {
		return nil, f.err
	}
	return f.consent, nil
}

func (f *fakeConsentRepo) Upsert(_ context.Context, consent *models.AIChatConsent) error {
	if f.err != nil {
		return f.err
	}
	f.saved = append(f.saved, *consent)
	f.consent = consent
	return nil
}

// ------------------------------------------------------------------

// fakeTherapist menggantikan panggilan ke Gemini.
//
// calls mencatat SETIAP pemanggilan, sehingga test dapat membuktikan hal yang
// paling penting dari D-5: penyedia pihak ketiga tidak pernah dihubungi ketika
// consent belum diberikan.
type fakeTherapist struct {
	reply string
	err   error
	calls [][]service.ChatTurn
}

var _ service.AITherapist = (*fakeTherapist)(nil)

func (f *fakeTherapist) Reply(_ context.Context, history []service.ChatTurn) (string, error) {
	f.calls = append(f.calls, history)
	if f.err != nil {
		return "", f.err
	}
	return f.reply, nil
}

// ------------------------------------------------------------------

type fakeUserRepo struct {
	user *authmodels.User
	err  error
}

func (f *fakeUserRepo) FindByEmail(context.Context, string) (*authmodels.User, error) {
	return f.user, f.err
}

func (f *fakeUserRepo) FindByID(context.Context, string) (*authmodels.User, error) {
	return f.user, f.err
}

func (f *fakeUserRepo) TouchLastLogin(context.Context, *gorm.DB, string) error { return nil }

func (f *fakeUserRepo) CountAdvisees(context.Context, string) (int64, error) { return 0, nil }
