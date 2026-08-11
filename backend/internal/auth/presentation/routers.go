package presentation

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/auth/domain/usecase"
	"github.com/gilabs/sanctuary/internal/auth/presentation/handler"
	"github.com/gilabs/sanctuary/internal/auth/presentation/router"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// Deps adalah dependency lintas domain yang di-share dari core.
type Deps struct {
	DB      *gorm.DB
	Config  *config.Config
	JWT     *utils.JWTManager
	Limiter *middleware.RateLimiter
}

// SharedRepositories adalah repository auth yang dipakai ulang domain lain.
type SharedRepositories struct {
	Users  repositories.UserRepository
	Audits repositories.AuditRepository
	// StudentAdvisors dipakai domain student (kartu pembimbing & "minta
	// dihubungi"): relasi bimbingan hidup di tabel users, jadi pembacaannya
	// tetap milik slice auth.
	StudentAdvisors repositories.StudentAdvisorRepository
}

// RegisterRoutes melakukan wiring domain auth dan mengembalikan repository
// yang dipakai ulang domain lain.
func RegisterRoutes(api *gin.RouterGroup, deps Deps) SharedRepositories {
	userRepo := repositories.NewUserRepository(deps.DB)
	tokenRepo := repositories.NewRefreshTokenRepository(deps.DB)
	auditRepo := repositories.NewAuditRepository(deps.DB)
	roleRepo := repositories.NewRoleRepository(deps.DB)
	programRepo := repositories.NewStudyProgramRepository(deps.DB)
	studentAdvisorRepo := repositories.NewStudentAdvisorRepository(deps.DB)

	authUC := usecase.NewAuthUsecase(
		deps.DB, userRepo, tokenRepo, auditRepo, roleRepo, programRepo,
		deps.JWT, deps.Limiter, deps.Config,
	)
	authHandler := handler.NewAuthHandler(authUC, deps.Config)
	router.RegisterAuthRoutes(api, authHandler, deps.JWT, deps.Limiter, deps.Config)

	// Kelola akun dosen & kaprodi tinggal satu slice dengan auth: ia menyentuh
	// tabel dan invarian yang sama (peran, identitas, sesi aktif).
	userMgmtUC := usecase.NewUserManagementUsecase(userRepo, roleRepo, programRepo, tokenRepo, auditRepo)
	router.RegisterUserManagementRoutes(api, handler.NewUserManagementHandler(userMgmtUC), deps.JWT)

	return SharedRepositories{
		Users:           userRepo,
		Audits:          auditRepo,
		StudentAdvisors: studentAdvisorRepo,
	}
}
