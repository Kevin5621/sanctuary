package router_test

import (
	"testing"

	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/program/presentation/handler"
	"github.com/gilabs/sanctuary/internal/program/presentation/router"
)

// Gin panik saat dua pola route bertabrakan (statis vs parameter pada segmen
// yang sama). Pendaftaran rute alokasi pembimbing menambah dua pola berparameter
// di bawah /advisors dan /students yang sudah punya rute statis, jadi tabrakan
// itu harus ketahuan di sini — bukan saat server dinyalakan.
func TestProgramRoutesRegisterWithoutConflict(t *testing.T) {
	gin.SetMode(gin.TestMode)
	engine := gin.New()

	router.RegisterProgramRoutes(engine.Group("/programs/me"), handler.NewProgramHandler(nil))

	want := map[string]string{
		"GET /programs/me/advisors":                     "",
		"PUT /programs/me/advisors/:advisorId/advisees": "",
		"GET /programs/me/students":                     "",
		"PUT /programs/me/students/:studentId/advisors": "",
	}
	for _, route := range engine.Routes() {
		delete(want, route.Method+" "+route.Path)
	}
	for missing := range want {
		t.Errorf("route %q tidak terdaftar", missing)
	}
}
