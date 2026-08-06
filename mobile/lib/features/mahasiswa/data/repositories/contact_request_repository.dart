import '../../../../core/network/dio_client.dart';
import '../../domain/entities/contact_request.dart';

/// Repository tombol "minta dihubungi".
class ContactRequestRepository {
  const ContactRequestRepository(this._client);

  final DioClient _client;

  static const _basePath = '/students/me/contact-requests';

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
