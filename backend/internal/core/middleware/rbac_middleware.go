package middleware

import (
	"github.com/gin-gonic/gin"

	"github.com/gilabs/sanctuary/internal/core/constants"
	"github.com/gilabs/sanctuary/internal/core/utils"
)

// RequireRoles membatasi route hanya untuk peran tertentu.
// Wajib dipasang SETELAH Auth().
func RequireRoles(roles ...constants.Role) gin.HandlerFunc {
	allowed := make(map[constants.Role]struct{}, len(roles))
	for _, r := range roles {
		allowed[r] = struct{}{}
	}

	return func(c *gin.Context) {
		user, ok := CurrentUser(c)
		if !ok {
			utils.Fail(c, utils.NewError(utils.CodeUnauthorized))
			return
		}
		if _, permitted := allowed[user.Role]; !permitted {
			utils.Fail(c, utils.NewError(utils.CodeRoleInsufficient).WithDetails(map[string]any{
				"required_roles": roleCodes(roles),
			}))
			return
		}
		c.Next()
	}
}

// RequireStudent adalah alias yang sering dipakai pada route milik mahasiswa.
func RequireStudent() gin.HandlerFunc { return RequireRoles(constants.RoleStudent) }

// EnforceSelfOwnership memastikan path param `id` sama dengan user pada token.
// Nilai "me" selalu diizinkan dan diterjemahkan menjadi user id token.
//
// Pertahanan berlapis: walaupun repository sudah selalu memfilter berdasarkan
// user_id dari token, guard ini mencegah endpoint baru bocor karena lupa filter.
func EnforceSelfOwnership(param string) gin.HandlerFunc {
	return func(c *gin.Context) {
		user, ok := CurrentUser(c)
		if !ok {
			utils.Fail(c, utils.NewError(utils.CodeUnauthorized))
			return
		}

		target := c.Param(param)
		if target == "" || target == "me" {
			c.Next()
			return
		}
		if !utils.SecureCompare(target, user.ID) {
			utils.Fail(c, utils.NewError(utils.CodeResourceOwnershipRequired))
			return
		}
		c.Next()
	}
}

func roleCodes(roles []constants.Role) []string {
	out := make([]string, 0, len(roles))
	for _, r := range roles {
		out = append(out, r.String())
	}
	return out
}
