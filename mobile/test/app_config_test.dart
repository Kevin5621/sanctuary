import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/core/config/app_config.dart';

/// Catatan: jalur fail-fast staging/production (AppConfig.apiBaseUrl throw
/// saat API_BASE_URL tidak diisi) TIDAK bisa diuji dalam satu proses test
/// yang sama — nilai --dart-define bersifat tetap per-kompilasi. Jalur itu
/// diverifikasi manual dengan menjalankan:
///   flutter test --dart-define=ENVIRONMENT=staging   (tanpa API_BASE_URL)
/// dan mengonfirmasi StateError terlempar. Lihat README §7 untuk detail.
void main() {
  test('default (tanpa dart-define apa pun) adalah lingkungan development', () {
    expect(AppConfig.environment, AppEnvironment.development);
    expect(AppConfig.isDevelopment, isTrue);
    expect(AppConfig.isProduction, isFalse);
    expect(AppConfig.environmentLabel, 'DEV');
  });

  test('development tidak pernah throw walau API_BASE_URL tidak diisi', () {
    expect(() => AppConfig.apiBaseUrl, returnsNormally);
    expect(AppConfig.apiBaseUrl, isNotEmpty);
  });

  test('AppEnvironment.fromCode aman terhadap kode tak dikenal', () {
    expect(AppEnvironment.fromCode('typo'), AppEnvironment.development);
    expect(AppEnvironment.fromCode('production'), AppEnvironment.production);
    expect(AppEnvironment.fromCode('staging'), AppEnvironment.staging);
  });
}
