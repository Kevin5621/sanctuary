package router

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/auth/presentation/handler"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// RegisterAuthRoutes memasang endpoint sesi.
// Login & refresh dilindungi rate limit per-IP yang lebih ketat.
func RegisterAuthRoutes(
	rg *gin.RouterGroup,
	h *handler.AuthHandler,
	jwtManager *utils.JWTManager,
	limiter *middleware.RateLimiter,
	cfg *config.Config,
) {
	g := rg.Group("/auth")

	loginLimit := limiter.Limit("login_ip", cfg.RateLimit.LoginPerMinute, middleware.KeyByIP)

	g.POST("/login", loginLimit, h.Login)
	g.POST("/refresh", loginLimit, h.Refresh)

	authenticated := g.Group("", middleware.Auth(jwtManager))
	authenticated.POST("/logout", h.Logout)
	authenticated.GET("/me", h.Me)
}
