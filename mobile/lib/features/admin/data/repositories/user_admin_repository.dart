import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/study_program.dart';
import '../../domain/entities/managed_user.dart';

/// Hasil `GET /admin/user-options`: isi dua dropdown formulir dalam satu
/// panggilan, supaya formulir Admin tidak perlu dua request untuk terbuka.
class StaffFormOptions {
  const StaffFormOptions({required this.roles, required this.studyPrograms});

  const StaffFormOptions.empty()
      : roles = const [],
        studyPrograms = const [];

  factory StaffFormOptions.fromJson(Map<String, dynamic> json) =>
      StaffFormOptions(
        roles: (json['roles'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RoleOption.fromJson)
            .toList(),
        studyPrograms: (json['study_programs'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(StudyProgram.fromJson)
            .toList(),
      );

  final List<RoleOption> roles;
  final List<StudyProgram> studyPrograms;

  bool get isEmpty => roles.isEmpty || studyPrograms.isEmpty;
}

/// Repository kelola akun dosen & kaprodi (Full Online — tanpa cache lokal).
///
/// Seluruh endpoint di bawah `/admin` dikunci untuk peran ADMIN oleh backend.
/// Klien tidak menyaring apa pun sendiri: menyembunyikan tombol bukan kontrol
/// akses, dan halaman ini memang tidak pernah dipasang untuk peran lain.
class UserAdminRepository {
  const UserAdminRepository(this._client);

  final DioClient _client;

  static const _basePath = '/admin/users';

  Future<List<ManagedUser>> fetchAll({
    String? role,
    bool? isActive,
    String? search,
    int page = 1,
  }) async {
    final result = await _client.get<List<ManagedUser>>(
      _basePath,
      query: {
        'page': page,
        'sort_by': 'name',
        if (role != null && role.isNotEmpty) 'role': role,
        if (isActive != null) 'is_active': isActive,
        if (search != null && search.isNotEmpty) 'q': search,
      },
      parser: (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ManagedUser.fromJson)
          .toList(),
    );
    return result.data;
  }

  Future<StaffFormOptions> fetchFormOptions() async {
    final result = await _client.get<StaffFormOptions>(
      '/admin/user-options',
      parser: (data) =>
          StaffFormOptions.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }

  Future<ManagedUser> create(StaffAccountDraft draft) async {
    final result = await _client.post<ManagedUser>(
      _basePath,
      body: draft.toCreateBody(),
      parser: (data) =>
          ManagedUser.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }

  Future<ManagedUser> update(String id, StaffAccountDraft draft) async {
    final result = await _client.put<ManagedUser>(
      '$_basePath/$id',
      body: draft.toUpdateBody(),
      parser: (data) =>
          ManagedUser.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }
}
