package presentation

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/data/repositories"
	"github.com/gilabs/sanctuary/internal/student/domain/service"
	"github.com/gilabs/sanctuary/internal/student/domain/usecase"
	"github.com/gilabs/sanctuary/internal/student/presentation/handler"
	"github.com/gilabs/sanctuary/internal/student/presentation/router"
)

// SharedRepositories dipakai domain mentor & program (read-only, agregat saja).
type SharedRepositories struct {
	Privacy repositories.PrivacyRepository
	Metrics repositories.DailyMetricRepository
	Dass    repositories.DassRepository
}

// RegisterRoutes melakukan wiring domain student.
//
// Seluruh route berada di bawah /students/me — tidak ada endpoint yang menerima
// student id dari klien, sehingga identitas selalu berasal dari token.
func RegisterRoutes(
	api *gin.RouterGroup,
	db *gorm.DB,
	jwt *utils.JWTManager,
	audits authrepo.AuditRepository,
) SharedRepositories {
	privacyRepo := repositories.NewPrivacyRepository(db)
	journalRepo := repositories.NewJournalRepository(db)
	metricRepo := repositories.NewDailyMetricRepository(db)
	dassRepo := repositories.NewDassRepository(db)

	privacyUC := usecase.NewPrivacyUsecase(privacyRepo, audits)
	journalUC := usecase.NewJournalUsecase(journalRepo, service.NewEmotionAnalyzer())
	dailyMetricUC := usecase.NewDailyMetricUsecase(metricRepo)

	privacyHandler := handler.NewPrivacyHandler(privacyUC)
	journalHandler := handler.NewJournalHandler(journalUC)
	dailyMetricHandler := handler.NewDailyMetricHandler(dailyMetricUC)

	group := api.Group("/students/me",
		middleware.Auth(jwt),
		middleware.RequireRoles(constants.RoleStudent),
	)
	router.RegisterPrivacyRoutes(group, privacyHandler)
	router.RegisterJournalRoutes(group, journalHandler)
	router.RegisterDailyMetricRoutes(group, dailyMetricHandler)

	return SharedRepositories{Privacy: privacyRepo, Metrics: metricRepo, Dass: dassRepo}
}
