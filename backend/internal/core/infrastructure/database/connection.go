package database

import (
	"context"
	"fmt"
	"log"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"

	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
)

// Connect membuka koneksi PostgreSQL dengan connection pool sesuai standar performa.
func Connect(cfg *config.Config) (*gorm.DB, error) {
	logLevel := gormlogger.Warn
	if cfg.App.LogLevel == "debug" {
		logLevel = gormlogger.Info
	}

	db, err := gorm.Open(postgres.Open(cfg.Database.DSN), &gorm.Config{
		Logger:                 gormlogger.Default.LogMode(logLevel),
		SkipDefaultTransaction: true,
		PrepareStmt:            true,
		NowFunc:                func() time.Time { return time.Now().UTC() },
		// Tanpa ini, pelanggaran unique index datang sebagai error driver mentah
		// dan berakhir sebagai 500 — padahal utils.TranslateDBError sudah
		// menyiapkan pemetaan gorm.ErrDuplicatedKey → RESOURCE_ALREADY_EXISTS.
		// Relevan pada dua pendaftaran bersamaan dengan email/NIM yang sama:
		// yang kalah balapan berhak tahu datanya bentrok, bukan disuguhi
		// "kesalahan server".
		TranslateError: true,
	})
	if err != nil {
		return nil, fmt.Errorf("open postgres: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("get sql.DB: %w", err)
	}
	sqlDB.SetMaxOpenConns(cfg.Database.MaxOpenConns)
	sqlDB.SetMaxIdleConns(cfg.Database.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(cfg.Database.ConnMaxLifetime)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := sqlDB.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("ping postgres: %w", err)
	}

	log.Printf("[db] connected (max_open=%d, max_idle=%d)", cfg.Database.MaxOpenConns, cfg.Database.MaxIdleConns)
	return db, nil
}

// Close menutup pool saat graceful shutdown.
func Close(db *gorm.DB) {
	if db == nil {
		return
	}
	if sqlDB, err := db.DB(); err == nil {
		_ = sqlDB.Close()
	}
}
