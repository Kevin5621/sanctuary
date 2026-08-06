import '../../../../core/network/dio_client.dart';
import '../../domain/entities/journal.dart';

/// Repository jurnal & analisis emosi (Full Online).
///
/// Endpoint berada di bawah /students/me/journals yang dilindungi
/// PrivateContentGuard di backend — identitas selalu dari token.
class JournalRepository {
  const JournalRepository(this._client);

  final DioClient _client;

  static const _basePath = '/students/me/journals';

  /// Menyimpan jurnal, opsional langsung menganalisis (M-JUR-02).
  ///
  /// [journalDate] dikirim hanya bila mahasiswa memilih tanggal mundur.
  /// Batas 7 hari (D-8) ditegakkan SERVER; klien hanya membatasi date picker
  /// agar mahasiswa tidak memilih tanggal yang pasti ditolak.
  Future<({Journal journal, JournalAnalysis? analysis})> createJournal({
    required String content,
    String title = '',
    String? journalDate,
    bool analyzeNow = true,
  }) async {
    final result = await _client.post<({Journal journal, JournalAnalysis? analysis})>(
      _basePath,
      body: {
        'content': content,
        if (title.isNotEmpty) 'title': title,
        if (journalDate != null && journalDate.isNotEmpty) 'journal_date': journalDate,
        'analyze_now': analyzeNow,
      },
      parser: (data) {
        final map = data as Map<String, dynamic>;
        final analysis = map['analysis'];
        return (
          journal: Journal.fromJson(map['journal'] as Map<String, dynamic>),
          analysis: analysis is Map<String, dynamic>
              ? JournalAnalysis.fromJson(analysis)
              : null,
        );
      },
    );
    return result.data;
  }

  /// Memicu analisis pada jurnal yang sudah tersimpan (M-JUR-02).
  Future<JournalAnalysis> analyze(String journalId) async {
    final result = await _client.post<JournalAnalysis>(
      '$_basePath/$journalId/analyze',
      parser: (data) => JournalAnalysis.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  /// Sebaran emosi untuk tab Mood (M-MOOD-04).
  ///
  /// Respons endpoint ini sengaja hanya berisi angka — tidak ada isi jurnal.
  Future<EmotionDistribution> fetchEmotionDistribution({int rangeDays = 30}) async {
    final result = await _client.get<EmotionDistribution>(
      '$_basePath/emotion-distribution',
      query: {'range': '${rangeDays}d'},
      parser: (data) => EmotionDistribution.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }
}
