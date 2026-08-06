import '../../../../core/network/dio_client.dart';
import '../../domain/entities/journal.dart';

/// Hasil pembuatan jurnal: catatan tersimpan, plus analisis bila diminta.
class JournalCreationResult {
  const JournalCreationResult({required this.journal, this.analysis});

  final Journal journal;
  final JournalAnalysis? analysis;
}

/// Satu halaman daftar jurnal.
class JournalPage {
  const JournalPage({required this.items, required this.hasNextPage, required this.page});

  final List<JournalListItem> items;
  final bool hasNextPage;
  final int page;
}

/// Repository jurnal — KONTEN PRIVAT.
///
/// Seluruh endpoint berada di bawah /students/me/journals and dilindungi
/// PrivateContentGuard di server. Tidak ada method di sini yang menerima id
/// mahasiswa: identitas selalu diambil dari token.
class JournalRepository {
  const JournalRepository(this._client);

  final DioClient _client;

  static const _basePath = '/students/me/journals';

  Future<JournalPage> fetchPage({int page = 1}) async {
    final result = await _client.get<List<JournalListItem>>(
      _basePath,
      query: {'page': page},
      parser: (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(JournalListItem.fromJson)
          .toList(),
    );

    return JournalPage(
      items: result.data,
      hasNextPage: result.meta?.hasNextPage ?? false,
      page: result.meta?.page ?? page,
    );
  }

  Future<Journal> fetchDetail(String id) async {
    final result = await _client.get<Journal>(
      '$_basePath/$id',
      parser: (data) => Journal.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<JournalCreationResult> create({
    required String content,
    String title = '',
    String? journalDate,
    bool analyzeNow = true,
  }) async {
    final result = await _client.post<JournalCreationResult>(
      _basePath,
      body: {
        'title': title,
        'content': content,
        'analyze_now': analyzeNow,
        if (journalDate != null && journalDate.isNotEmpty) 'journal_date': journalDate,
      },
      parser: (data) {
        final envelope = data as Map<String, dynamic>;
        final analysis = envelope['analysis'];
        return JournalCreationResult(
          journal: Journal.fromJson(envelope['journal'] as Map<String, dynamic>),
          analysis: analysis == null
              ? null
              : JournalAnalysis.fromJson(analysis as Map<String, dynamic>),
        );
      },
    );
    return result.data;
  }

  /// Alias untuk create yang mengembalikan record type untuk kompabilitas
  Future<({Journal journal, JournalAnalysis? analysis})> createJournal({
    required String content,
    String title = '',
    String? journalDate,
    bool analyzeNow = true,
  }) async {
    final result = await create(
      content: content,
      title: title,
      journalDate: journalDate,
      analyzeNow: analyzeNow,
    );
    return (journal: result.journal, analysis: result.analysis);
  }

  Future<JournalAnalysis> analyze(String id) async {
    final result = await _client.post<JournalAnalysis>(
      '$_basePath/$id/analyze',
      parser: (data) => JournalAnalysis.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<void> delete(String id) async {
    await _client.delete<void>('$_basePath/$id', parser: (_) {});
  }

  /// Riwayat Analisis Emosi (menu di tab Profil).
  Future<EmotionHistory> fetchEmotionHistory() async {
    final result = await _client.get<EmotionHistory>(
      '$_basePath/emotion-history',
      parser: (data) => EmotionHistory.fromJson(data as Map<String, dynamic>),
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
