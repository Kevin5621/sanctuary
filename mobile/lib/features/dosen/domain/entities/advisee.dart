import 'package:equatable/equatable.dart';

/// Entitas layar Dosen Pembimbing.
///
/// CATATAN PRIVASI (D-6) — dibaca sebelum menambah field:
/// tidak satu pun entitas di file ini boleh memuat teks tulisan mahasiswa.
/// Khususnya `student_contact_requests.note`: backend memang tidak
/// mengirimkannya, dan menyediakan tempat untuk menampungnya di sini akan
/// mengundang seseorang "melengkapinya" saat API berubah.
/// Yang boleh masuk hanya SIAPA, KAPAN, dan hasil hitungan.

/// Tingkat berbagi data yang dipilih mahasiswa.
enum ShareLevel {
  closed('CLOSED', 'Tertutup'),
  summary('SUMMARY', 'Ringkasan'),
  summaryTrend('SUMMARY_TREND', 'Ringkasan + Tren');

  const ShareLevel(this.code, this.label);

  final String code;
  final String label;

  static ShareLevel fromCode(String? code) => switch (code) {
        'SUMMARY' => ShareLevel.summary,
        'SUMMARY_TREND' => ShareLevel.summaryTrend,
        // Default paling tertutup: bila nilainya tidak dikenali, aplikasi
        // memilih menampilkan lebih sedikit, bukan lebih banyak.
        _ => ShareLevel.closed,
      };

  bool get isClosed => this == ShareLevel.closed;
  bool get allowsTrend => this == ShareLevel.summaryTrend;
}

/// Satu indikator EWS beserta ambang dan nilainya.
class EwsIndicator extends Equatable {
  const EwsIndicator({
    required this.code,
    required this.label,
    required this.triggered,
    required this.value,
    required this.threshold,
    required this.detail,
  });

  factory EwsIndicator.fromJson(Map<String, dynamic> json) => EwsIndicator(
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
        triggered: json['triggered'] as bool? ?? false,
        value: (json['value'] as num?)?.toDouble() ?? 0,
        threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
        detail: json['detail'] as String? ?? '',
      );

  final String code;
  final String label;
  final bool triggered;
  final double value;
  final double threshold;
  final String detail;

  @override
  List<Object?> get props => [code, label, triggered, value, threshold, detail];
}

/// Ringkasan Early Warning System.
///
/// Hanya terisi bila mahasiswa mengizinkan peringatan dini. Bila `null` di
/// entitas induk, artinya BUKAN "Normal" — melainkan tidak dibagikan.
class EwsSummary extends Equatable {
  const EwsSummary({
    required this.level,
    required this.levelLabel,
    required this.score,
    required this.isSufficient,
    required this.dataPoints,
    required this.windowDays,
    required this.indicators,
  });

  factory EwsSummary.fromJson(Map<String, dynamic> json) => EwsSummary(
        level: json['level'] as String? ?? 'INSUFFICIENT_DATA',
        levelLabel: json['level_label'] as String? ?? 'Data belum cukup',
        score: json['score'] as int? ?? 0,
        isSufficient: json['is_sufficient'] as bool? ?? false,
        dataPoints: json['data_points'] as int? ?? 0,
        windowDays: json['window_days'] as int? ?? 0,
        indicators: (json['indicators'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EwsIndicator.fromJson)
            .toList(),
      );

  final String level;
  final String levelLabel;
  final int score;
  final bool isSufficient;
  final int dataPoints;
  final int windowDays;
  final List<EwsIndicator> indicators;

  /// Prioritas tampilan, sejajar dengan `constants.EWSLevel.Priority()` di
  /// backend. Dipakai hanya untuk penegasan visual — pengurutan daftar tetap
  /// dilakukan server (L-BIM-01).
  int get priority => switch (level) {
        'INTERVENTION' => 4,
        'RISK' => 3,
        'WATCH' => 2,
        'NORMAL' => 1,
        _ => 0,
      };

  List<EwsIndicator> get triggeredIndicators =>
      indicators.where((i) => i.triggered).toList();

  @override
  List<Object?> get props =>
      [level, levelLabel, score, isSufficient, dataPoints, windowDays, indicators];
}

/// Satu baris pada tab Bimbingan.
class Advisee extends Equatable {
  const Advisee({
    required this.studentId,
    required this.fullName,
    required this.shareLevel,
    required this.shareLevelLabel,
    this.studentNumber,
    this.cohortYear,
    this.privacyNotice,
    this.hasOpenContactRequest = false,
    this.contactRequestedAt,
    this.lastCheckinDate,
    this.ews,
  });

  factory Advisee.fromJson(Map<String, dynamic> json) => Advisee(
        studentId: json['student_id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        shareLevel: ShareLevel.fromCode(json['share_level'] as String?),
        shareLevelLabel: json['share_level_label'] as String? ?? '',
        studentNumber: json['student_number'] as String?,
        cohortYear: json['cohort_year'] as int?,
        privacyNotice: json['privacy_notice'] as String?,
        hasOpenContactRequest: json['has_open_contact_request'] as bool? ?? false,
        contactRequestedAt: json['contact_requested_at'] as String?,
        lastCheckinDate: json['last_checkin_date'] as String?,
        ews: json['ews'] is Map<String, dynamic>
            ? EwsSummary.fromJson(json['ews'] as Map<String, dynamic>)
            : null,
      );

  final String studentId;
  final String fullName;
  final ShareLevel shareLevel;
  final String shareLevelLabel;
  final String? studentNumber;
  final int? cohortYear;
  final String? privacyNotice;
  final bool hasOpenContactRequest;
  final String? contactRequestedAt;
  final String? lastCheckinDate;
  final EwsSummary? ews;

  /// Level untuk badge. `null` dibiarkan `null` — pemanggil WAJIB membedakan
  /// "tidak dibagikan" dari "Normal" (L-BIM-05), sehingga getter ini sengaja
  /// tidak punya nilai default yang tampak aman.
  String? get ewsLevel => ews?.level;

  bool get hasEws => ews != null;

  @override
  List<Object?> get props => [
        studentId,
        fullName,
        shareLevel,
        shareLevelLabel,
        studentNumber,
        cohortYear,
        privacyNotice,
        hasOpenContactRequest,
        contactRequestedAt,
        lastCheckinDate,
        ews,
      ];
}

/// Satu baris daftar "minta dihubungi" (L-BIM-03).
///
/// Field alasan TIDAK ADA dan tidak boleh ditambahkan (D-6).
class ContactRequest extends Equatable {
  const ContactRequest({
    required this.requestId,
    required this.studentId,
    required this.fullName,
    required this.requestedAt,
    this.studentNumber,
  });

  factory ContactRequest.fromJson(Map<String, dynamic> json) => ContactRequest(
        requestId: json['request_id'] as String? ?? '',
        studentId: json['student_id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        requestedAt: json['requested_at'] as String? ?? '',
        studentNumber: json['student_number'] as String?,
      );

  final String requestId;
  final String studentId;
  final String fullName;
  final String requestedAt;
  final String? studentNumber;

  @override
  List<Object?> get props =>
      [requestId, studentId, fullName, requestedAt, studentNumber];
}

/// Indikator kondisi ringkas milik satu mahasiswa (tab detail).
class ConditionSummary extends Equatable {
  const ConditionSummary({
    required this.avgMood,
    required this.avgStress,
    required this.avgSleepHours,
    required this.checkinCount,
    required this.windowDays,
  });

  factory ConditionSummary.fromJson(Map<String, dynamic> json) =>
      ConditionSummary(
        avgMood: (json['avg_mood'] as num?)?.toDouble() ?? 0,
        avgStress: (json['avg_stress'] as num?)?.toDouble() ?? 0,
        avgSleepHours: (json['avg_sleep_hours'] as num?)?.toDouble() ?? 0,
        checkinCount: json['checkin_count'] as int? ?? 0,
        windowDays: json['window_days'] as int? ?? 30,
      );

  final double avgMood;
  final double avgStress;
  final double avgSleepHours;
  final int checkinCount;
  final int windowDays;

  @override
  List<Object?> get props =>
      [avgMood, avgStress, avgSleepHours, checkinCount, windowDays];
}

/// Satu titik grafik tren mingguan (hanya pada level Ringkasan + Tren).
class WeeklyTrendPoint extends Equatable {
  const WeeklyTrendPoint({
    required this.weekStart,
    required this.avgMood,
    required this.avgStress,
    required this.avgSleep,
    required this.entries,
  });

  factory WeeklyTrendPoint.fromJson(Map<String, dynamic> json) =>
      WeeklyTrendPoint(
        weekStart: json['week_start'] as String? ?? '',
        avgMood: (json['avg_mood'] as num?)?.toDouble() ?? 0,
        avgStress: (json['avg_stress'] as num?)?.toDouble() ?? 0,
        avgSleep: (json['avg_sleep'] as num?)?.toDouble() ?? 0,
        entries: json['entries'] as int? ?? 0,
      );

  final String weekStart;
  final double avgMood;
  final double avgStress;
  final double avgSleep;
  final int entries;

  @override
  List<Object?> get props => [weekStart, avgMood, avgStress, avgSleep, entries];
}

/// Halaman detail mahasiswa (L-BIM-04).
class StudentIndicator extends Equatable {
  const StudentIndicator({
    required this.studentId,
    required this.fullName,
    required this.shareLevel,
    required this.shareLevelLabel,
    this.studentNumber,
    this.privacyNotice,
    this.summary,
    this.trend = const [],
    this.ews,
    this.hasOpenContactRequest = false,
    this.contactRequestedAt,
    this.coAdvisors = const [],
  });

  factory StudentIndicator.fromJson(Map<String, dynamic> json) =>
      StudentIndicator(
        studentId: json['student_id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        shareLevel: ShareLevel.fromCode(json['share_level'] as String?),
        shareLevelLabel: json['share_level_label'] as String? ?? '',
        studentNumber: json['student_number'] as String?,
        privacyNotice: json['privacy_notice'] as String?,
        summary: json['summary'] is Map<String, dynamic>
            ? ConditionSummary.fromJson(json['summary'] as Map<String, dynamic>)
            : null,
        trend: (json['trend'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(WeeklyTrendPoint.fromJson)
            .toList(),
        ews: json['ews'] is Map<String, dynamic>
            ? EwsSummary.fromJson(json['ews'] as Map<String, dynamic>)
            : null,
        hasOpenContactRequest: json['has_open_contact_request'] as bool? ?? false,
        contactRequestedAt: json['contact_requested_at'] as String?,
        coAdvisors: (json['co_advisors'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
      );

  final String studentId;
  final String fullName;
  final ShareLevel shareLevel;
  final String shareLevelLabel;
  final String? studentNumber;
  final String? privacyNotice;
  final ConditionSummary? summary;
  final List<WeeklyTrendPoint> trend;
  final EwsSummary? ews;
  final bool hasOpenContactRequest;
  final String? contactRequestedAt;

  /// Nama pembimbing LAIN mahasiswa ini — data administratif, tanpa satu pun
  /// angka kondisi. Ditampilkan supaya pendampingan tidak bertubrukan.
  final List<String> coAdvisors;

  bool get hasTrend => trend.isNotEmpty;
  bool get isCoAdvised => coAdvisors.isNotEmpty;

  @override
  List<Object?> get props => [
        studentId,
        fullName,
        shareLevel,
        shareLevelLabel,
        studentNumber,
        privacyNotice,
        summary,
        trend,
        ews,
        hasOpenContactRequest,
        contactRequestedAt,
        coAdvisors,
      ];
}

/// Tab Profil dosen (L-PRO-02..03).
class MentorProfile extends Equatable {
  const MentorProfile({
    required this.adviseeCount,
    required this.openContactRequest,
    required this.accessLimits,
  });

  factory MentorProfile.fromJson(Map<String, dynamic> json) => MentorProfile(
        adviseeCount: json['advisee_count'] as int? ?? 0,
        openContactRequest: json['open_contact_request'] as int? ?? 0,
        accessLimits: (json['access_limits'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
      );

  const MentorProfile.empty()
      : adviseeCount = 0,
        openContactRequest = 0,
        accessLimits = const [];

  final int adviseeCount;
  final int openContactRequest;
  final List<String> accessLimits;

  @override
  List<Object?> get props => [adviseeCount, openContactRequest, accessLimits];
}
