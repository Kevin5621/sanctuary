// Package apptime adalah satu-satunya sumber waktu aplikasi.
// Aturan standar: JANGAN memakai time.Now() di luar package ini.
package apptime

import (
	"strconv"
	"sync"
	"time"
)

const (
	LayoutDate     = "2006-01-02"
	LayoutMonth    = "2006-01"
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

// StartOfWeek mengembalikan Senin (00:00) dari minggu yang memuat t.
// Dipakai ringkasan mood mingguan agar kalender selalu mulai dari Senin,
// terlepas dari hari mana request dikirim.
func StartOfWeek(t time.Time) time.Time {
	t = StartOfDay(t)
	weekday := int(t.Weekday()) // Minggu(Sunday) = 0 .. Sabtu(Saturday) = 6
	if weekday == 0 {
		weekday = 7
	}
	return t.AddDate(0, 0, -(weekday - 1))
}

// EndOfWeek mengembalikan Minggu (00:00) dari minggu yang memuat t.
func EndOfWeek(t time.Time) time.Time { return StartOfWeek(t).AddDate(0, 0, 6) }

// StartOfMonth mengembalikan tanggal 1 (00:00) dari bulan yang memuat t.
func StartOfMonth(t time.Time) time.Time {
	t = t.In(Location())
	return time.Date(t.Year(), t.Month(), 1, 0, 0, 0, 0, Location())
}

// EndOfMonth mengembalikan hari terakhir (00:00) dari bulan yang memuat t.
func EndOfMonth(t time.Time) time.Time {
	return StartOfMonth(t).AddDate(0, 1, -1)
}

// DaysInMonth dipakai kalender mood bulanan untuk menggambar sel kosong.
func DaysInMonth(t time.Time) int { return EndOfMonth(t).Day() }

// SameMonth membandingkan dua waktu pada tingkat bulan (timezone aplikasi).
func SameMonth(a, b time.Time) bool {
	a, b = a.In(Location()), b.In(Location())
	return a.Year() == b.Year() && a.Month() == b.Month()
}

// indonesianMonths dipakai label yang dilihat pengguna; nama bulan bawaan Go
// selalu bahasa Inggris dan tidak dapat dilokalkan tanpa paket tambahan.
var indonesianMonths = [...]string{
	"Januari", "Februari", "Maret", "April", "Mei", "Juni",
	"Juli", "Agustus", "September", "Oktober", "November", "Desember",
}

// FormatMonthLabel mengembalikan "Agustus 2026".
func FormatMonthLabel(t time.Time) string {
	t = t.In(Location())
	return indonesianMonths[int(t.Month())-1] + " " + strconv.Itoa(t.Year())
}

// ParseMonth mem-parse "YYYY-MM" menjadi tanggal 1 bulan tersebut.
func ParseMonth(s string) (time.Time, error) {
	return time.ParseInLocation(LayoutMonth, s, Location())
}

func FormatMonth(t time.Time) string    { return t.In(Location()).Format(LayoutMonth) }
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
