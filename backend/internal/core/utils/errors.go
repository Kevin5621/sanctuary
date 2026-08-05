package utils

import (
	"errors"
	"fmt"
	"net/http"
)

// ErrorInfo memetakan kode error ke HTTP status + pesan default.
// Sesuai ./api-standart/api-error-codes.md
type ErrorInfo struct {
	HTTPStatus int
	Message    string
}

// Kode error umum (lihat api-error-codes.md).
const (
	// 400
	CodeValidationError    = "VALIDATION_ERROR"
	CodeInvalidRequestBody = "INVALID_REQUEST_BODY"
	CodeInvalidQueryParam  = "INVALID_QUERY_PARAM"
	CodeInvalidPathParam   = "INVALID_PATH_PARAM"
	CodeInvalidDate        = "INVALID_DATE"
	CodeInvalidEnum        = "INVALID_ENUM"

	// 401
	CodeUnauthorized        = "UNAUTHORIZED"
	CodeTokenExpired        = "TOKEN_EXPIRED"
	CodeTokenInvalid        = "TOKEN_INVALID"
	CodeTokenMissing        = "TOKEN_MISSING"
	CodeInvalidCredentials  = "INVALID_CREDENTIALS"
	CodeAccountDisabled     = "ACCOUNT_DISABLED"
	CodeRefreshTokenInvalid = "REFRESH_TOKEN_INVALID"
	CodeRefreshTokenExpired = "REFRESH_TOKEN_EXPIRED"

	// 403
	CodeForbidden                 = "FORBIDDEN"
	CodePermissionDenied          = "PERMISSION_DENIED"
	CodeRoleInsufficient          = "ROLE_INSUFFICIENT"
	CodeResourceOwnershipRequired = "RESOURCE_OWNERSHIP_REQUIRED"
	CodeCSRFTokenInvalid          = "CSRF_TOKEN_INVALID"

	// 404 / 409
	CodeNotFound                 = "NOT_FOUND"
	CodeUserNotFound             = "USER_NOT_FOUND"
	CodeStudentNotFound          = "STUDENT_NOT_FOUND"
	CodeEmergencyContactNotFound = "EMERGENCY_CONTACT_NOT_FOUND"
	CodeConflict                 = "CONFLICT"
	CodeResourceAlreadyExists    = "RESOURCE_ALREADY_EXISTS"

	// 422
	CodeUnprocessable = "UNPROCESSABLE_ENTITY"

	// 429 / 5xx
	CodeRateLimitExceeded   = "RATE_LIMIT_EXCEEDED"
	CodeInternalServerError = "INTERNAL_SERVER_ERROR"
	CodeDatabaseError       = "DATABASE_ERROR"
	CodeQueryTimeout        = "QUERY_TIMEOUT"
	CodeServiceUnavailable  = "SERVICE_UNAVAILABLE"
	CodeTooManyResults      = "TOO_MANY_RESULTS"
)

// ------------------------------------------------------------------
// Kode error spesifik Sanctuary (privacy & clinical domain).
// Wajib didokumentasikan juga di ./api-standart/api-error-codes.md
// ------------------------------------------------------------------
const (
	// 403 - konten privat (jurnal & chat AI) hanya milik mahasiswa pemilik akun.
	CodePrivateContentForbidden = "PRIVATE_CONTENT_FORBIDDEN"
	// 403 - dosen bukan pembimbing mahasiswa tersebut.
	CodeAdvisorAssignmentRequired = "ADVISOR_ASSIGNMENT_REQUIRED"
	// 403 - mahasiswa mengunci berbagi data (share_level = CLOSED).
	CodeSharingDisabledByStudent = "SHARING_DISABLED_BY_STUDENT"
	// 422 - kelompok agregat di bawah ambang k-anonymity.
	CodeInsufficientGroupSize = "INSUFFICIENT_GROUP_SIZE"
	// 422 - data harian tidak cukup untuk kalkulasi indikator.
	CodeInsufficientData = "INSUFFICIENT_DATA"
	// 409 - check-in harian untuk tanggal tersebut sudah ada.
	CodeMetricAlreadyExists = "METRIC_ALREADY_EXISTS"
	// 422 - backdate check-in tidak boleh ke masa depan.
	CodeFutureDateNotAllowed = "FUTURE_DATE_NOT_ALLOWED"
)

var ErrorCodeMap = map[string]ErrorInfo{
	CodeValidationError:    {http.StatusBadRequest, "Data yang dikirim tidak valid"},
	CodeInvalidRequestBody: {http.StatusBadRequest, "Format request body tidak valid"},
	CodeInvalidQueryParam:  {http.StatusBadRequest, "Parameter query tidak valid"},
	CodeInvalidPathParam:   {http.StatusBadRequest, "Parameter path tidak valid"},
	CodeInvalidDate:        {http.StatusBadRequest, "Format tanggal tidak valid"},
	CodeInvalidEnum:        {http.StatusBadRequest, "Nilai tidak termasuk pilihan yang diizinkan"},

	CodeUnauthorized:        {http.StatusUnauthorized, "Sesi tidak valid, silakan masuk kembali"},
	CodeTokenExpired:        {http.StatusUnauthorized, "Sesi telah berakhir"},
	CodeTokenInvalid:        {http.StatusUnauthorized, "Token tidak valid"},
	CodeTokenMissing:        {http.StatusUnauthorized, "Token tidak ditemukan"},
	CodeInvalidCredentials:  {http.StatusUnauthorized, "Email atau kata sandi salah"},
	CodeAccountDisabled:     {http.StatusUnauthorized, "Akun dinonaktifkan"},
	CodeRefreshTokenInvalid: {http.StatusUnauthorized, "Refresh token tidak valid"},
	CodeRefreshTokenExpired: {http.StatusUnauthorized, "Refresh token telah kedaluwarsa"},

	CodeForbidden:                 {http.StatusForbidden, "Anda tidak memiliki akses ke sumber daya ini"},
	CodePermissionDenied:          {http.StatusForbidden, "Izin tidak mencukupi"},
	CodeRoleInsufficient:          {http.StatusForbidden, "Peran Anda tidak memiliki akses ke fitur ini"},
	CodeResourceOwnershipRequired: {http.StatusForbidden, "Hanya pemilik data yang dapat mengakses"},
	CodeCSRFTokenInvalid:          {http.StatusForbidden, "CSRF token tidak valid"},

	CodeNotFound:                 {http.StatusNotFound, "Data tidak ditemukan"},
	CodeUserNotFound:             {http.StatusNotFound, "Pengguna tidak ditemukan"},
	CodeStudentNotFound:          {http.StatusNotFound, "Mahasiswa tidak ditemukan"},
	CodeEmergencyContactNotFound: {http.StatusNotFound, "Layanan bantuan tidak ditemukan"},
	CodeConflict:                 {http.StatusConflict, "Terjadi konflik dengan data saat ini"},
	CodeResourceAlreadyExists:    {http.StatusConflict, "Data sudah ada"},

	CodeUnprocessable: {http.StatusUnprocessableEntity, "Permintaan tidak dapat diproses"},

	CodeRateLimitExceeded:   {http.StatusTooManyRequests, "Terlalu banyak permintaan, coba lagi nanti"},
	CodeInternalServerError: {http.StatusInternalServerError, "Terjadi kesalahan pada server"},
	CodeDatabaseError:       {http.StatusInternalServerError, "Terjadi kesalahan basis data"},
	CodeQueryTimeout:        {http.StatusInternalServerError, "Permintaan basis data melebihi batas waktu"},
	CodeServiceUnavailable:  {http.StatusServiceUnavailable, "Layanan sedang tidak tersedia"},
	CodeTooManyResults:      {http.StatusBadRequest, "Jumlah data yang diminta melebihi batas"},

	CodePrivateContentForbidden:   {http.StatusForbidden, "Konten ini bersifat privat dan hanya dapat diakses oleh pemiliknya"},
	CodeAdvisorAssignmentRequired: {http.StatusForbidden, "Mahasiswa ini bukan bimbingan Anda"},
	CodeSharingDisabledByStudent:  {http.StatusForbidden, "Mahasiswa menonaktifkan berbagi data"},
	CodeInsufficientGroupSize:     {http.StatusUnprocessableEntity, "Data belum cukup untuk ditampilkan secara agregat"},
	CodeInsufficientData:          {http.StatusUnprocessableEntity, "Data belum cukup"},
	CodeMetricAlreadyExists:       {http.StatusConflict, "Check-in untuk tanggal ini sudah ada"},
	CodeFutureDateNotAllowed:      {http.StatusUnprocessableEntity, "Tanggal tidak boleh melebihi hari ini"},
}

// FieldError mengikuti format field_errors pada standar error.
type FieldError struct {
	Field      string         `json:"field"`
	Code       string         `json:"code"`
	Message    string         `json:"message"`
	Constraint map[string]any `json:"constraint,omitempty"`
}

// AppError adalah error domain yang membawa kode standar.
type AppError struct {
	Code        string
	Message     string
	Details     map[string]any
	FieldErrors []FieldError
	cause       error
}

func (e *AppError) Error() string {
	if e.cause != nil {
		return fmt.Sprintf("%s: %s (%v)", e.Code, e.Message, e.cause)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error { return e.cause }

func (e *AppError) HTTPStatus() int { return StatusOf(e.Code) }

// WithDetails menambahkan konteks non-sensitif untuk debugging klien.
func (e *AppError) WithDetails(details map[string]any) *AppError {
	e.Details = details
	return e
}

func (e *AppError) WithCause(err error) *AppError {
	e.cause = err
	return e
}

// NewError membuat AppError memakai pesan default dari ErrorCodeMap.
func NewError(code string) *AppError {
	info, ok := ErrorCodeMap[code]
	if !ok {
		info = ErrorCodeMap[CodeInternalServerError]
		code = CodeInternalServerError
	}
	return &AppError{Code: code, Message: info.Message}
}

// NewErrorWithMessage meng-override pesan default (harus user-friendly, tanpa data sensitif).
func NewErrorWithMessage(code, message string) *AppError {
	e := NewError(code)
	if message != "" {
		e.Message = message
	}
	return e
}

// NewFieldErrors membuat error validasi multi-field.
func NewFieldErrors(fields []FieldError) *AppError {
	e := NewError(CodeValidationError)
	e.FieldErrors = fields
	return e
}

// WrapInternal membungkus error teknis agar detail internal tidak bocor ke klien.
func WrapInternal(err error) *AppError {
	return NewError(CodeInternalServerError).WithCause(err)
}

func StatusOf(code string) int {
	if info, ok := ErrorCodeMap[code]; ok {
		return info.HTTPStatus
	}
	return http.StatusInternalServerError
}

// AsAppError menormalkan error apa pun menjadi *AppError.
func AsAppError(err error) *AppError {
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr
	}
	return WrapInternal(err)
}
