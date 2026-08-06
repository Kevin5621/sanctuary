package presentation

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/mentor/data/repositories"
	"github.com/gilabs/sanctuary/internal/mentor/domain/usecase"
	"github.com/gilabs/sanctuary/internal/mentor/presentation/handler"
	"github.com/gilabs/sanctuary/internal/mentor/presentation/router"
	studentpresentation "github.com/gilabs/sanctuary/internal/student/presentation"
)

// RegisterRoutes melakukan wiring domain mentor dan mengembalikan EWS usecase
// agar dapat dipakai ulang domain program (sebaran EWS prodi).
func RegisterRoutes(
	api *gin.RouterGroup,
	db *gorm.DB,
	cfg *config.Config,
	jwt *utils.JWTManager,
	shared studentpresentation.SharedRepositories,
	audits authrepo.AuditRepository,
) usecase.EWSUsecase {
	adviseeRepo := repositories.NewAdviseeRepository(db)
	ewsRepo := repositories.NewEarlyWarningRepository(db)
	advisorNoteRepo := repositories.NewAdvisorNoteRepository(db)

	ewsUC := usecase.NewEWSUsecase(shared.Metrics, shared.Dass, ewsRepo, cfg.EWS)
	mentorUC := usecase.NewMentorUsecase(adviseeRepo, shared.Privacy, shared.Metrics, ewsUC, audits, advisorNoteRepo)

	mentorHandler := handler.NewMentorHandler(mentorUC)

	group := api.Group("/mentors/me",
		middleware.Auth(jwt),
		middleware.RequireRoles(constants.RoleLecturer),
	)
	router.RegisterMentorRoutes(group, mentorHandler)

	return ewsUC
}
