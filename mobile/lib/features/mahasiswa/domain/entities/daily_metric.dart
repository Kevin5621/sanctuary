import 'package:equatable/equatable.dart';

/// Satu titik check-in harian (kuantitatif) — selaras dengan
/// dto.DailyMetricResponse di backend.
///
/// Label teks (moodLabel, stressLabel, emotionLabelText, academicTriggerText)
/// datang dari server, bukan dipetakan ulang di klien: arti angka 3 pada skala
/// mood hanya boleh punya satu definisi, dan definisinya ada di backend.
class DailyMetric extends Equatable {
  const DailyMetric({
    required this.date,
    required this.moodScore,
    required this.stressLevel,
    required this.sleepHours,
    this.moodLabel = '',
    this.stressLabel = '',
    this.emotionLabel = '',
    this.emotionLabelText = '',
    this.academicTrigger = '',
    this.academicTriggerText = '',
  });

  factory DailyMetric.fromJson(Map<String, dynamic> json) => DailyMetric(
        date: DateTime.parse(json['date'] as String),
        moodScore: json['mood_score'] as int? ?? 0,
        moodLabel: json['mood_label'] as String? ?? '',
        stressLevel: json['stress_level'] as int? ?? 0,
        stressLabel: json['stress_label'] as String? ?? '',
        sleepHours: (json['sleep_hours'] as num?)?.toDouble() ?? 0,
        emotionLabel: json['emotion_label'] as String? ?? '',
        emotionLabelText: json['emotion_label_text'] as String? ?? '',
        academicTrigger: json['academic_trigger'] as String? ?? '',
        academicTriggerText: json['academic_trigger_text'] as String? ?? '',
      );

  final DateTime date;
  final int moodScore;
  final String moodLabel;
  final int stressLevel;
  final String stressLabel;
  final double sleepHours;
  final String emotionLabel;
  final String emotionLabelText;
  final String academicTrigger;
  final String academicTriggerText;

  bool isSameDate(DateTime other) =>
      date.year == other.year && date.month == other.month && date.day == other.day;

  @override
  List<Object?> get props => [
        date,
        moodScore,
        stressLevel,
        sleepHours,
        emotionLabel,
        academicTrigger,
      ];
}

/// Ringkasan Senin–Minggu — dipakai kartu "Ringkasan Hari Ini" dan
/// "Kalender Mood Mingguan" di Beranda.
class WeeklyMoodSummary extends Equatable {
  const WeeklyMoodSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.today,
    required this.days,
    this.checkinCount = 0,
    this.currentStreak = 0,
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
        checkinCount: json['checkin_count'] as int? ?? 0,
        currentStreak: json['current_streak'] as int? ?? 0,
      );

  const WeeklyMoodSummary.empty()
      : weekStart = null,
        weekEnd = null,
        today = null,
        days = const [],
        checkinCount = 0,
        currentStreak = 0;

  final DateTime? weekStart;
  final DateTime? weekEnd;
  final DailyMetric? today;
  final List<DailyMetric> days;
  final int checkinCount;
  final int currentStreak;

  bool get hasCheckedInToday => today != null;

  /// Pengguna yang benar-benar baru — dipakai memilih empty state alih-alih
  /// kalender kosong yang terlihat seperti data gagal dimuat.
  bool get isEmpty => days.isEmpty;

  /// Cari check-in pada tanggal tertentu (untuk mengisi sel kalender).
  DailyMetric? forDate(DateTime date) {
    for (final day in days) {
      if (day.isSameDate(date)) return day;
    }
    return null;
  }

  @override
  List<Object?> get props => [weekStart, weekEnd, today, days, checkinCount, currentStreak];
}

/// Kalender mood satu bulan penuh — tab Mood.
class MonthlyMood extends Equatable {
  const MonthlyMood({
    required this.month,
    required this.monthLabel,
    required this.firstDate,
    required this.daysInMonth,
    required this.days,
    required this.checkinCount,
    required this.avgMood,
    required this.hasNextMonth,
  });

  factory MonthlyMood.fromJson(Map<String, dynamic> json) => MonthlyMood(
        month: json['month'] as String? ?? '',
        monthLabel: json['month_label'] as String? ?? '',
        firstDate: DateTime.parse(json['first_date'] as String),
        daysInMonth: json['days_in_month'] as int? ?? 0,
        days: (json['days'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DailyMetric.fromJson)
            .toList(),
        checkinCount: json['checkin_count'] as int? ?? 0,
        avgMood: (json['avg_mood'] as num?)?.toDouble() ?? 0,
        hasNextMonth: json['has_next_month'] as bool? ?? false,
      );

  const MonthlyMood.empty()
      : month = '',
        monthLabel = '',
        firstDate = null,
        daysInMonth = 0,
        days = const [],
        checkinCount = 0,
        avgMood = 0,
        hasNextMonth = false;

  final String month;
  final String monthLabel;
  final DateTime? firstDate;
  final int daysInMonth;
  final List<DailyMetric> days;
  final int checkinCount;
  final double avgMood;
  final bool hasNextMonth;

  DailyMetric? forDay(int day) {
    for (final metric in days) {
      if (metric.date.day == day) return metric;
    }
    return null;
  }

  @override
  List<Object?> get props => [month, days, checkinCount, avgMood, hasNextMonth];
}

/// Satu titik pada grafik ritme mood.
class MoodTrendPoint extends Equatable {
  const MoodTrendPoint({
    required this.date,
    required this.moodScore,
    required this.stressLevel,
    required this.sleepHours,
  });

  factory MoodTrendPoint.fromJson(Map<String, dynamic> json) => MoodTrendPoint(
        date: DateTime.parse(json['date'] as String),
        moodScore: json['mood_score'] as int? ?? 0,
        stressLevel: json['stress_level'] as int? ?? 0,
        sleepHours: (json['sleep_hours'] as num?)?.toDouble() ?? 0,
      );

  final DateTime date;
  final int moodScore;
  final int stressLevel;
  final double sleepHours;

  @override
  List<Object?> get props => [date, moodScore, stressLevel, sleepHours];
}

/// Satu irisan sebaran emosi.
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

  /// Nilai 0..1 untuk progress bar.
  double get fraction => percentage / 100;

  @override
  List<Object?> get props => [emotion, count, percentage, isNegative];
}

class TriggerShare extends Equatable {
  const TriggerShare({required this.trigger, required this.label, required this.count});

  factory TriggerShare.fromJson(Map<String, dynamic> json) => TriggerShare(
        trigger: json['trigger'] as String? ?? '',
        label: json['label'] as String? ?? '',
        count: json['count'] as int? ?? 0,
      );

  final String trigger;
  final String label;
  final int count;

  @override
  List<Object?> get props => [trigger, count];
}

/// Statistik periode untuk tab Mood.
///
/// [isSufficient] false berarti server menilai datanya belum cukup untuk
/// membentuk pola; klien wajib menampilkan pesan, bukan grafik yang terlihat
/// meyakinkan padahal ditarik dari satu-dua titik.
class MoodStats extends Equatable {
  const MoodStats({
    required this.periodDays,
    required this.points,
    required this.emotionDistribution,
    required this.topTriggers,
    required this.checkinCount,
    required this.avgMood,
    required this.avgStress,
    required this.avgSleepHours,
    required this.currentStreak,
    required this.longestStreak,
    required this.isSufficient,
    required this.message,
  });

  factory MoodStats.fromJson(Map<String, dynamic> json) => MoodStats(
        periodDays: json['period_days'] as int? ?? 0,
        points: (json['points'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MoodTrendPoint.fromJson)
            .toList(),
        emotionDistribution: (json['emotion_distribution'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EmotionShare.fromJson)
            .toList(),
        topTriggers: (json['top_triggers'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TriggerShare.fromJson)
            .toList(),
        checkinCount: json['checkin_count'] as int? ?? 0,
        avgMood: (json['avg_mood'] as num?)?.toDouble() ?? 0,
        avgStress: (json['avg_stress'] as num?)?.toDouble() ?? 0,
        avgSleepHours: (json['avg_sleep_hours'] as num?)?.toDouble() ?? 0,
        currentStreak: json['current_streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        isSufficient: json['is_sufficient'] as bool? ?? false,
        message: json['message'] as String? ?? '',
      );

  const MoodStats.empty()
      : periodDays = 30,
        points = const [],
        emotionDistribution = const [],
        topTriggers = const [],
        checkinCount = 0,
        avgMood = 0,
        avgStress = 0,
        avgSleepHours = 0,
        currentStreak = 0,
        longestStreak = 0,
        isSufficient = false,
        message = '';

  final int periodDays;
  final List<MoodTrendPoint> points;
  final List<EmotionShare> emotionDistribution;
  final List<TriggerShare> topTriggers;
  final int checkinCount;
  final double avgMood;
  final double avgStress;
  final double avgSleepHours;
  final int currentStreak;
  final int longestStreak;
  final bool isSufficient;
  final String message;

  @override
  List<Object?> get props => [
        periodDays,
        points,
        emotionDistribution,
        checkinCount,
        isSufficient,
      ];
}

/// Pilihan check-in yang dikirim server (skala, emosi, pemicu, batas backdate).
class CheckinOptions extends Equatable {
  const CheckinOptions({
    required this.moodScale,
    required this.stressScale,
    required this.emotions,
    required this.academicTriggers,
    required this.maxBackdateDays,
  });

  factory CheckinOptions.fromJson(Map<String, dynamic> json) => CheckinOptions(
        moodScale: _scale(json['mood_scale']),
        stressScale: _scale(json['stress_scale']),
        emotions: _coded(json['emotions']),
        academicTriggers: _coded(json['academic_triggers']),
        maxBackdateDays: json['max_backdate_days'] as int? ?? 0,
      );

  const CheckinOptions.empty()
      : moodScale = const [],
        stressScale = const [],
        emotions = const [],
        academicTriggers = const [],
        maxBackdateDays = 0;

  static List<ScaleOption> _scale(dynamic raw) => (raw as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((json) => ScaleOption(
            value: json['value'] as int? ?? 0,
            label: json['label'] as String? ?? '',
          ))
      .toList();

  static List<CodedOption> _coded(dynamic raw) => (raw as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((json) => CodedOption(
            value: json['value'] as String? ?? '',
            label: json['label'] as String? ?? '',
          ))
      .toList();

  final List<ScaleOption> moodScale;
  final List<ScaleOption> stressScale;
  final List<CodedOption> emotions;
  final List<CodedOption> academicTriggers;
  final int maxBackdateDays;

  bool get isLoaded => moodScale.isNotEmpty;

  /// Tanggal paling awal yang boleh dipilih pada form check-in.
  DateTime earliestDate(DateTime today) => today.subtract(Duration(days: maxBackdateDays));

  String moodLabel(int value) => _labelFor(moodScale, value);
  String stressLabel(int value) => _labelFor(stressScale, value);

  static String _labelFor(List<ScaleOption> options, int value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return '';
  }

  @override
  List<Object?> get props => [moodScale, stressScale, emotions, academicTriggers, maxBackdateDays];
}

class ScaleOption extends Equatable {
  const ScaleOption({required this.value, required this.label});

  final int value;
  final String label;

  @override
  List<Object?> get props => [value, label];
}

class CodedOption extends Equatable {
  const CodedOption({required this.value, required this.label});

  final String value;
  final String label;

  @override
  List<Object?> get props => [value, label];
}
