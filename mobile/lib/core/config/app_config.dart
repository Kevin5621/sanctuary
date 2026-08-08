import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Lingkungan build. Menentukan default API base URL dan apakah aplikasi
/// boleh diam-diam jatuh ke URL pengembangan.
enum AppEnvironment {
  development('development'),
  staging('staging'),
  production('production');

  const AppEnvironment(this.code);

  final String code;

  static AppEnvironment fromCode(String code) => AppEnvironment.values.firstWhere(
        (env) => env.code == code,
        orElse: () => AppEnvironment.development,
      );
}

/// Konfigurasi runtime aplikasi — **compile-time**, bukan file `.env` yang
/// dibaca saat runtime.
///
/// Ini bukan luput/kelupaan, melainkan cara standar Flutter menangani hal ini:
/// nilai `.env` yang dibundel sebagai asset tetap bisa diekstrak dari
/// APK/IPA hasil build (`.env` bukan tersembunyi, hanya sebuah file di dalam
/// arsip), dan tetap butuh parsing runtime. `--dart-define` (atau
/// `--dart-define-from-file`) di-compile menjadi konstanta Dart saat build —
/// ini pendekatan resmi Flutter untuk konfigurasi per-lingkungan.
/// Lihat: https://docs.flutter.dev/deployment/flavors
///
/// ## Cara pakai
///
/// Development (default, tanpa flag apa pun):
/// ```
/// flutter run
/// ```
///
/// Staging / Production — pakai file `--dart-define-from-file` (bukan
/// mengetik banyak `--dart-define` di command line, agar tidak tercatat di
/// shell history dan mudah dipakai ulang di CI/CD):
/// ```
/// flutter run     --dart-define-from-file=config/env.staging.json
/// flutter build apk --release --dart-define-from-file=config/env.prod.json
/// ```
///
/// File `config/env.*.json` di repo ini HANYA berisi API_BASE_URL (bukan
/// rahasia — ini alamat publik API). Bila suatu saat perlu menambah nilai
/// rahasia (API key pihak ketiga, dsb.), pisahkan ke file baru yang
/// di-gitignore, jangan disatukan ke sini.
///
/// ## Kegagalan disengaja pada build non-development
///
/// Bila lingkungan adalah staging/production TAPI `API_BASE_URL` tidak
/// disertakan, aplikasi sengaja `throw` saat start — build yang salah target
/// (mis. APK produksi diam-diam menunjuk ke localhost developer) harus
/// gagal terlihat jelas, bukan jalan senyap dengan endpoint yang salah.
class AppConfig {
  const AppConfig._();

  static const _environmentCode =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  static final AppEnvironment environment =
      AppEnvironment.fromCode(_environmentCode);

  static bool get isDevelopment => environment == AppEnvironment.development;
  static bool get isProduction => environment == AppEnvironment.production;

  static const _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String? _cachedApiBaseUrl;

  /// Base URL REST API, termasuk host DAN port (mis. `http://10.0.2.2:8080/api/v1`).
  /// Port sengaja tidak dipisah jadi variabel sendiri — satu URL utuh adalah
  /// satu-satunya sumber kebenaran yang langsung dipakai Dio, tidak ada
  /// perakitan string tersebar di beberapa tempat.
  static String get apiBaseUrl => _cachedApiBaseUrl ??= _resolveApiBaseUrl();

  static String _resolveApiBaseUrl() {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;

    if (!isDevelopment) {
      throw StateError(
        'API_BASE_URL wajib diisi untuk lingkungan "${environment.code}". '
        'Jalankan build dengan --dart-define-from-file=config/env.${environment.code}.json '
        'atau --dart-define=API_BASE_URL=... Aplikasi tidak boleh diam-diam '
        'memakai URL pengembangan pada build staging/production.',
      );
    }

    // Default kenyamanan HANYA untuk development: emulator Android memetakan
    // host mesin developer ke 10.0.2.2, bukan localhost.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  static const appName = 'Sanctuary';

  /// Label ditampilkan pada environment banner (lihat EnvironmentBanner).
  static String get environmentLabel => switch (environment) {
        AppEnvironment.development => 'DEV',
        AppEnvironment.staging => 'STAGING',
        AppEnvironment.production => 'PRODUCTION',
      };

  /// Ukuran halaman default — sesuai batas backend (per_page maksimum 20).
  static const defaultPerPage = 20;
}
