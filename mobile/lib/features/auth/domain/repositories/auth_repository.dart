import '../entities/app_user.dart';

/// Kontrak domain — presentation hanya bergantung pada abstraksi ini,
/// bukan pada Dio maupun bentuk JSON backend.
abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password});

  /// Mengambil profil pengguna dari token yang tersimpan (restore sesi).
  Future<AppUser> currentUser();

  Future<void> logout();

  Future<bool> hasSession();
}
