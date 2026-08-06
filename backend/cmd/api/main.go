package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gilabs/sanctuary/apps/api/seeders"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/database"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/redis"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/router"
)

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

	if cfg.Database.AutoSeed {
		log.Println("[db] running auto-seed...")
		seedCtx, seedCancel := context.WithTimeout(context.Background(), 2*time.Minute)
		if err := seeders.New(db, cfg).Run(seedCtx); err != nil {
			seedCancel()
			log.Fatalf("auto-seed: %v", err)
		}
		seedCancel()
	}

	redisClient := redis.Connect(cfg)
	if redisClient != nil {
		defer redisClient.Close()
	}

	engine := router.New(cfg, db, redisClient)

	server := &http.Server{
		Addr:              ":" + cfg.App.Port,
		Handler:           engine,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	go func() {
		log.Printf("[api] %s listening on :%s (env=%s)", cfg.App.Name, cfg.App.Port, cfg.App.Env)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("listen: %v", err)
		}
	}()

	// Graceful shutdown: hentikan penerimaan request baru, tuntaskan yang berjalan.
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("[api] shutting down...")

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		log.Printf("[api] forced shutdown: %v", err)
	}
	log.Println("[api] stopped")
}
