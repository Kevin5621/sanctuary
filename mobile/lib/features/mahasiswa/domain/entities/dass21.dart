import 'package:equatable/equatable.dart';

/// Kuesioner DASS-21 yang dikirim server.
///
/// Soal, instruksi, dan disclaimer TIDAK disalin ke klien: memperbaiki
/// terjemahan atau mengganti katalog soal tidak boleh menunggu rilis aplikasi,
/// dan dua klien tidak boleh menampilkan instrumen yang berbeda.
class DassQuestionnaire extends Equatable {
  const DassQuestionnaire({
    required this.version,
    required this.instruction,
    required this.disclaimer,
    required this.questions,
    required this.options,
  });

  factory DassQuestionnaire.fromJson(Map<String, dynamic> json) => DassQuestionnaire(
        version: json['version'] as String? ?? '',
        instruction: json['instruction'] as String? ?? '',
        disclaimer: json['disclaimer'] as String? ?? '',
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DassQuestion.fromJson)
            .toList(),
        options: (json['options'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DassAnswerOption.fromJson)
            .toList(),
      );

  const DassQuestionnaire.empty()
      : version = '',
        instruction = '',
        disclaimer = '',
        questions = const [],
        options = const [];

  final String version;
  final String instruction;
  final String disclaimer;
  final List<DassQuestion> questions;
  final List<DassAnswerOption> options;

  bool get isLoaded => questions.isNotEmpty;

  @override
  List<Object?> get props => [version, questions, options];
}

class DassQuestion extends Equatable {
  const DassQuestion({
    required this.number,
    required this.text,
    required this.subscale,
    required this.subscaleLabel,
  });

  factory DassQuestion.fromJson(Map<String, dynamic> json) => DassQuestion(
        number: json['number'] as int? ?? 0,
        text: json['text'] as String? ?? '',
        subscale: json['subscale'] as String? ?? '',
        subscaleLabel: json['subscale_label'] as String? ?? '',
      );

  final int number;
  final String text;
  final String subscale;
  final String subscaleLabel;

  @override
  List<Object?> get props => [number, text, subscale];
}

class DassAnswerOption extends Equatable {
  const DassAnswerOption({required this.value, required this.label});

  factory DassAnswerOption.fromJson(Map<String, dynamic> json) => DassAnswerOption(
        value: json['value'] as int? ?? 0,
        label: json['label'] as String? ?? '',
      );

  final int value;
  final String label;

  @override
  List<Object?> get props => [value, label];
}

/// Hasil satu subskala. Kategori (severity) dihitung server — klien tidak
/// pernah menentukan sendiri apakah sebuah skor tergolong parah.
class DassSubscaleResult extends Equatable {
  const DassSubscaleResult({
    required this.subscale,
    required this.label,
    required this.score,
    required this.maxScore,
    required this.severity,
    required this.severityLabel,
    required this.isSevere,
  });

  factory DassSubscaleResult.fromJson(Map<String, dynamic> json) => DassSubscaleResult(
        subscale: json['subscale'] as String? ?? '',
        label: json['label'] as String? ?? '',
        score: json['score'] as int? ?? 0,
        maxScore: json['max_score'] as int? ?? 42,
        severity: json['severity'] as String? ?? '',
        severityLabel: json['severity_label'] as String? ?? '',
        isSevere: json['is_severe'] as bool? ?? false,
      );

  final String subscale;
  final String label;
  final int score;
  final int maxScore;
  final String severity;
  final String severityLabel;
  final bool isSevere;

  double get fraction => maxScore == 0 ? 0 : score / maxScore;

  @override
  List<Object?> get props => [subscale, score, severity];
}

class DassResult extends Equatable {
  const DassResult({
    required this.id,
    required this.takenAt,
    required this.takenDate,
    required this.depression,
    required this.anxiety,
    required this.stress,
    required this.totalScore,
    required this.hasSevere,
    required this.disclaimer,
    required this.copingSuggestions,
  });

  factory DassResult.fromJson(Map<String, dynamic> json) => DassResult(
        id: json['id'] as String? ?? '',
        takenAt: DateTime.parse(json['taken_at'] as String),
        takenDate: json['taken_date'] as String? ?? '',
        depression: DassSubscaleResult.fromJson(json['depression'] as Map<String, dynamic>),
        anxiety: DassSubscaleResult.fromJson(json['anxiety'] as Map<String, dynamic>),
        stress: DassSubscaleResult.fromJson(json['stress'] as Map<String, dynamic>),
        totalScore: json['total_score'] as int? ?? 0,
        hasSevere: json['has_severe'] as bool? ?? false,
        disclaimer: json['disclaimer'] as String? ?? '',
        copingSuggestions: (json['coping_suggestions'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
      );

  final String id;
  final DateTime takenAt;
  final String takenDate;
  final DassSubscaleResult depression;
  final DassSubscaleResult anxiety;
  final DassSubscaleResult stress;
  final int totalScore;
  final bool hasSevere;
  final String disclaimer;
  final List<String> copingSuggestions;

  List<DassSubscaleResult> get subscales => [depression, anxiety, stress];

  @override
  List<Object?> get props => [id, totalScore, hasSevere];
}

class DassTrendPoint extends Equatable {
  const DassTrendPoint({
    required this.takenDate,
    required this.depressionScore,
    required this.anxietyScore,
    required this.stressScore,
    required this.totalScore,
  });

  factory DassTrendPoint.fromJson(Map<String, dynamic> json) => DassTrendPoint(
        takenDate: json['taken_date'] as String? ?? '',
        depressionScore: json['depression_score'] as int? ?? 0,
        anxietyScore: json['anxiety_score'] as int? ?? 0,
        stressScore: json['stress_score'] as int? ?? 0,
        totalScore: json['total_score'] as int? ?? 0,
      );

  final String takenDate;
  final int depressionScore;
  final int anxietyScore;
  final int stressScore;
  final int totalScore;

  @override
  List<Object?> get props => [takenDate, totalScore];
}

class DassHistory extends Equatable {
  const DassHistory({
    required this.latest,
    required this.results,
    required this.trend,
    required this.totalDelta,
    required this.changeLabel,
    required this.count,
  });

  factory DassHistory.fromJson(Map<String, dynamic> json) => DassHistory(
        latest: json['latest'] == null
            ? null
            : DassResult.fromJson(json['latest'] as Map<String, dynamic>),
        results: (json['results'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DassResult.fromJson)
            .toList(),
        trend: (json['trend'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DassTrendPoint.fromJson)
            .toList(),
        totalDelta: json['total_delta'] as int?,
        changeLabel: json['change_label'] as String? ?? '',
        count: json['count'] as int? ?? 0,
      );

  const DassHistory.empty()
      : latest = null,
        results = const [],
        trend = const [],
        totalDelta = null,
        changeLabel = '',
        count = 0;

  final DassResult? latest;
  final List<DassResult> results;
  final List<DassTrendPoint> trend;

  /// Positif berarti skor naik (memburuk); null bila belum ada pembanding.
  final int? totalDelta;
  final String changeLabel;
  final int count;

  bool get isEmpty => count == 0;
  bool get isWorsening => (totalDelta ?? 0) > 0;

  @override
  List<Object?> get props => [latest, results, trend, totalDelta, count];
}
