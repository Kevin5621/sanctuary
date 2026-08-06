package presentation

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	authrepo "github.com/gilabs/sanctuary/internal/auth/data/repositories"
	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/config"
	"github.com/gilabs/sanctuary/internal/core/infrastructure/gemini"
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
	chatRepo := repositories.NewChatRepository(db)
	consentRepo := repositories.NewAIConsentRepository(db)

	// Penyedia AI hanya dibangun bila GEMINI_API_KEY benar-benar terisi.
	// Bila kosong, therapist bernilai nil dan usecase menjawab dengan pesan
	// "belum aktif" — tidak ada teks mahasiswa yang dikirim ke mana pun.
	var therapist service.AITherapist
	if cfg.AI.Enabled() {
		therapist = gemini.New(cfg.AI)
	}

	privacyUC := usecase.NewPrivacyUsecase(privacyRepo, audits)
	journalUC := usecase.NewJournalUsecase(journalRepo, service.NewEmotionAnalyzer(), cfg.Student)
	dailyMetricUC := usecase.NewDailyMetricUsecase(metricRepo, cfg.Student)
	dassUC := usecase.NewDassUsecase(dassRepo)
	contactUC := usecase.NewContactRequestUsecase(contactRepo, users)
	chatUC := usecase.NewChatUsecase(chatRepo, consentRepo, therapist, cfg.AI)

	privacyHandler := handler.NewPrivacyHandler(privacyUC)
	journalHandler := handler.NewJournalHandler(journalUC)
	dailyMetricHandler := handler.NewDailyMetricHandler(dailyMetricUC)
	dassHandler := handler.NewDassHandler(dassUC)
	contactHandler := handler.NewContactRequestHandler(contactUC)
	chatHandler := handler.NewChatHandler(chatUC)

	group := api.Group("/students/me",
		middleware.Auth(jwt),
		middleware.RequireRoles(constants.RoleStudent),
	)
	router.RegisterPrivacyRoutes(group, privacyHandler)
	router.RegisterJournalRoutes(group, journalHandler)
	router.RegisterChatRoutes(group, chatHandler)
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
