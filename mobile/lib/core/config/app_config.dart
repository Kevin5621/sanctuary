import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Konfigurasi runtime aplikasi.
/// Nilai berasal dari --dart-define agar tidak ada URL yang ter-hardcode.
///
/// Contoh:
///   flutter run --dart-define=API_BASE_URL=https://api.sanctuary.ac.id/api/v1
class AppConfig {
  const AppConfig._();

  static const _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;

    // Default pengembangan lokal: emulator Android memetakan host ke 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  static const appName = 'Sanctuary';

  /// Ukuran halaman default — sesuai batas backend (per_page maksimum 20).
  static const defaultPerPage = 20;
}
