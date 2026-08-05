import 'package:equatable/equatable.dart';

/// Satu titik check-in harian (kuantitatif) — selaras dengan
/// dto.DailyMetricResponse di backend.
class DailyMetric extends Equatable {
  const DailyMetric({
    required this.date,
    required this.moodScore,
    required this.stressLevel,
    required this.sleepHours,
    this.emotionLabel = '',
    this.emotionLabelText = '',
    this.academicTrigger = '',
  });

  factory DailyMetric.fromJson(Map<String, dynamic> json) => DailyMetric(
        date: DateTime.parse(json['date'] as String),
        moodScore: json['mood_score'] as int? ?? 0,
        stressLevel: json['stress_level'] as int? ?? 0,
        sleepHours: (json['sleep_hours'] as num?)?.toDouble() ?? 0,
        emotionLabel: json['emotion_label'] as String? ?? '',
        emotionLabelText: json['emotion_label_text'] as String? ?? '',
        academicTrigger: json['academic_trigger'] as String? ?? '',
      );

  final DateTime date;
  final int moodScore;
  final int stressLevel;
  final double sleepHours;
  final String emotionLabel;
  final String emotionLabelText;
  final String academicTrigger;

  bool isSameDate(DateTime other) =>
      date.year == other.year && date.month == other.month && date.day == other.day;

  @override
  List<Object?> get props =>
      [date, moodScore, stressLevel, sleepHours, emotionLabel, emotionLabelText, academicTrigger];
}

/// Ringkasan Senin–Minggu — dipakai kartu "Ringkasan Hari Ini" dan
/// "Kalender Mood Mingguan" di Beranda.
class WeeklyMoodSummary extends Equatable {
  const WeeklyMoodSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.today,
    required this.days,
  });

  factory WeeklyMoodSummary.fromJson(Map<String, dynamic> json) => WeeklyMoodSummary(
        weekStart: DateTime.parse(json['week_start'] as String),
        weekEnd: DateTime.parse(json['week_end'] as String),
        today: json['today'] == null
            ? null
            : DailyMetric.fromJson(json['today'] as Map<String, dynamic>),
        days: (json['days'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DailyMetric.fromJson)
            .toList(),
      );

  const WeeklyMoodSummary.empty()
      : weekStart = null,
        weekEnd = null,
        today = null,
        days = const [];

  final DateTime? weekStart;
  final DateTime? weekEnd;
  final DailyMetric? today;
  final List<DailyMetric> days;

  /// Cari check-in pada tanggal tertentu (untuk mengisi sel kalender).
  DailyMetric? forDate(DateTime date) {
    for (final day in days) {
      if (day.isSameDate(date)) return day;
    }
    return null;
  }

  @override
  List<Object?> get props => [weekStart, weekEnd, today, days];
}
