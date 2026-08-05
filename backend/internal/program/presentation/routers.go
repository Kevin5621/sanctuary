package presentation

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	mentorusecase "github.com/gilabs/sanctuary/internal/mentor/domain/usecase"
	"github.com/gilabs/sanctuary/internal/program/data/repositories"
	"github.com/gilabs/sanctuary/internal/program/domain/usecase"
	"github.com/gilabs/sanctuary/internal/program/presentation/handler"
	"github.com/gilabs/sanctuary/internal/program/presentation/router"
	studentpresentation "github.com/gilabs/sanctuary/internal/student/presentation"
)

func RegisterRoutes(
	api *gin.RouterGroup,
	db *gorm.DB,
	jwt *utils.JWTManager,
	shared studentpresentation.SharedRepositories,
	ews mentorusecase.EWSUsecase,
	audits authrepo.AuditRepository,
) {
	programRepo := repositories.NewProgramRepository(db)
	programUC := usecase.NewProgramUsecase(programRepo, shared.Metrics, shared.Dass, ews, audits)
	programHandler := handler.NewProgramHandler(programUC)

	group := api.Group("/programs/me",
		middleware.Auth(jwt),
		middleware.RequireRoles(constants.RoleHeadOfProgram),
	)
	router.RegisterProgramRoutes(group, programHandler)
}
