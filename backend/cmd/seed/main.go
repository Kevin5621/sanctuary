package main

import (
	"context"
	"log"
	"time"

	"github.com/gilabs/sanctuary/apps/api/seeders"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/database"
)

// Runner seeder: `go run ./cmd/seed`
//
// Seeder bersifat idempotent sehingga aman dijalankan berulang pada lingkungan
// development/staging. Untuk produksi, jalankan hanya secara eksplisit dan
// terkontrol (lihat api-configuration-standards.md).
func main() {
	cfg := config.MustLoad()

	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer database.Close(db)

	if cfg.Database.AutoMigrate {
		if err := database.AutoMigrate(db); err != nil {
			log.Fatalf("auto-migrate: %v", err)
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	if err := seeders.New(db, cfg).Run(ctx); err != nil {
		log.Fatalf("seed: %v", err)
	}
}
