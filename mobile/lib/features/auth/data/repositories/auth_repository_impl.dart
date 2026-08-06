import '../../../../core/network/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/study_program.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

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
    return _persist(session);
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String studentNumber,
    required int cohortYear,
    required String studyProgramId,
    String? phone,
  }) async {
    final session = await _remote.register(
      fullName: fullName,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      studentNumber: studentNumber,
      cohortYear: cohortYear,
      studyProgramId: studyProgramId,
      phone: phone,
    );
    return _persist(session);
  }

  @override
  Future<List<StudyProgram>> studyPrograms() => _remote.studyPrograms();

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

  /// Login dan pendaftaran sama-sama berakhir dengan satu sesi baru, sehingga
  /// penyimpanan tokennya pun harus lewat satu jalur yang sama.
  Future<AppUser> _persist(SessionModel session) async {
    await _tokenStorage.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      role: session.user.role.code,
    );
    return session.user;
  }
}
