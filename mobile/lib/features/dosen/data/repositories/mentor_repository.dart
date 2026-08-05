import '../../../../core/network/dio_client.dart';
import '../../domain/entities/advisee.dart';
import '../../domain/entities/group_condition.dart';

/// Repository Dosen Pembimbing (Full Online — tanpa cache lokal).
///
/// Seluruh endpoint berada di bawah `/mentors/me`, sehingga backend selalu
/// memakai identitas dosen dari token. Klien tidak pernah mengirim advisor id,
/// dan tidak ada satu pun method di sini yang mengambil jurnal atau chat
/// mahasiswa — jalur API-nya memang tidak ada (I-1).
class MentorRepository {
  const MentorRepository(this._client);

  final DioClient _client;

  static const _basePath = '/mentors/me';

  /// Daftar bimbingan (L-BIM-01).
  ///
  /// Urutan datang dari server: minta-dihubungi → prioritas EWS → nama.
  /// Klien sengaja TIDAK mengurut ulang; server adalah satu-satunya yang tahu
  /// level EWS mahasiswa yang tidak membagikannya ke daftar ini.
  Future<({List<Advisee> items, PaginationMeta? meta})> fetchAdvisees({
    int page = 1,
  }) async {
    final result = await _client.get<List<Advisee>>(
      '$_basePath/students',
      query: {'page': page},
      parser: (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Advisee.fromJson)
          .toList(),
    );
    return (items: result.data, meta: result.meta);
  }

  /// Detail indikator satu mahasiswa (L-BIM-04).
  /// Isinya menyesuaikan `share_level` mahasiswa — penyaringan dilakukan server.
  Future<StudentIndicator> fetchStudentIndicator(String studentId) async {
    final result = await _client.get<StudentIndicator>(
      '$_basePath/students/$studentId',
      parser: (data) =>
          StudentIndicator.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }

  /// Daftar "minta dihubungi" (L-BIM-03).
  ///
  /// Response berisi nama + waktu saja. Alasan yang ditulis mahasiswa
  /// (`note`) tidak dikirim backend dan tidak diurai di sini (D-6).
  Future<List<ContactRequest>> fetchContactRequests() async {
    final result = await _client.get<List<ContactRequest>>(
      '$_basePath/contact-requests',
      parser: (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ContactRequest.fromJson)
          .toList(),
    );
    return result.data;
  }

  /// Agregat kelompok bimbingan (L-KON-01..04).
  /// [periodDays] hanya menerima 30 / 90 / 120 — divalidasi ulang server.
  Future<GroupCondition> fetchGroupCondition({int periodDays = 30}) async {
    final result = await _client.get<GroupCondition>(
      '$_basePath/condition',
      query: {'period_days': periodDays},
      parser: (data) =>
          GroupCondition.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }

  /// Profil dosen: jumlah bimbingan + batas akses (L-PRO-02..03).
  Future<MentorProfile> fetchProfile() async {
    final result = await _client.get<MentorProfile>(
      '$_basePath/profile',
      parser: (data) =>
          MentorProfile.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }
}
