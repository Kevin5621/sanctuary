import 'package:equatable/equatable.dart';

/// Entitas layar Kaprodi.
///
/// Kaprodi TIDAK PERNAH melihat data individu. Seluruh entitas di file ini
/// hanya membawa angka agregat yang sudah lolos ambang k-anonymity di server —
/// tidak ada satu pun field bernama/berisi identitas mahasiswa.

/// Satu kartu metrik pada dashboard.
///
/// [value] bertipe nullable dan itu disengaja: `null` berarti server menolak
/// mengeluarkan angkanya (k < ambang). UI wajib merendernya sebagai
/// "Data belum cukup", bukan sebagai 0.
class MetricCard extends Equatable {
  const MetricCard({
    required this.key,
    required this.label,
    this.value,
    this.unit = '',
    this.hint = '',
  });

  factory MetricCard.fromJson(Map<String, dynamic> json) => MetricCard(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        value: (json['value'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? '',
        hint: json['hint'] as String? ?? '',
      );

  final String key;
  final String label;
  final double? value;
  final String unit;
  final String hint;

  /// True bila kartu ini adalah persentase.
  ///
  /// Dibaca dari `unit`, BUKAN dari `key`: backend memutuskan satuan, dan
  /// menebaknya dari nama kunci akan salah begitu ada metrik persentase baru.
  bool get isPercentage => unit == '%';

  bool get hasValue => value != null;

  /// Angka siap tampil. Persentase dibulatkan ke bilangan bulat karena
  /// desimalnya tidak bermakna pada kelompok berukuran puluhan.
  String get displayValue {
    final v = value;
    if (v == null) return '—';
    if (isPercentage) return '${v.round()}%';
    if (v == v.roundToDouble() && v.abs() < 1000) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String get displayUnit => isPercentage ? '' : unit;

  @override
  List<Object?> get props => [key, label, value, unit, hint];
}

/// Satu potong sebaran tingkat perhatian prodi (K-DAS-07).
///
/// Hanya persentase — backend sengaja tidak mengirim jumlah mentah, karena itu
/// akan membatalkan D-9 lewat pintu belakang (jumlah "Perlu Intervensi" bisa
/// dibaca langsung dari sebaran).
class EwsShare extends Equatable {
  const EwsShare({
    required this.level,
    required this.levelLabel,
    required this.percentage,
  });

  factory EwsShare.fromJson(Map<String, dynamic> json) => EwsShare(
        level: json['level'] as String? ?? '',
        levelLabel: json['level_label'] as String? ?? '',
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      );

  final String level;
  final String levelLabel;
  final double percentage;

  @override
  List<Object?> get props => [level, levelLabel, percentage];
}

/// Dashboard prodi — 6 metrik + sebaran tingkat perhatian.
class ProgramDashboard extends Equatable {
  const ProgramDashboard({
    required this.isSufficient,
    required this.minimumGroupSize,
    required this.periodDays,
    this.groupSize = 0,
    this.message,
    this.metrics = const [],
    this.ewsDistribution = const [],
  });

  factory ProgramDashboard.fromJson(Map<String, dynamic> json) =>
      ProgramDashboard(
        isSufficient: json['is_sufficient'] as bool? ?? false,
        minimumGroupSize: json['minimum_group_size'] as int? ?? 5,
        periodDays: json['period_days'] as int? ?? 30,
        groupSize: json['group_size'] as int? ?? 0,
        message: json['message'] as String?,
        metrics: (json['metrics'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MetricCard.fromJson)
            .toList(),
        ewsDistribution: (json['ews_distribution'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EwsShare.fromJson)
            .toList(),
      );

  const ProgramDashboard.initial()
      : isSufficient = false,
        minimumGroupSize = 5,
        periodDays = 30,
        groupSize = 0,
        message = null,
        metrics = const [],
        ewsDistribution = const [];

  final bool isSufficient;
  final int minimumGroupSize;
  final int periodDays;
  final int groupSize;
  final String? message;
  final List<MetricCard> metrics;
  final List<EwsShare> ewsDistribution;

  bool get hasEwsDistribution => ewsDistribution.isNotEmpty;

  @override
  List<Object?> get props => [
        isSufficient,
        minimumGroupSize,
        periodDays,
        groupSize,
        message,
        metrics,
        ewsDistribution,
      ];
}

/// Ringkasan mahasiswa bimbingan seorang dosen.
class AdviseeSummary extends Equatable {
  const AdviseeSummary({
    required this.id,
    required this.fullName,
    required this.studentNumber,
    required this.email,
  });

  factory AdviseeSummary.fromJson(Map<String, dynamic> json) => AdviseeSummary(
        id: json['id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        studentNumber: json['student_number'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  final String id;
  final String fullName;
  final String studentNumber;
  final String email;

  @override
  List<Object?> get props => [id, fullName, studentNumber, email];
}

/// Mahasiswa prodi beserta info dosen pembimbingnya saat ini.
class ProgramStudent extends Equatable {
  const ProgramStudent({
    required this.id,
    required this.fullName,
    required this.studentNumber,
    required this.email,
    this.advisorId,
    this.advisorName = '',
  });

  factory ProgramStudent.fromJson(Map<String, dynamic> json) => ProgramStudent(
        id: json['id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        studentNumber: json['student_number'] as String? ?? '',
        email: json['email'] as String? ?? '',
        advisorId: json['advisor_id'] as String?,
        advisorName: json['advisor_name'] as String? ?? '',
      );

  final String id;
  final String fullName;
  final String studentNumber;
  final String email;
  final String? advisorId;
  final String advisorName;

  bool get hasAdvisor => advisorId != null && advisorId!.isNotEmpty;

  @override
  List<Object?> get props =>
      [id, fullName, studentNumber, email, advisorId, advisorName];
}

/// Beban bimbingan seorang dosen (K-PEM-01).
///
/// Jumlah bimbingan adalah data ADMINISTRATIF, bukan data kondisi, sehingga
/// tidak tunduk k-anonymity dan ditampilkan apa adanya.
class AdvisorLoad extends Equatable {
  const AdvisorLoad({
    required this.advisorId,
    required this.fullName,
    required this.email,
    required this.adviseeCount,
    this.lecturerNumber = '',
    this.advisees = const [],
  });

  factory AdvisorLoad.fromJson(Map<String, dynamic> json) => AdvisorLoad(
        advisorId: json['advisor_id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        adviseeCount: json['advisee_count'] as int? ?? 0,
        lecturerNumber: json['lecturer_number'] as String? ?? '',
        advisees: (json['advisees'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdviseeSummary.fromJson)
            .toList(),
      );

  final String advisorId;
  final String fullName;
  final String email;
  final int adviseeCount;
  final String lecturerNumber;
  final List<AdviseeSummary> advisees;

  @override
  List<Object?> get props =>
      [advisorId, fullName, email, adviseeCount, lecturerNumber, advisees];
}

/// Ringkasan satu angkatan (K-LAP-01).
/// Angkatan dengan anggota di bawah ambang tetap tampil, namun tanpa angka.
class CohortReport extends Equatable {
  const CohortReport({
    required this.cohortYear,
    required this.isSufficient,
    required this.minimumGroupSize,
    this.groupSize = 0,
    this.message,
    this.avgMood,
    this.avgStress,
    this.avgSleepHours,
    this.activeStudents,
  });

  factory CohortReport.fromJson(Map<String, dynamic> json) => CohortReport(
        cohortYear: json['cohort_year'] as int? ?? 0,
        isSufficient: json['is_sufficient'] as bool? ?? false,
        minimumGroupSize: json['minimum_group_size'] as int? ?? 5,
        groupSize: json['group_size'] as int? ?? 0,
        message: json['message'] as String?,
        avgMood: (json['avg_mood'] as num?)?.toDouble(),
        avgStress: (json['avg_stress'] as num?)?.toDouble(),
        avgSleepHours: (json['avg_sleep_hours'] as num?)?.toDouble(),
        activeStudents: json['active_students'] as int?,
      );

  final int cohortYear;
  final bool isSufficient;
  final int minimumGroupSize;
  final int groupSize;
  final String? message;
  final double? avgMood;
  final double? avgStress;
  final double? avgSleepHours;
  final int? activeStudents;

  @override
  List<Object?> get props => [
        cohortYear,
        isSufficient,
        minimumGroupSize,
        groupSize,
        message,
        avgMood,
        avgStress,
        avgSleepHours,
        activeStudents,
      ];
}

/// Tab Profil kaprodi (K-PRO-01).
class ProgramProfile extends Equatable {
  const ProgramProfile({
    required this.programId,
    required this.programName,
    required this.totalStudents,
    required this.totalAdvisors,
    required this.accessLimits,
  });

  factory ProgramProfile.fromJson(Map<String, dynamic> json) => ProgramProfile(
        programId: json['program_id'] as String? ?? '',
        programName: json['program_name'] as String? ?? '',
        totalStudents: json['total_students'] as int? ?? 0,
        totalAdvisors: json['total_advisors'] as int? ?? 0,
        accessLimits: (json['access_limits'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
      );

  const ProgramProfile.empty()
      : programId = '',
        programName = '',
        totalStudents = 0,
        totalAdvisors = 0,
        accessLimits = const [];

  final String programId;
  final String programName;
  final int totalStudents;
  final int totalAdvisors;
  final List<String> accessLimits;

  @override
  List<Object?> get props =>
      [programId, programName, totalStudents, totalAdvisors, accessLimits];
}
