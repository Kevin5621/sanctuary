import '../../../../core/network/dio_client.dart';
import '../../domain/entities/dass21.dart';

/// Repository skrining DASS-21.
///
/// Klien hanya mengirim jawaban mentah (0..3). Skor dan kategori keparahan
/// dihitung server — versi aplikasi lama tidak boleh dapat menyimpan kategori
/// dengan ambang yang sudah berubah.
class DassRepository {
  const DassRepository(this._client);

  final DioClient _client;

  static const _basePath = '/students/me/dass21';

  Future<DassQuestionnaire> fetchQuestionnaire() async {
    final result = await _client.get<DassQuestionnaire>(
      '$_basePath/questions',
      parser: (data) => DassQuestionnaire.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<DassHistory> fetchHistory() async {
    final result = await _client.get<DassHistory>(
      _basePath,
      parser: (data) => DassHistory.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  /// [answers] harus lengkap 21 nilai; server menolak pengisian sebagian
  /// karena skor DASS-21 hanya bermakna bila seluruh item terjawab.
  Future<DassResult> submit(List<int> answers) async {
    final result = await _client.post<DassResult>(
      _basePath,
      body: {'answers': answers},
      parser: (data) => DassResult.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }
}
