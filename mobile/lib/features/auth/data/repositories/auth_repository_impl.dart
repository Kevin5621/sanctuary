import '../../../../core/network/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<AppUser> login({required String email, required String password}) async {
    final session = await _remote.login(email: email, password: password);

    await _tokenStorage.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      role: session.user.role.code,
    );
    return session.user;
  }

  @override
  Future<AppUser> currentUser() => _remote.me();

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      await _remote.logout(refreshToken: refreshToken);
    } finally {
      // Token lokal selalu dibersihkan, walau panggilan server gagal.
      await _tokenStorage.clear();
    }
  }

  @override
  Future<bool> hasSession() => _tokenStorage.hasSession;
}
