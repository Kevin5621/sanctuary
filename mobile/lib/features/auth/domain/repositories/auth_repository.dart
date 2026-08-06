import '../entities/app_user.dart';
import '../entities/study_program.dart';

/// Kontrak domain — presentation hanya bergantung pada abstraksi ini,
/// bukan pada Dio maupun bentuk JSON backend.
abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password});

  /// Pendaftaran mandiri mahasiswa. Berhasil mendaftar berarti langsung punya
  /// sesi — pengguna tidak diminta mengetik ulang kredensial yang baru dibuat.
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String studentNumber,
    required int cohortYear,
    required String studyProgramId,
    String? phone,
  });

  /// Daftar program studi untuk dropdown pendaftaran (tanpa sesi).
  Future<List<StudyProgram>> studyPrograms();

  /// Mengambil profil pengguna dari token yang tersimpan (restore sesi).
  Future<AppUser> currentUser();

  Future<void> logout();

  Future<bool> hasSession();
}
