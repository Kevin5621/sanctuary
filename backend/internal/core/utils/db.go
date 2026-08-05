package utils

import (
	"context"
	"errors"
	"time"

	"gorm.io/gorm"
)

var configDBTimeout = 5 * time.Second

// ConfigureDBTimeout dipanggil sekali dari config saat startup.
func ConfigureDBTimeout(d time.Duration) {
	if d > 0 {
		configDBTimeout = d
	}
}

// DBContext membungkus context request dengan batas waktu query.
// Seluruh repository WAJIB memakainya (api-security-standards.md §9).
func DBContext(ctx context.Context) (context.Context, context.CancelFunc) {
	return context.WithTimeout(ctx, configDBTimeout)
}

// TranslateDBError memetakan error GORM ke AppError standar.
func TranslateDBError(err error, notFoundCode string) error {
	switch {
	case err == nil:
		return nil
	case errors.Is(err, gorm.ErrRecordNotFound):
		if notFoundCode == "" {
			notFoundCode = CodeNotFound
		}
		return NewError(notFoundCode)
	case errors.Is(err, gorm.ErrDuplicatedKey):
		return NewError(CodeResourceAlreadyExists)
	case errors.Is(err, context.DeadlineExceeded):
		return NewError(CodeQueryTimeout).WithCause(err)
	default:
		return NewError(CodeDatabaseError).WithCause(err)
	}
}
