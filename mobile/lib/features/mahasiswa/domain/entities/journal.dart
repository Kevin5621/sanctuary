import 'package:equatable/equatable.dart';

/// Entitas jurnal & hasil analisis emosi — selaras dengan dto/journal_dto.go.

class Journal extends Equatable {
  const Journal({
    required this.id,
    required this.content,
    required this.journalDate,
    this.title = '',
    this.emotionLabel = '',
    this.isCrisisFlagged = false,
    this.analyzedAt,
  });

  factory Journal.fromJson(Map<String, dynamic> json) => Journal(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        journalDate: DateTime.parse(json['journal_date'] as String),
        emotionLabel: json['emotion_label'] as String? ?? '',
        isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
        analyzedAt: DateTime.tryParse(json['analyzed_at'] as String? ?? ''),
      );

  final String id;
  final String title;
  final String content;
  final DateTime journalDate;
  final String emotionLabel;
  final bool isCrisisFlagged;
  final DateTime? analyzedAt;

  bool get isAnalyzed => analyzedAt != null;

  @override
  List<Object?> get props =>
      [id, title, content, journalDate, emotionLabel, isCrisisFlagged, analyzedAt];
}

/// Hasil "Analisis Emosi" (M-JUR-02..05).
///
/// Seluruh isinya datang dari server. Klien TIDAK memiliki daftar kata kunci
/// krisis sendiri: dua leksikon di dua tempat pasti menyimpang, dan yang
/// menyimpang di sisi klien akan gagal menampilkan kartu bantuan pada kalimat
/// yang justru dianggap krisis oleh backend.
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
    this.analyzedAt = '',
  });

  factory JournalAnalysis.fromJson(Map<String, dynamic> json) => JournalAnalysis(
        journalId: json['journal_id'] as String? ?? '',
        emotionLabel: json['emotion_label'] as String? ?? '',
        emotionLabelText: json['emotion_label_text'] as String? ?? '',
        emotionConfidence: (json['emotion_confidence'] as num?)?.toDouble() ?? 0,
        sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0,
        isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
        copingSuggestions: (json['coping_suggestions'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        crisisMessage: json['crisis_message'] as String? ?? '',
        modelVersion: json['model_version'] as String? ?? '',
        analyzedAt: json['analyzed_at'] as String? ?? '',
      );

  final String journalId;
  final String emotionLabel;
  final String emotionLabelText;
  final double emotionConfidence;
  final double sentimentScore;
  final bool isCrisisFlagged;
  final List<String> copingSuggestions;
  final String crisisMessage;

  /// Versi model yang benar-benar menghasilkan label ini. Ditampilkan apa
  /// adanya supaya layar tidak mengklaim ketelitian yang tidak dimilikinya.
  final String modelVersion;

  final String analyzedAt;

  int get confidencePercent => (emotionConfidence * 100).round();

  @override
  List<Object?> get props => [
        journalId,
        emotionLabel,
        emotionLabelText,
        emotionConfidence,
        sentimentScore,
        isCrisisFlagged,
        copingSuggestions,
        crisisMessage,
        modelVersion,
        analyzedAt,
      ];
}

/// Satu irisan grafik sebaran emosi.
class EmotionShare extends Equatable {
  const EmotionShare({
    required this.emotion,
    required this.label,
    required this.count,
    required this.percentage,
    required this.isNegative,
  });

  factory EmotionShare.fromJson(Map<String, dynamic> json) => EmotionShare(
        emotion: json['emotion'] as String? ?? '',
        label: json['label'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
        isNegative: json['is_negative'] as bool? ?? false,
      );

  final String emotion;
  final String label;
  final int count;
  final double percentage;
  final bool isNegative;

  @override
  List<Object?> get props => [emotion, label, count, percentage, isNegative];
}

/// Sebaran Emosi (M-MOOD-04).
///
/// D-3: seluruh angka berasal dari analisis JURNAL, bukan check-in mood manual.
class EmotionDistribution extends Equatable {
  const EmotionDistribution({
    required this.periodDays,
    required this.distribution,
    required this.totalAnalyzed,
    required this.negativeRatio,
    required this.modelVersion,
    this.crisisFlaggedCount = 0,
    this.dominantEmotion = '',
    this.dominantEmotionText = '',
    this.isEmpty = true,
    this.message = '',
  });

  factory EmotionDistribution.fromJson(Map<String, dynamic> json) =>
      EmotionDistribution(
        periodDays: json['period_days'] as int? ?? 30,
        distribution: (json['distribution'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EmotionShare.fromJson)
            .toList(),
        totalAnalyzed: json['total_analyzed'] as int? ?? 0,
        crisisFlaggedCount: json['crisis_flagged_count'] as int? ?? 0,
        dominantEmotion: json['dominant_emotion'] as String? ?? '',
        dominantEmotionText: json['dominant_emotion_text'] as String? ?? '',
        negativeRatio: (json['negative_ratio'] as num?)?.toDouble() ?? 0,
        modelVersion: json['model_version'] as String? ?? '',
        isEmpty: json['is_empty'] as bool? ?? false,
        message: json['message'] as String? ?? '',
      );

  const EmotionDistribution.initial()
      : periodDays = 30,
        distribution = const [],
        totalAnalyzed = 0,
        crisisFlaggedCount = 0,
        dominantEmotion = '',
        dominantEmotionText = '',
        negativeRatio = 0,
        modelVersion = '',
        isEmpty = true,
        message = '';

  final int periodDays;
  final List<EmotionShare> distribution;
  final int totalAnalyzed;
  final int crisisFlaggedCount;
  final String dominantEmotion;
  final String dominantEmotionText;
  final double negativeRatio;
  final String modelVersion;

  /// Server yang memutuskan ini kosong, sehingga UI menampilkan empty state
  /// yang jujur alih-alih menggambar grafik nol.
  final bool isEmpty;
  final String message;

  @override
  List<Object?> get props => [
        periodDays,
        distribution,
        totalAnalyzed,
        crisisFlaggedCount,
        dominantEmotion,
        dominantEmotionText,
        negativeRatio,
        modelVersion,
        isEmpty,
        message,
      ];
}
