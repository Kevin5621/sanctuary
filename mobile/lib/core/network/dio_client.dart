import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Hasil pemanggilan API dalam bentuk terurai (data + meta pagination).
class ApiResult<T> {
  const ApiResult({required this.data, this.meta});

  final T data;
  final PaginationMeta? meta;
}

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        page: json['page'] as int? ?? 1,
        perPage: json['per_page'] as int? ?? 20,
        total: json['total'] as int? ?? 0,
        totalPages: json['total_pages'] as int? ?? 0,
      );

  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  bool get hasNextPage => page < totalPages;
}

/// Klien REST tunggal aplikasi.
///
/// Tanggung jawab:
///  - menyisipkan Bearer token & header klien native,
///  - membuka amplop response standar `{success, data, meta}`,
///  - menerjemahkan seluruh kegagalan menjadi [ApiException],
///  - melakukan refresh token otomatis satu kali saat menerima 401.
class DioClient {
  /// Endpoint yang tidak boleh dibawakan Bearer token: seluruhnya berada di
  /// luar middleware Auth backend, dan token sesi lama yang ikut terkirim
  /// hanya membuat kunci rate limit (`KeyByUser`) menunjuk ke user yang salah.
  /// Refresh memakai refresh_token pada body, bukan header Authorization.
  static const _publicPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/study-programs',
  };

  DioClient({
    required TokenStorage tokenStorage,
    required this.onSessionExpired,
    Dio? dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Menandai klien native: backend mengembalikan token pada body
        // dan melewati pemeriksaan CSRF (tidak ada ambient cookie).
        'X-Client-Type': 'mobile',
      },
      // Status divalidasi manual agar body error tetap dapat dibaca.
      validateStatus: (_) => true,
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_publicPaths.contains(options.path)) {
            final token = await _tokenStorage.readAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Dipanggil saat refresh token gagal — router akan mengarahkan ke login.
  final Future<void> Function() onSessionExpired;

  Completer<bool>? _refreshCompleter;

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parser,
  }) =>
      _send(path, method: 'GET', query: query, parser: parser);

  Future<ApiResult<T>> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parser,
  }) =>
      _send(path, method: 'POST', body: body, query: query, parser: parser);

  Future<ApiResult<T>> put<T>(
    String path, {
    Object? body,
    required T Function(dynamic data) parser,
  }) =>
      _send(path, method: 'PUT', body: body, parser: parser);

  Future<ApiResult<T>> delete<T>(
    String path, {
    required T Function(dynamic data) parser,
  }) =>
      _send(path, method: 'DELETE', parser: parser);

  Future<ApiResult<T>> _send<T>(
    String path, {
    required String method,
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parser,
    bool isRetry = false,
  }) async {
    late Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.badResponse && error.response != null) {
        response = error.response!;
      } else {
        throw const ApiException.network();
      }
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    final envelope = data is Map<String, dynamic> ? data : <String, dynamic>{};

    if (statusCode >= 200 && statusCode < 300) {
      return ApiResult<T>(
        data: parser(envelope['data']),
        meta: envelope['meta'] is Map<String, dynamic>
            ? PaginationMeta.fromJson(envelope['meta'] as Map<String, dynamic>)
            : null,
      );
    }

    final exception = ApiException.fromResponse(envelope, statusCode);

    // Satu kali percobaan refresh; permintaan refresh itu sendiri tidak diulang.
    if (exception.requiresReauth && !isRetry && path != '/auth/refresh') {
      final refreshed = await _refreshSession();
      if (refreshed) {
        return _send(
          path,
          method: method,
          body: body,
          query: query,
          parser: parser,
          isRetry: true,
        );
      }
    }

    throw exception;
  }

  /// Menjalankan refresh token sekali saja walau beberapa request gagal
  /// bersamaan (permintaan lain menunggu hasil yang sama).
  Future<bool> _refreshSession() async {
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _failSession(completer);
        return false;
      }

      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final statusCode = response.statusCode ?? 0;
      final envelope =
          response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null;
      final session = envelope?['data'] as Map<String, dynamic>?;

      if (statusCode < 200 || statusCode >= 300 || session == null) {
        await _failSession(completer);
        return false;
      }

      final newAccess = session['access_token'] as String?;
      final newRefresh = session['refresh_token'] as String?;
      final role = (session['user'] as Map<String, dynamic>?)?['role'] as String?;

      if (newAccess == null || newAccess.isEmpty) {
        await _failSession(completer);
        return false;
      }

      if (newRefresh != null && role != null) {
        await _tokenStorage.saveSession(
          accessToken: newAccess,
          refreshToken: newRefresh,
          role: role,
        );
      } else {
        await _tokenStorage.updateAccessToken(newAccess);
      }

      completer.complete(true);
      return true;
    } catch (_) {
      await _failSession(completer);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _failSession(Completer<bool> completer) async {
    await _tokenStorage.clear();
    await onSessionExpired();
    if (!completer.isCompleted) completer.complete(false);
  }
}
