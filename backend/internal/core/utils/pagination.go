package utils

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm/clause"
)

// Nilai fallback bila config belum di-set (api-configuration-standards.md).
const (
	fallbackDefaultPerPage = 20
	fallbackMaxPerPage     = 20
)

var (
	configDefaultPerPage = fallbackDefaultPerPage
	configMaxPerPage     = fallbackMaxPerPage
)

// ConfigurePagination dipanggil sekali dari config saat startup.
func ConfigurePagination(defaultPerPage, maxPerPage int) {
	if defaultPerPage > 0 {
		configDefaultPerPage = defaultPerPage
	}
	if maxPerPage > 0 {
		configMaxPerPage = maxPerPage
	}
}

type Pagination struct {
	Page    int    `json:"page"`
	PerPage int    `json:"per_page"`
	Search  string `json:"search,omitempty"`
	SortBy  string `json:"sort_by,omitempty"`
	SortDir string `json:"sort_dir,omitempty"`
}

func (p Pagination) Offset() int { return (p.Page - 1) * p.PerPage }

// NormalizePagination membatasi page/per_page ke rentang aman.
// Semua handler/usecase/repository WAJIB lewat fungsi ini.
func NormalizePagination(page, perPage int) (int, int) {
	if page < 1 {
		page = 1
	}
	if perPage < 1 {
		perPage = configDefaultPerPage
	}
	if perPage > configMaxPerPage {
		perPage = configMaxPerPage
	}
	return page, perPage
}

// ParsePagination membaca query `page` & `per_page` (alias `limit` sengaja tidak didukung).
func ParsePagination(c *gin.Context) Pagination {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "0"))
	page, perPage = NormalizePagination(page, perPage)

	sortDir := c.Query("sort_dir")
	if sortDir != "desc" {
		sortDir = "asc"
	}

	return Pagination{
		Page:    page,
		PerPage: perPage,
		Search:  c.Query("q"),
		SortBy:  c.Query("sort_by"),
		SortDir: sortDir,
	}
}

// SafeOrderBy membangun ORDER BY dari whitelist kolom (anti SQL injection).
// allowed: map[queryValue]actualColumn, mis. {"name": "users.full_name"}.
func SafeOrderBy(sortBy, sortDir string, allowed map[string]string, fallback string) clause.OrderByColumn {
	column, ok := allowed[sortBy]
	if !ok {
		column = fallback
	}
	return clause.OrderByColumn{
		Column: clause.Column{Name: column, Raw: true},
		Desc:   sortDir == "desc",
	}
}
