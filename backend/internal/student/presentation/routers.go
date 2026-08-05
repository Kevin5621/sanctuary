package presentation

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
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
	Privacy         repositories.PrivacyRepository
	Metrics         repositories.DailyMetricRepository
	Dass            repositories.DassRepository
	ContactRequests repositories.ContactRequestRepository
}

// RegisterRoutes melakukan wiring domain student.
//
// Seluruh route berada di bawah /students/me — tidak ada endpoint yang menerima
// student id dari klien, sehingga identitas selalu berasal dari token.
func RegisterRoutes(
	api *gin.RouterGroup,
	db *gorm.DB,
	cfg *config.Config,
	jwt *utils.JWTManager,
	users authrepo.UserRepository,
	audits authrepo.AuditRepository,
) SharedRepositories {
	privacyRepo := repositories.NewPrivacyRepository(db)
	journalRepo := repositories.NewJournalRepository(db)
	metricRepo := repositories.NewDailyMetricRepository(db)
	dassRepo := repositories.NewDassRepository(db)
	contactRepo := repositories.NewContactRequestRepository(db)

	privacyUC := usecase.NewPrivacyUsecase(privacyRepo, audits)
	journalUC := usecase.NewJournalUsecase(journalRepo, service.NewEmotionAnalyzer())
	dailyMetricUC := usecase.NewDailyMetricUsecase(metricRepo, cfg.Student)
	dassUC := usecase.NewDassUsecase(dassRepo)
	contactUC := usecase.NewContactRequestUsecase(contactRepo, users)

	privacyHandler := handler.NewPrivacyHandler(privacyUC)
	journalHandler := handler.NewJournalHandler(journalUC)
	dailyMetricHandler := handler.NewDailyMetricHandler(dailyMetricUC)
	dassHandler := handler.NewDassHandler(dassUC)
	contactHandler := handler.NewContactRequestHandler(contactUC)

	group := api.Group("/students/me",
		middleware.Auth(jwt),
		middleware.RequireRoles(constants.RoleStudent),
	)
	router.RegisterPrivacyRoutes(group, privacyHandler)
	router.RegisterJournalRoutes(group, journalHandler)
	router.RegisterDailyMetricRoutes(group, dailyMetricHandler)
	router.RegisterDassRoutes(group, dassHandler)
	router.RegisterContactRequestRoutes(group, contactHandler)

	return SharedRepositories{
		Privacy:         privacyRepo,
		Metrics:         metricRepo,
		Dass:            dassRepo,
		ContactRequests: contactRepo,
	}
}
