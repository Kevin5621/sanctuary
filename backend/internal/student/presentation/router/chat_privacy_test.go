package router_test

// M-AI-05 / I-1 — audit guard privasi untuk rute Terapis AI.
//
// Test ini melengkapi C-15 (privacy_leak_test.go) dari sisi yang berbeda:
// C-15 memindai BENTUK DATA yang mengalir ke peran lain, sedangkan berkas ini
// memeriksa PERMUKAAN RUTE. Keduanya dibutuhkan — DTO yang bersih tidak
// menolong bila rutenya ternyata dapat dipanggil dosen.
//
// Pendekatannya sengaja meng-ENUMERASI seluruh route yang terdaftar pada grup
// /chats, bukan menuliskan daftar path secara manual. Alasannya sama dengan
// C-15: route yang ditambahkan enam bulan lagi harus ikut teruji tanpa ada
// yang perlu mengingat untuk menambahkannya ke test ini.

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/middleware"
	"github.com/gilabs/sanctuary/internal/core/utils"
	"github.com/gilabs/sanctuary/internal/student/presentation/handler"
	"github.com/gilabs/sanctuary/internal/student/presentation/router"
)

// asRole memasang identitas terverifikasi seolah-olah Auth middleware sudah
// berjalan, sehingga yang diuji murni PrivateContentGuard.
func asRole(role constants.Role) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Set(middleware.ContextUserID, "user-"+role.String())
		c.Set(middleware.ContextUserRole, role.String())
		c.Next()
	}
}

// buildChatRouter mendaftarkan rute chat persis seperti produksi.
//
// Handler dibangun dengan usecase nil secara sengaja: bila guard bekerja, tidak
// ada satu pun handler yang terpanggil untuk peran non-mahasiswa. Kalau guard
// bocor, test akan panic — kegagalan yang keras dan mustahil terlewat.
func buildChatRouter(role constants.Role) *gin.Engine {
	gin.SetMode(gin.TestMode)
	engine := gin.New()

	group := engine.Group("/api/v1/students/me", asRole(role))
	router.RegisterChatRoutes(group, handler.NewChatHandler(nil))
	return engine
}

// chatRoutes mengembalikan seluruh route chat yang benar-benar terdaftar.
func chatRoutes(t *testing.T) []gin.RouteInfo {
	t.Helper()

	var out []gin.RouteInfo
	for _, route := range buildChatRouter(constants.RoleStudent).Routes() {
		if strings.Contains(route.Path, "/chats") {
			out = append(out, route)
		}
	}
	if len(out) == 0 {
		t.Fatal("tidak ada route /chats terpindai — audit ini jadi tidak berarti")
	}
	return out
}

// TestChatRoutesRejectNonStudentRoles adalah inti I-1: isi percakapan Terapis
// AI tidak punya jalur API untuk peran mana pun selain pemiliknya, TERMASUK
// admin. Bila suatu saat ada yang menambahkan route chat di luar grup ber-guard,
// test ini gagal.
func TestChatRoutesRejectNonStudentRoles(t *testing.T) {
	forbiddenRoles := []constants.Role{
		constants.RoleLecturer,
		constants.RoleHeadOfProgram,
		constants.RoleAdmin,
	}

	for _, role := range forbiddenRoles {
		for _, route := range chatRoutes(t) {
			engine := buildChatRouter(role)

			req := httptest.NewRequest(route.Method, route.Path, strings.NewReader("{}"))
			req.Header.Set("Content-Type", "application/json")
			rec := httptest.NewRecorder()
			engine.ServeHTTP(rec, req)

			if rec.Code != http.StatusForbidden {
				t.Errorf("KEBOCORAN PRIVASI (I-1): %s %s untuk peran %s menghasilkan status %d, harusnya 403",
					route.Method, route.Path, role, rec.Code)
				continue
			}

			var body utils.ErrorResponse
			if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
				t.Errorf("%s %s: response bukan amplop error standar: %v", route.Method, route.Path, err)
				continue
			}
			if body.Error.Code != utils.CodePrivateContentForbidden {
				t.Errorf("%s %s peran %s: kode error %q, harusnya %q — audit log perlu membedakan "+
					"percobaan akses lintas peran dari 404 biasa",
					route.Method, route.Path, role, body.Error.Code, utils.CodePrivateContentForbidden)
			}
		}
	}
}

// TestChatRoutesRejectUnauthenticated menjaga agar guard tidak dapat dilewati
// dengan request tanpa identitas sama sekali.
func TestChatRoutesRejectUnauthenticated(t *testing.T) {
	for _, route := range chatRoutes(t) {
		gin.SetMode(gin.TestMode)
		engine := gin.New()
		// Tanpa middleware identitas apa pun.
		group := engine.Group("/api/v1/students/me")
		router.RegisterChatRoutes(group, handler.NewChatHandler(nil))

		req := httptest.NewRequest(route.Method, route.Path, strings.NewReader("{}"))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		engine.ServeHTTP(rec, req)

		if rec.Code != http.StatusUnauthorized {
			t.Errorf("%s %s tanpa identitas menghasilkan %d, harusnya 401",
				route.Method, route.Path, rec.Code)
		}
	}
}

// TestChatRoutesSetNoStoreHeaders: isi percakapan tidak boleh mengendap di
// cache proxy/CDN mana pun.
func TestChatRoutesSetNoStoreHeaders(t *testing.T) {
	gin.SetMode(gin.TestMode)
	engine := gin.New()

	group := engine.Group("/api/v1/students/me", asRole(constants.RoleStudent))
	// Handler tiruan: yang diperiksa adalah header yang dipasang guard.
	group.Group("/chats", middleware.PrivateContentGuard()).
		GET("/probe", func(c *gin.Context) { c.Status(http.StatusOK) })

	req := httptest.NewRequest(http.MethodGet, "/api/v1/students/me/chats/probe", nil)
	rec := httptest.NewRecorder()
	engine.ServeHTTP(rec, req)

	if cache := rec.Header().Get("Cache-Control"); !strings.Contains(cache, "no-store") {
		t.Errorf("Cache-Control = %q, konten privat wajib no-store", cache)
	}
	if scope := rec.Header().Get(middleware.HeaderPrivacyScope); scope != "private-owner-only" {
		t.Errorf("%s = %q, harusnya private-owner-only", middleware.HeaderPrivacyScope, scope)
	}
}
