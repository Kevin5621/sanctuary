package presentation

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/support/data/repositories"
	"github.com/gilabs/sanctuary/internal/support/domain/usecase"
	"github.com/gilabs/sanctuary/internal/support/presentation/handler"
	"github.com/gilabs/sanctuary/internal/support/presentation/router"
)

func RegisterRoutes(api *gin.RouterGroup, db *gorm.DB, jwt *utils.JWTManager) {
	contactRepo := repositories.NewEmergencyContactRepository(db)
	contactUC := usecase.NewEmergencyContactUsecase(contactRepo)
	contactHandler := handler.NewEmergencyContactHandler(contactUC)

	group := api.Group("/support", middleware.Auth(jwt))
	router.RegisterEmergencyContactRoutes(group, contactHandler)
}
