package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

const ContextRequestID = "request_id"

// Meta adalah metadata pagination standar (page / per_page).
type Meta struct {
	Page       int   `json:"page"`
	PerPage    int   `json:"per_page"`
	Total      int64 `json:"total"`
	TotalPages int   `json:"total_pages"`
}

func NewMeta(page, perPage int, total int64) *Meta {
	totalPages := 0
	if perPage > 0 {
		totalPages = int((total + int64(perPage) - 1) / int64(perPage))
	}
	return &Meta{Page: page, PerPage: perPage, Total: total, TotalPages: totalPages}
}

type SuccessResponse struct {
	Success bool  `json:"success"`
	Data    any   `json:"data"`
	Meta    *Meta `json:"meta,omitempty"`
}

type ErrorBody struct {
	Code        string         `json:"code"`
	Message     string         `json:"message"`
	Details     map[string]any `json:"details,omitempty"`
	FieldErrors []FieldError   `json:"field_errors,omitempty"`
}

type ErrorResponse struct {
	Success bool      `json:"success"`
	Error   ErrorBody `json:"error"`
}

func OK(c *gin.Context, data any) {
	c.JSON(http.StatusOK, SuccessResponse{Success: true, Data: data})
}

func Created(c *gin.Context, data any) {
	c.JSON(http.StatusCreated, SuccessResponse{Success: true, Data: data})
}

func OKWithMeta(c *gin.Context, data any, meta *Meta) {
	c.JSON(http.StatusOK, SuccessResponse{Success: true, Data: data, Meta: meta})
}

func NoContent(c *gin.Context) { c.Status(http.StatusNoContent) }

// Fail menulis error response standar dan menghentikan chain handler.
func Fail(c *gin.Context, err error) {
	appErr := AsAppError(err)

	details := appErr.Details
	if rid := c.GetString(ContextRequestID); rid != "" {
		if details == nil {
			details = map[string]any{}
		}
		details["request_id"] = rid
	}

	c.AbortWithStatusJSON(appErr.HTTPStatus(), ErrorResponse{
		Success: false,
		Error: ErrorBody{
			Code:        appErr.Code,
			Message:     appErr.Message,
			Details:     details,
			FieldErrors: appErr.FieldErrors,
		},
	})
}

// FailCode adalah shortcut Fail(c, NewError(code)).
func FailCode(c *gin.Context, code string) { Fail(c, NewError(code)) }

// FailBinding mengubah error binding Gin menjadi VALIDATION_ERROR.
func FailBinding(c *gin.Context, err error) {
	Fail(c, NewError(CodeValidationError).WithDetails(map[string]any{
		"reason": err.Error(),
	}))
}
