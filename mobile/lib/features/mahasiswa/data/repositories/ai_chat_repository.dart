import '../../../../core/network/dio_client.dart';
import '../../domain/entities/ai_chat.dart';

/// Repository Terapis AI (Full Online — tidak ada cache lokal).
///
/// Seluruh endpoint berada di bawah /students/me/chats, yang di backend
/// dilindungi PrivateContentGuard. Klien tidak pernah mengirim user id:
/// identitas selalu diambil dari token.
class AiChatRepository {
  const AiChatRepository(this._client);

  final DioClient _client;

  static const _basePath = '/students/me/chats';

  /// Status gate D-5. Endpoint ini boleh dipanggil kapan saja — justru inilah
  /// yang memberi tahu klien apakah tab boleh dipakai.
  Future<AiConsentStatus> fetchConsentStatus() async {
    final result = await _client.get<AiConsentStatus>(
      '$_basePath/consent',
      parser: (data) => AiConsentStatus.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  /// Mengirim keputusan mahasiswa.
  ///
  /// [noticeVersion] adalah versi teks yang BENAR-BENAR ditampilkan di layar.
  /// Server menolak versi yang bukan versi berlaku, sehingga aplikasi lama
  /// tidak bisa merekam persetujuan atas pemberitahuan yang sudah usang.
  Future<AiConsentStatus> submitConsent({
    required bool accepted,
    required String noticeVersion,
  }) async {
    final result = await _client.post<AiConsentStatus>(
      '$_basePath/consent',
      body: {'accepted': accepted, 'notice_version': noticeVersion},
      parser: (data) => AiConsentStatus.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  /// Riwayat percakapan. Sudah dipangkas server ke batas giliran yang berlaku.
  Future<AiChatHistory> fetchHistory() async {
    final result = await _client.get<AiChatHistory>(
      _basePath,
      parser: (data) => AiChatHistory.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<AiSendResult> sendMessage(String text) async {
    final result = await _client.post<AiSendResult>(
      _basePath,
      body: {'text': text},
      parser: (data) => AiSendResult.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }
}
