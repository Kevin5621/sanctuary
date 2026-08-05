import 'package:equatable/equatable.dart';

/// Satu potong sebaran emosi kelompok.
///
/// Hanya LABEL emosi dan jumlahnya — tidak pernah teks jurnal yang
/// menghasilkannya (L-KON-03).
class EmotionShare extends Equatable {
  const EmotionShare({
    required this.emotionLabel,
    required this.total,
    required this.percentage,
  });

  factory EmotionShare.fromJson(Map<String, dynamic> json) => EmotionShare(
        emotionLabel: json['emotion_label'] as String? ?? '',
        total: json['total'] as int? ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      );

  final String emotionLabel;
  final int total;
  final double percentage;

  /// Label bahasa Indonesia untuk keluaran analisis.
  ///
  /// Mengikuti D-2: `JOY`/`SAD`/`ANGRY`/`ANXIOUS` adalah keluaran model,
  /// `NEUTRAL` dipakai saat keyakinan rendah, sedangkan `CALM` & `TIRED`
  /// berasal dari check-in manual mahasiswa — bukan keluaran model.
  String get displayLabel => switch (emotionLabel) {
        'JOY' => 'Senang',
        'SAD' => 'Sedih',
        'ANGRY' => 'Marah',
        'ANXIOUS' => 'Cemas',
        'NEUTRAL' => 'Netral',
        'CALM' => 'Tenang',
        'TIRED' => 'Lelah',
        _ => emotionLabel,
      };

  bool get isNegative => const {'SAD', 'ANGRY', 'ANXIOUS', 'TIRED'}
      .contains(emotionLabel);

  @override
  List<Object?> get props => [emotionLabel, total, percentage];
}

/// Agregat kelompok bimbingan (tab Kondisi, L-KON-01..04).
///
/// Bila [isSufficient] false, SELURUH angka bernilai null — termasuk
/// [groupSize] yang dikirim server sebagai 0. UI wajib menampilkan
/// "Data belum cukup" dan tidak boleh menyulap null menjadi 0 (I-4).
class GroupCondition extends Equatable {
  const GroupCondition({
    required this.isSufficient,
    required this.minimumGroupSize,
    required this.periodDays,
    this.groupSize = 0,
    this.message,
    this.avgMood,
    this.avgStress,
    this.avgSleepHours,
    this.ewsDistribution = const {},
    this.emotionDistribution = const [],
  });

  factory GroupCondition.fromJson(Map<String, dynamic> json) {
    final rawEws = json['ews_distribution'];

    return GroupCondition(
      isSufficient: json['is_sufficient'] as bool? ?? false,
      minimumGroupSize: json['minimum_group_size'] as int? ?? 5,
      periodDays: json['period_days'] as int? ?? 30,
      groupSize: json['group_size'] as int? ?? 0,
      message: json['message'] as String?,
      avgMood: (json['avg_mood'] as num?)?.toDouble(),
      avgStress: (json['avg_stress'] as num?)?.toDouble(),
      avgSleepHours: (json['avg_sleep_hours'] as num?)?.toDouble(),
      ewsDistribution: rawEws is Map<String, dynamic>
          ? rawEws.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0))
          : const {},
      emotionDistribution:
          (json['emotion_distribution'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(EmotionShare.fromJson)
              .toList(),
    );
  }

  const GroupCondition.initial()
      : isSufficient = false,
        minimumGroupSize = 5,
        periodDays = 30,
        groupSize = 0,
        message = null,
        avgMood = null,
        avgStress = null,
        avgSleepHours = null,
        ewsDistribution = const {},
        emotionDistribution = const [];

  final bool isSufficient;
  final int minimumGroupSize;
  final int periodDays;
  final int groupSize;
  final String? message;
  final double? avgMood;
  final double? avgStress;
  final double? avgSleepHours;

  /// Sebaran tingkat perhatian dalam JUMLAH mahasiswa.
  ///
  /// Berbeda dari dashboard Kaprodi yang memakai persentase (D-9): dosen sudah
  /// melihat level per mahasiswa bimbingannya satu per satu di tab Bimbingan,
  /// sehingga jumlah di sini tidak membuka informasi baru. Kaprodi tidak punya
  /// akses itu, karena itu untuknya angka mentah tidak dikeluarkan.
  final Map<String, int> ewsDistribution;

  final List<EmotionShare> emotionDistribution;

  bool get hasEwsDistribution => ewsDistribution.isNotEmpty;
  bool get hasEmotionDistribution => emotionDistribution.isNotEmpty;

  /// Sebaran EWS terurut dari tingkat perhatian tertinggi.
  List<MapEntry<String, int>> get orderedEwsDistribution {
    const order = ['INTERVENTION', 'RISK', 'WATCH', 'NORMAL', 'INSUFFICIENT_DATA'];
    final entries = ewsDistribution.entries.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a.key);
        final ib = order.indexOf(b.key);
        return (ia < 0 ? order.length : ia).compareTo(ib < 0 ? order.length : ib);
      });
    return entries;
  }

  int get ewsTotal =>
      ewsDistribution.values.fold(0, (sum, value) => sum + value);

  @override
  List<Object?> get props => [
        isSufficient,
        minimumGroupSize,
        periodDays,
        groupSize,
        message,
        avgMood,
        avgStress,
        avgSleepHours,
        ewsDistribution,
        emotionDistribution,
      ];
}
