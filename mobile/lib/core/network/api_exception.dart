import 'package:equatable/equatable.dart';

/// Kode error backend yang perlu ditangani khusus di UI.
/// Selaras dengan internal/core/utils/errors.go.
class ApiErrorCode {
  const ApiErrorCode._();

  static const validationError = 'VALIDATION_ERROR';
  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const unauthorized = 'UNAUTHORIZED';
  static const tokenExpired = 'TOKEN_EXPIRED';
  static const accountDisabled = 'ACCOUNT_DISABLED';
  static const roleInsufficient = 'ROLE_INSUFFICIENT';
  static const privateContentForbidden = 'PRIVATE_CONTENT_FORBIDDEN';
  static const advisorAssignmentRequired = 'ADVISOR_ASSIGNMENT_REQUIRED';
  static const insufficientGroupSize = 'INSUFFICIENT_GROUP_SIZE';
  static const insufficientData = 'INSUFFICIENT_DATA';
  static const rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';

  // --- Terapis AI (D-5) ---
  /// Backend menolak request chat karena consent belum tercatat, ditolak, atau
  /// merujuk versi pemberitahuan lama. UI menanggapinya dengan menampilkan
  /// ulang layar consent — bukan dengan pesan error merah.
  static const aiConsentRequired = 'AI_CONSENT_REQUIRED';
  static const aiConsentVersionMismatch = 'AI_CONSENT_VERSION_MISMATCH';
  static const aiServiceUnavailable = 'AI_SERVICE_UNAVAILABLE';

  static const backdateLimitExceeded = 'BACKDATE_LIMIT_EXCEEDED';
  static const futureDateNotAllowed = 'FUTURE_DATE_NOT_ALLOWED';
  static const networkError = 'NETWORK_ERROR';
  static const unknown = 'UNKNOWN_ERROR';
}

class FieldError extends Equatable {
  const FieldError({required this.field, required this.code, required this.message});

  factory FieldError.fromJson(Map<String, dynamic> json) => FieldError(
        field: json['field'] as String? ?? '',
        code: json['code'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  final String field;
  final String code;
  final String message;

  @override
  List<Object?> get props => [field, code, message];
}

/// Representasi tunggal kegagalan API di sisi klien.
/// Seluruh layer atas (repository/cubit) hanya berurusan dengan tipe ini.
class ApiException extends Equatable implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldErrors = const [],
    this.details,
  });

  factory ApiException.fromResponse(
    Map<String, dynamic>? body,
    int? statusCode,
  ) {
    final error = body?['error'] as Map<String, dynamic>?;
    if (error == null) {
      return ApiException(
        code: ApiErrorCode.unknown,
        message: 'Terjadi kesalahan yang tidak diketahui.',
        statusCode: statusCode,
      );
    }

    final rawFieldErrors = error['field_errors'] as List<dynamic>? ?? const [];

    return ApiException(
      code: error['code'] as String? ?? ApiErrorCode.unknown,
      message: error['message'] as String? ?? 'Terjadi kesalahan.',
      statusCode: statusCode,
      fieldErrors: rawFieldErrors
          .whereType<Map<String, dynamic>>()
          .map(FieldError.fromJson)
          .toList(),
      details: error['details'] as Map<String, dynamic>?,
    );
  }

  const ApiException.network()
      : code = ApiErrorCode.networkError,
        message = 'Tidak dapat terhubung ke server. Periksa koneksi internetmu.',
        statusCode = null,
        fieldErrors = const [],
        details = null;

  final String code;
  final String message;
  final int? statusCode;
  final List<FieldError> fieldErrors;
  final Map<String, dynamic>? details;

  /// Error yang mengharuskan pengguna login ulang.
  bool get requiresReauth =>
      code == ApiErrorCode.unauthorized ||
      code == ApiErrorCode.tokenExpired ||
      statusCode == 401;

  String? fieldMessage(String field) {
    for (final error in fieldErrors) {
      if (error.field == field) return error.message;
    }
    return null;
  }

  @override
  List<Object?> get props => [code, message, statusCode, fieldErrors];

  @override
  String toString() => 'ApiException($code): $message';
}
