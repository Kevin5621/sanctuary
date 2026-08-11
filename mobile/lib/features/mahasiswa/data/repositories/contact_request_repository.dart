import '../../../../core/network/dio_client.dart';
import '../../domain/entities/advisor.dart';
import '../../domain/entities/contact_request.dart';

/// Repository tombol "minta dihubungi" dan daftar pembimbing sendiri.
class ContactRequestRepository {
  const ContactRequestRepository(this._client);

  final DioClient _client;

  static const _basePath = '/students/me/contact-requests';
  static const _advisorsPath = '/students/me/advisors';

  /// Daftar pembimbing mahasiswa yang sedang login (bisa lebih dari satu).
  Future<MyAdvisors> fetchAdvisors() async {
    final result = await _client.get<MyAdvisors>(
      _advisorsPath,
      parser: (data) =>
          MyAdvisors.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }

  Future<ContactRequestState> fetchState() async {
    final result = await _client.get<ContactRequestState>(
      _basePath,
      parser: (data) => ContactRequestState.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  /// [note] adalah catatan untuk diri sendiri — server menyimpannya tetapi
  /// tidak pernah meneruskannya ke dosen.
  Future<ContactRequest> create({String note = ''}) async {
    final result = await _client.post<ContactRequest>(
      _basePath,
      body: {'note': note},
      parser: (data) => ContactRequest.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<void> cancel() async {
    await _client.delete<void>(_basePath, parser: (_) {});
  }
}
