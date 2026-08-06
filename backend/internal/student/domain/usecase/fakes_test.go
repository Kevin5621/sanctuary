package usecase

import (
	"context"
	"time"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/models"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
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

// Bagian tulis & kelola akun tidak dipakai usecase mahasiswa; hanya ada agar
// fake ini tetap memenuhi kontrak repository.

func (f *fakeUserRepo) Create(context.Context, *authmodels.User) error { return f.err }

func (f *fakeUserRepo) Update(context.Context, *authmodels.User, map[string]any) error {
	return f.err
}

func (f *fakeUserRepo) List(context.Context, utils.Pagination, authrepo.UserFilter) ([]authmodels.User, int64, error) {
	return nil, 0, f.err
}

func (f *fakeUserRepo) EmailTaken(context.Context, string, string) (bool, error) {
	return false, f.err
}

func (f *fakeUserRepo) StudentNumberTaken(context.Context, string, string) (bool, error) {
	return false, f.err
}

func (f *fakeUserRepo) LecturerNumberTaken(context.Context, string, string) (bool, error) {
	return false, f.err
}
