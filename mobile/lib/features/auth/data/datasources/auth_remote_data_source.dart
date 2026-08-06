import '../../../../core/network/dio_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/study_program.dart';
import '../models/user_model.dart';

/// Sumber data jarak jauh untuk domain auth.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final DioClient _client;

  Future<SessionModel> login({
    required String email,
    required String password,
  }) async {
    final result = await _client.post<SessionModel>(
      '/auth/login',
      body: {'email': email, 'password': password},
      parser: (data) => SessionModel.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  /// Pendaftaran mandiri mahasiswa.
  ///
  /// Peran tidak ikut dikirim: endpoint ini selalu membuat akun mahasiswa.
  /// Akun dosen & kaprodi hanya lahir dari halaman kelola akun Admin.
  Future<SessionModel> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String studentNumber,
    required int cohortYear,
    required String studyProgramId,
    String? phone,
  }) async {
    final result = await _client.post<SessionModel>(
      '/auth/register',
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'student_number': studentNumber,
        'cohort_year': cohortYear,
        'study_program_id': studyProgramId,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
      parser: (data) => SessionModel.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  /// Daftar program studi untuk dropdown formulir pendaftaran.
  /// Endpoint publik — dibutuhkan sebelum pengguna punya sesi.
  Future<List<StudyProgram>> studyPrograms() async {
    final result = await _client.get<List<StudyProgram>>(
      '/auth/study-programs',
      parser: (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudyProgram.fromJson)
          .toList(),
    );
    return result.data;
  }

  Future<AppUser> me() async {
    final result = await _client.get<AppUser>(
      '/auth/me',
      parser: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<void> logout({String? refreshToken}) async {
    await _client.post<void>(
      '/auth/logout',
      body: refreshToken != null && refreshToken.isNotEmpty
          ? {'refresh_token': refreshToken}
          : null,
      parser: (_) {},
    );
  }
}
