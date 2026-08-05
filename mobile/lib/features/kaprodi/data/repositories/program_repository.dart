import '../../../../core/network/dio_client.dart';
import '../../domain/entities/program_dashboard.dart';

/// Repository Kaprodi (Full Online — tanpa cache lokal).
///
/// Seluruh endpoint di bawah `/programs/me`; cakupan prodi berasal dari klaim
/// JWT, bukan dari parameter klien. Tidak ada satu pun method yang mengembalikan
/// data per mahasiswa — jalur API-nya memang tidak tersedia untuk peran ini.
class ProgramRepository {
  const ProgramRepository(this._client);

  final DioClient _client;

  static const _basePath = '/programs/me';

  /// Dashboard prodi (K-DAS-01..07).
  Future<ProgramDashboard> fetchDashboard({int periodDays = 30}) async {
    final result = await _client.get<ProgramDashboard>(
      '$_basePath/dashboard',
      query: {'period_days': periodDays},
      parser: (data) =>
          ProgramDashboard.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }

  /// Daftar dosen + beban bimbingan (K-PEM-01).
  Future<List<AdvisorLoad>> fetchAdvisors() async {
    final result = await _client.get<List<AdvisorLoad>>(
      '$_basePath/advisors',
      parser: (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdvisorLoad.fromJson)
          .toList(),
    );
    return result.data;
  }

  /// Ringkasan per angkatan (K-LAP-01).
  Future<List<CohortReport>> fetchCohortReports({int periodDays = 90}) async {
    final result = await _client.get<List<CohortReport>>(
      '$_basePath/reports/cohorts',
      query: {'period_days': periodDays},
      parser: (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CohortReport.fromJson)
          .toList(),
    );
    return result.data;
  }

  /// Identitas prodi + batas akses (K-PRO-01).
  Future<ProgramProfile> fetchProfile() async {
    final result = await _client.get<ProgramProfile>(
      '$_basePath/profile',
      parser: (data) =>
          ProgramProfile.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }
}
