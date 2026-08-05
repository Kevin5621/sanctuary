// Package apptime adalah satu-satunya sumber waktu aplikasi.
// Aturan standar: JANGAN memakai time.Now() di luar package ini.
package apptime

import (
	"sync"
	"time"
)

const (
	LayoutDate     = "2006-01-02"
	LayoutDateTime = time.RFC3339
	LayoutDisplay  = "02 Jan 2006"
)

var (
	mu  sync.RWMutex
	loc = time.UTC
)

// Init dipanggil sekali saat startup dengan nilai config APP_TIMEZONE.
func Init(tz string) error {
	if tz == "" {
		return nil
	}
	l, err := time.LoadLocation(tz)
	if err != nil {
		return err
	}
	mu.Lock()
	loc = l
	mu.Unlock()
	return nil
}

func Location() *time.Location {
	mu.RLock()
	defer mu.RUnlock()
	return loc
}

// Now mengembalikan waktu sekarang pada timezone aplikasi.
func Now() time.Time { return time.Now().In(Location()) }

// Today mengembalikan tanggal hari ini (jam 00:00) pada timezone aplikasi.
func Today() time.Time { return StartOfDay(Now()) }

func StartOfDay(t time.Time) time.Time {
	t = t.In(Location())
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, Location())
}

// DaysAgo dipakai window analitik (EWS lookback, agregat 30/90/120 hari).
func DaysAgo(days int) time.Time { return Today().AddDate(0, 0, -days) }

func FormatDate(t time.Time) string     { return t.In(Location()).Format(LayoutDate) }
func FormatDateTime(t time.Time) string { return t.In(Location()).Format(LayoutDateTime) }

// ParseDate mem-parse "YYYY-MM-DD" pada timezone aplikasi (dipakai backdate check-in).
func ParseDate(s string) (time.Time, error) {
	return time.ParseInLocation(LayoutDate, s, Location())
}

// FormatDatePtr aman untuk field nullable pada mapper/DTO.
func FormatDatePtr(t *time.Time) *string {
	if t == nil {
		return nil
	}
	s := FormatDate(*t)
	return &s
}

func FormatDateTimePtr(t *time.Time) *string {
	if t == nil {
		return nil
	}
	s := FormatDateTime(*t)
	return &s
}
