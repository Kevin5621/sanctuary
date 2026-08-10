package database

import (
	"log"

	"gorm.io/gorm"

	authmodels "github.com/gilabs/sanctuary/internal/auth/data/models"
	mentormodels "github.com/gilabs/sanctuary/internal/mentor/data/models"
	studentmodels "github.com/gilabs/sanctuary/internal/student/data/models"
	supportmodels "github.com/gilabs/sanctuary/internal/support/data/models"
)

// AllModels adalah daftar model terdaftar (dipakai AutoMigrate dev & test).
// Sumber kebenaran skema untuk staging/production tetap ./migrations (Atlas).
func AllModels() []any {
	return []any{
		&authmodels.Role{},
		&authmodels.StudyProgram{},
		&authmodels.User{},
		&authmodels.StudentAdvisor{},
		&authmodels.RefreshToken{},
		&authmodels.AuditLog{},
		&studentmodels.StudentPrivacySetting{},
		&studentmodels.StudentDailyMetric{},
		&studentmodels.StudentJournal{},
		&studentmodels.StudentChatMessage{},
		&studentmodels.AIChatConsent{},
		&studentmodels.Dass21Result{},
		&studentmodels.StudentContactRequest{},
		&mentormodels.EarlyWarningLog{},
		&mentormodels.AdvisorNote{},
		&supportmodels.EmergencyContact{},
	}
}

// AutoMigrate hanya untuk development/test (DB_AUTO_MIGRATE=true).
func AutoMigrate(db *gorm.DB) error {
	log.Println("[db] running auto-migrate (development only)")
	return db.AutoMigrate(AllModels()...)
}
