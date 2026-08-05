package middleware

import (
	"context"
	"fmt"
	"log"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"

	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// RateLimiter adalah fixed-window limiter berbasis Redis (multi-instance safe).
type RateLimiter struct {
	client     *redis.Client
	failClosed bool
}

func NewRateLimiter(client *redis.Client, failClosed bool) *RateLimiter {
	return &RateLimiter{client: client, failClosed: failClosed}
}

// Limit membatasi `limit` request per menit per kunci.
// keyFunc menentukan granularitas (per IP, per email, per user).
func (rl *RateLimiter) Limit(scope string, limit int, keyFunc func(c *gin.Context) string) gin.HandlerFunc {
	return func(c *gin.Context) {
		if rl == nil || rl.client == nil {
			// Limiter backend tidak dikonfigurasi (dev lokal): fail-open + peringatan.
			c.Next()
			return
		}

		window := apptime.Now().Truncate(time.Minute).Unix()
		key := fmt.Sprintf("rl:%s:%s:%d", scope, keyFunc(c), window)

		ctx, cancel := context.WithTimeout(c.Request.Context(), 200*time.Millisecond)
		defer cancel()

		count, err := rl.client.Incr(ctx, key).Result()
		if err != nil {
			log.Printf("[ratelimit] backend error scope=%s err=%v fail_closed=%v", scope, err, rl.failClosed)
			if rl.failClosed {
				// Endpoint kritikal (auth) memilih fail-closed agar tidak bisa
				// di-bypass massal saat Redis bermasalah.
				c.Header("Retry-After", "60")
				utils.Fail(c, utils.NewError(utils.CodeServiceUnavailable))
				return
			}
			c.Next()
			return
		}
		if count == 1 {
			rl.client.Expire(ctx, key, 70*time.Second)
		}

		remaining := limit - int(count)
		if remaining < 0 {
			remaining = 0
		}
		c.Header("X-RateLimit-Limit", strconv.Itoa(limit))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(remaining))

		if int(count) > limit {
			c.Header("Retry-After", "60")
			utils.Fail(c, utils.NewError(utils.CodeRateLimitExceeded))
			return
		}
		c.Next()
	}
}

// KeyByIP dipakai limit global (mis. login per IP).
func KeyByIP(c *gin.Context) string { return c.ClientIP() }

// KeyByUser dipakai limit endpoint terautentikasi.
func KeyByUser(c *gin.Context) string {
	if id := c.GetString(ContextUserID); id != "" {
		return "u:" + id
	}
	return "ip:" + c.ClientIP()
}

// Allow adalah pemeriksaan limiter programatik untuk kunci yang baru diketahui
// setelah body dibaca — dipakai auth usecase untuk limit per-email
// (brute-force pada satu akun) yang tidak bisa dilakukan di layer middleware.
func (rl *RateLimiter) Allow(ctx context.Context, scope, key string, limit int) (bool, error) {
	if rl == nil || rl.client == nil {
		return true, nil
	}

	window := apptime.Now().Truncate(time.Minute).Unix()
	redisKey := fmt.Sprintf("rl:%s:%s:%d", scope, key, window)

	ctx, cancel := context.WithTimeout(ctx, 200*time.Millisecond)
	defer cancel()

	count, err := rl.client.Incr(ctx, redisKey).Result()
	if err != nil {
		log.Printf("[ratelimit] backend error scope=%s err=%v fail_closed=%v", scope, err, rl.failClosed)
		return !rl.failClosed, err
	}
	if count == 1 {
		rl.client.Expire(ctx, redisKey, 70*time.Second)
	}
	return int(count) <= limit, nil
}
