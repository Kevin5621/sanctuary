package repositories

import (
	"context"
	"encoding/json"

	"gorm.io/datatypes"
	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/auth/data/models"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// AuditRepository menyimpan jejak akses. Kegagalan penulisan audit tidak boleh
// menggagalkan request utama, tetapi wajib ter-log (lihat pemakaian di usecase).
type AuditRepository interface {
	Record(ctx context.Context, entry AuditEntry) error
}

type AuditEntry struct {
	ActorID    string
	ActorRole  string
	Action     string
	Resource   string
	ResourceID string
	Metadata   map[string]any
	IPAddress  string
	RequestID  string
}

type auditRepository struct{ db *gorm.DB }

func NewAuditRepository(db *gorm.DB) AuditRepository { return &auditRepository{db: db} }

func (r *auditRepository) Record(ctx context.Context, entry AuditEntry) error {
	ctx, cancel := utils.DBContext(ctx)
	defer cancel()

	var meta datatypes.JSON
	if entry.Metadata != nil {
		raw, err := json.Marshal(entry.Metadata)
		if err != nil {
			return utils.WrapInternal(err)
		}
		meta = raw
	}

	log := &models.AuditLog{
		ActorID:    entry.ActorID,
		ActorRole:  entry.ActorRole,
		Action:     entry.Action,
		Resource:   entry.Resource,
		ResourceID: entry.ResourceID,
		Metadata:   meta,
		IPAddress:  entry.IPAddress,
		RequestID:  entry.RequestID,
	}
	return utils.TranslateDBError(r.db.WithContext(ctx).Create(log).Error, "")
}
