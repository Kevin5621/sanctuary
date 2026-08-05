import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan token pada secure storage OS
/// (Keychain di iOS, SharedPreferences terenkripsi di Android).
///
/// Catatan arsitektur: aplikasi bersifat FULL ONLINE — tidak ada database
/// lokal. Yang tersimpan di perangkat hanyalah token sesi, bukan data
/// jurnal/mood/chat mahasiswa.
///
/// Sejak flutter_secure_storage v10, enkripsi Android aktif secara default
/// (Jetpack Security sudah usang dan digantikan cipher internal paket),
/// sehingga tidak ada lagi flag yang perlu dinyalakan.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'sanctuary.access_token';
  static const _refreshTokenKey = 'sanctuary.refresh_token';
  static const _roleKey = 'sanctuary.role';

  // Cache di memori agar interceptor tidak menyentuh storage tiap request.
  String? _cachedAccessToken;

  Future<String?> readAccessToken() async {
    return _cachedAccessToken ??= await _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> readRole() => _storage.read(key: _roleKey);

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    _cachedAccessToken = accessToken;
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _roleKey, value: role),
    ]);
  }

  Future<void> updateAccessToken(String accessToken) async {
    _cachedAccessToken = accessToken;
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<void> clear() async {
    _cachedAccessToken = null;
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _roleKey),
    ]);
  }

  Future<bool> get hasSession async =>
      (await readAccessToken())?.isNotEmpty ?? false;
}
