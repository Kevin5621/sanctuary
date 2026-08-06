import 'package:equatable/equatable.dart';

/// Satu baris pada daftar jurnal.
///
/// Sengaja tanpa `content`: daftar hanya membawa cuplikan, isi lengkap diambil
/// saat catatan dibuka. Ini mengikuti bentuk response backend, yang juga
/// memisahkan keduanya.
class JournalListItem extends Equatable {
  const JournalListItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.journalDate,
    required this.emotionLabel,
    required this.emotionLabelText,
    required this.isCrisisFlagged,
    required this.analyzedAt,
  });

  factory JournalListItem.fromJson(Map<String, dynamic> json) => JournalListItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        preview: json['preview'] as String? ?? '',
        journalDate: DateTime.parse(json['journal_date'] as String),
        emotionLabel: json['emotion_label'] as String? ?? '',
        emotionLabelText: json['emotion_label_text'] as String? ?? '',
        isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
        analyzedAt: json['analyzed_at'] == null
            ? null
            : DateTime.parse(json['analyzed_at'] as String),
      );

  final String id;
  final String title;
  final String preview;
  final DateTime journalDate;
  final String emotionLabel;
  final String emotionLabelText;
  final bool isCrisisFlagged;
  final DateTime? analyzedAt;

  bool get isAnalyzed => analyzedAt != null;

  @override
  List<Object?> get props => [id, journalDate, emotionLabel, isCrisisFlagged, analyzedAt];
}

/// Jurnal lengkap beserta isinya — hanya dapat diambil oleh pemiliknya.
class Journal extends Equatable {
  const Journal({
    required this.id,
    required this.title,
    required this.content,
    required this.journalDate,
    required this.emotionLabel,
    required this.isCrisisFlagged,
    required this.analyzedAt,
  });

  factory Journal.fromJson(Map<String, dynamic> json) => Journal(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        journalDate: DateTime.parse(json['journal_date'] as String),
        emotionLabel: json['emotion_label'] as String? ?? '',
        isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
        analyzedAt: json['analyzed_at'] == null
            ? null
            : DateTime.parse(json['analyzed_at'] as String),
      );

  final String id;
  final String title;
  final String content;
  final DateTime journalDate;
  final String emotionLabel;
  final bool isCrisisFlagged;
  final DateTime? analyzedAt;

  @override
  List<Object?> get props => [id, content, journalDate, emotionLabel];
}

/// Hasil analisis emosi satu catatan.
///
/// [crisisMessage] tidak kosong berarti sistem mendeteksi tanda krisis —
/// klien wajib memunculkan jalur bantuan, bukan sekadar menampilkan teksnya.
class JournalAnalysis extends Equatable {
  const JournalAnalysis({
    required this.journalId,
    required this.emotionLabel,
    required this.emotionLabelText,
    required this.emotionConfidence,
    required this.sentimentScore,
    required this.isCrisisFlagged,
    required this.copingSuggestions,
    required this.crisisMessage,
    required this.modelVersion,
  });

  factory JournalAnalysis.fromJson(Map<String, dynamic> json) => JournalAnalysis(
        journalId: json['journal_id'] as String? ?? '',
        emotionLabel: json['emotion_label'] as String? ?? '',
        emotionLabelText: json['emotion_label_text'] as String? ?? '',
        emotionConfidence: (json['emotion_confidence'] as num?)?.toDouble() ?? 0,
        sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0,
        isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
        copingSuggestions:
            (json['coping_suggestions'] as List<dynamic>? ?? const []).whereType<String>().toList(),
        crisisMessage: json['crisis_message'] as String? ?? '',
        modelVersion: json['model_version'] as String? ?? '',
      );

  final String journalId;
  final String emotionLabel;
  final String emotionLabelText;
  final double emotionConfidence;
  final double sentimentScore;
  final bool isCrisisFlagged;
  final List<String> copingSuggestions;
  final String crisisMessage;
  final String modelVersion;

  /// Keyakinan dalam persen bulat, untuk ditampilkan di badge.
  int get confidencePercent => (emotionConfidence * 100).round();

  @override
  List<Object?> get props => [journalId, emotionLabel, emotionConfidence, isCrisisFlagged];
}

/// Satu hasil analisis pada layar "Riwayat Analisis Emosi".
class EmotionHistoryItem extends Equatable {
  const EmotionHistoryItem({
    required this.journalId,
    required this.title,
    required this.preview,
    required this.journalDate,
    required this.analyzedAt,
    required this.emotionLabel,
    required this.emotionLabelText,
    required this.emotionConfidence,
    required this.sentimentScore,
    required this.isCrisisFlagged,
    required this.copingSuggestions,
  });

  factory EmotionHistoryItem.fromJson(Map<String, dynamic> json) => EmotionHistoryItem(
        journalId: json['journal_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        preview: json['preview'] as String? ?? '',
        journalDate: DateTime.parse(json['journal_date'] as String),
        analyzedAt: DateTime.parse(json['analyzed_at'] as String),
        emotionLabel: json['emotion_label'] as String? ?? '',
        emotionLabelText: json['emotion_label_text'] as String? ?? '',
        emotionConfidence: (json['emotion_confidence'] as num?)?.toDouble() ?? 0,
        sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0,
        isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
        copingSuggestions:
            (json['coping_suggestions'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      );

  final String journalId;
  final String title;
  final String preview;
  final DateTime journalDate;
  final DateTime analyzedAt;
  final String emotionLabel;
  final String emotionLabelText;
  final double emotionConfidence;
  final double sentimentScore;
  final bool isCrisisFlagged;
  final List<String> copingSuggestions;

  int get confidencePercent => (emotionConfidence * 100).round();

  @override
  List<Object?> get props => [journalId, analyzedAt, emotionLabel];
}

class EmotionTrendPoint extends Equatable {
  const EmotionTrendPoint({
    required this.date,
    required this.sentimentScore,
    required this.emotionLabel,
    required this.emotionLabelText,
  });

  factory EmotionTrendPoint.fromJson(Map<String, dynamic> json) => EmotionTrendPoint(
        date: DateTime.parse(json['date'] as String),
        sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0,
        emotionLabel: json['emotion_label'] as String? ?? '',
        emotionLabelText: json['emotion_label_text'] as String? ?? '',
      );

  final DateTime date;
  final double sentimentScore;
  final String emotionLabel;
  final String emotionLabelText;

  @override
  List<Object?> get props => [date, sentimentScore, emotionLabel];
}

/// Layar "Riwayat Analisis Emosi" secara utuh.
class EmotionHistory extends Equatable {
  const EmotionHistory({
    required this.items,
    required this.distribution,
    required this.trend,
    required this.totalAnalyzed,
    required this.crisisFlaggedCount,
    required this.dominantEmotion,
    required this.dominantEmotionText,
    required this.negativeRatio,
    required this.modelVersion,
    required this.isSufficient,
    required this.message,
  });

  factory EmotionHistory.fromJson(Map<String, dynamic> json) => EmotionHistory(
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EmotionHistoryItem.fromJson)
            .toList(),
        distribution: (json['distribution'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(_EmotionShareParser.parse)
            .toList(),
        trend: (json['trend'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EmotionTrendPoint.fromJson)
            .toList(),
        totalAnalyzed: json['total_analyzed'] as int? ?? 0,
        crisisFlaggedCount: json['crisis_flagged_count'] as int? ?? 0,
        dominantEmotion: json['dominant_emotion'] as String? ?? '',
        dominantEmotionText: json['dominant_emotion_text'] as String? ?? '',
        negativeRatio: (json['negative_ratio'] as num?)?.toDouble() ?? 0,
        modelVersion: json['model_version'] as String? ?? '',
        isSufficient: json['is_sufficient'] as bool? ?? false,
        message: json['message'] as String? ?? '',
      );

  const EmotionHistory.empty()
      : items = const [],
        distribution = const [],
        trend = const [],
        totalAnalyzed = 0,
        crisisFlaggedCount = 0,
        dominantEmotion = '',
        dominantEmotionText = '',
        negativeRatio = 0,
        modelVersion = '',
        isSufficient = false,
        message = '';

  final List<EmotionHistoryItem> items;
  final List<EmotionDistributionSlice> distribution;
  final List<EmotionTrendPoint> trend;
  final int totalAnalyzed;
  final int crisisFlaggedCount;
  final String dominantEmotion;
  final String dominantEmotionText;
  final double negativeRatio;
  final String modelVersion;
  final bool isSufficient;
  final String message;

  bool get isEmpty => totalAnalyzed == 0;
  int get negativePercent => (negativeRatio * 100).round();

  @override
  List<Object?> get props => [items, distribution, trend, totalAnalyzed, isSufficient];
}

/// Irisan sebaran emosi pada riwayat analisis.
class EmotionDistributionSlice extends Equatable {
  const EmotionDistributionSlice({
    required this.emotion,
    required this.label,
    required this.count,
    required this.percentage,
    required this.isNegative,
  });

  final String emotion;
  final String label;
  final int count;
  final double percentage;
  final bool isNegative;

  double get fraction => percentage / 100;

  @override
  List<Object?> get props => [emotion, count, percentage];
}

class _EmotionShareParser {
  static EmotionDistributionSlice parse(Map<String, dynamic> json) => EmotionDistributionSlice(
        emotion: json['emotion'] as String? ?? '',
        label: json['label'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
        isNegative: json['is_negative'] as bool? ?? false,
      );
}
