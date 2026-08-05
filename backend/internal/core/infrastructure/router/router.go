package router

import (
	"net/http"

	"github.com/gin-gonic/gin"
	goredis "github.com/redis/go-redis/v9"
	"gorm.io/gorm"

	authpresentation "github.com/gilabs/sanctuary/internal/auth/presentation"
	"github.com/gilabs/sanctuary/internal/core/apptime"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	mentorpresentation "github.com/gilabs/sanctuary/internal/mentor/presentation"
	programpresentation "github.com/gilabs/sanctuary/internal/program/presentation"
	studentpresentation "github.com/gilabs/sanctuary/internal/student/presentation"
	supportpresentation "github.com/gilabs/sanctuary/internal/support/presentation"
)

// New membangun engine Gin lengkap dengan middleware global dan seluruh domain.
func New(cfg *config.Config, db *gorm.DB, redisClient *goredis.Client) *gin.Engine {
	if cfg.App.IsProduction() {
		gin.SetMode(gin.ReleaseMode)
	}

	engine := gin.New()
	engine.RedirectTrailingSlash = false

	// Urutan middleware penting: request id → recovery → keamanan → CSRF.
	engine.Use(
		middleware.RequestID(),
		middleware.Recovery(),
		middleware.SecurityHeaders(cfg),
		middleware.CORS(cfg),
		middleware.BodyLimit(),
		middleware.CSRF(),
		middleware.AccessLog(),
	)

	engine.NoRoute(func(c *gin.Context) { utils.FailCode(c, utils.CodeNotFound) })

	jwtManager := utils.NewJWTManager(
		cfg.Security.JWTSecret,
		cfg.App.Name,
		cfg.Security.AccessTTL,
		cfg.Security.RefreshTTL,
	)
	limiter := middleware.NewRateLimiter(redisClient, cfg.RateLimit.FailClosed)

	engine.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": cfg.App.Name,
			"time":    apptime.FormatDateTime(apptime.Now()),
		})
	})

	api := engine.Group("/api/v1")
	api.Use(limiter.Limit("general", cfg.RateLimit.GeneralPerMinute, middleware.KeyByUser))

	Register(api, cfg, db, jwtManager, limiter)
	return engine
}

// Register memasang seluruh domain vertical slice.
//
// Urutan wiring mengikuti arah ketergantungan data:
// auth → student (repo bersama) → mentor (EWS) → program → support.
func Register(
	api *gin.RouterGroup,
	cfg *config.Config,
	db *gorm.DB,
	jwtManager *utils.JWTManager,
	limiter *middleware.RateLimiter,
) {
	_, auditRepo := authpresentation.RegisterRoutes(api, authpresentation.Deps{
		DB:      db,
		Config:  cfg,
		JWT:     jwtManager,
		Limiter: limiter,
	})

	shared := studentpresentation.RegisterRoutes(api, db, jwtManager, auditRepo)
	ewsUC := mentorpresentation.RegisterRoutes(api, db, cfg, jwtManager, shared, auditRepo)
	programpresentation.RegisterRoutes(api, db, jwtManager, shared, ewsUC, auditRepo)
	supportpresentation.RegisterRoutes(api, db, jwtManager)
}
