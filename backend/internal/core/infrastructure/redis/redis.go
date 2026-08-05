package redis

import (
	"context"
	"log"
	"time"

	goredis "github.com/redis/go-redis/v9"

	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
)

// Connect mengembalikan client Redis, atau nil bila REDIS_ADDR kosong.
// Nil client membuat rate limiter berjalan mode degrade (dev lokal).
func Connect(cfg *config.Config) *goredis.Client {
	if !cfg.Redis.Enabled() {
		log.Println("[redis] disabled (REDIS_ADDR empty) — rate limiter runs in degraded mode")
		return nil
	}

	client := goredis.NewClient(&goredis.Options{
		Addr:         cfg.Redis.Addr,
		Password:     cfg.Redis.Password,
		DB:           cfg.Redis.DB,
		DialTimeout:  2 * time.Second,
		ReadTimeout:  200 * time.Millisecond,
		WriteTimeout: 200 * time.Millisecond,
		PoolSize:     20,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := client.Ping(ctx).Err(); err != nil {
		log.Printf("[redis] ping failed: %v — continuing without cache", err)
		_ = client.Close()
		return nil
	}

	log.Printf("[redis] connected to %s", cfg.Redis.Addr)
	return client
}
