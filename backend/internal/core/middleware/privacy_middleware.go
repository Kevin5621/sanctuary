package middleware

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// ------------------------------------------------------------------
// Privacy enforcement (server-side, tidak bisa di-bypass klien).
//
// Aturan Sanctuary:
//   - Teks Jurnal Bebas & Chat AI HANYA dapat diakses mahasiswa pemiliknya.
//     Dosen / Kaprodi / Admin tidak punya jalur API apa pun ke konten tersebut.
//   - Endpoint agregat wajib melewati ambang k-anonymity (>= 5 anggota).
// ------------------------------------------------------------------

const (
	// ContextAggregateScope menandai request sebagai jalur data agregat.
	ContextAggregateScope = "privacy_aggregate_scope"
	// HeaderPrivacyScope memudahkan audit/observability di sisi gateway.
	HeaderPrivacyScope = "X-Privacy-Scope"
)

// PrivateContentGuard mengunci seluruh route konten privat (jurnal & chat AI)
// agar hanya dapat diakses oleh role STUDENT untuk dirinya sendiri.
//
// Peran non-mahasiswa ditolak dengan PRIVATE_CONTENT_FORBIDDEN — bukan 404 —
// supaya audit log jelas memperlihatkan percobaan akses lintas peran.
func PrivateContentGuard() gin.HandlerFunc {
	return func(c *gin.Context) {
		user, ok := CurrentUser(c)
		if !ok {
			utils.Fail(c, utils.NewError(utils.CodeUnauthorized))
			return
		}

		if user.Role != constants.RoleStudent {
			utils.Fail(c, utils.NewError(utils.CodePrivateContentForbidden).WithDetails(map[string]any{
				"resource": "student_private_content",
				"role":     user.Role.String(),
			}))
			return
		}

		// Konten privat tidak boleh di-cache oleh proxy/CDN mana pun.
		c.Header("Cache-Control", "no-store, no-cache, must-revalidate, private")
		c.Header("Pragma", "no-cache")
		c.Header(HeaderPrivacyScope, "private-owner-only")
		c.Next()
	}
}

// AggregateOnly menandai grup route sebagai jalur agregat (dosen/kaprodi).
// Usecase di belakangnya WAJIB memakai utils.NewAggregateGuard() sebelum
// mengeluarkan angka apa pun.
func AggregateOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Set(ContextAggregateScope, true)
		c.Header(HeaderPrivacyScope, "aggregate")
		c.Header("Cache-Control", "no-store")
		c.Next()
	}
}

// KAnonymityGuard menolak lebih awal endpoint agregat yang ukuran kelompoknya
// sudah diketahui dari context (mis. di-set resolver sebelumnya).
// Untuk kebanyakan endpoint, ukuran kelompok baru diketahui setelah query,
// sehingga pemakaian utama tetap utils.NewAggregateGuard() di dalam usecase.
func KAnonymityGuard(groupSizeResolver func(c *gin.Context) (int, error)) gin.HandlerFunc {
	return func(c *gin.Context) {
		size, err := groupSizeResolver(c)
		if err != nil {
			utils.Fail(c, err)
			return
		}
		if !utils.IsGroupSufficient(size) {
			// 200 dengan penanda, agar UI menampilkan state "Data belum cukup".
			c.AbortWithStatusJSON(200, utils.SuccessResponse{
				Success: true,
				Data:    utils.NewAggregateGuard(size),
			})
			return
		}
		c.Next()
	}
}
