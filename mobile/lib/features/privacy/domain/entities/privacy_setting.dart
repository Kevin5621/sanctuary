import 'package:equatable/equatable.dart';

/// Tingkat berbagi data ke Dosen Pembimbing.
/// Kode string identik dengan constants.ShareLevel di backend.
enum ShareLevel {
  closed('CLOSED', 'Tertutup'),
  summary('SUMMARY', 'Ringkasan'),
  summaryTrend('SUMMARY_TREND', 'Ringkasan + Tren');

  const ShareLevel(this.code, this.label);

  final String code;
  final String label;

  static ShareLevel fromCode(String? code) => ShareLevel.values.firstWhere(
        (level) => level.code == code,
        orElse: () => ShareLevel.closed,
      );

  bool get allowsIndicator => this != ShareLevel.closed;
}

class PrivacySetting extends Equatable {
  const PrivacySetting({
    required this.shareLevel,
    required this.allowEarlyWarning,
    required this.allowProgramStatistic,
    this.effect = '',
    this.advisorCanSeeIndicator = false,
    this.advisorCanSeeTrend = false,
    this.advisorCanGetAlert = false,
  });

  const PrivacySetting.initial()
      : shareLevel = ShareLevel.closed,
        allowEarlyWarning = false,
        allowProgramStatistic = false,
        effect = '',
        advisorCanSeeIndicator = false,
        advisorCanSeeTrend = false,
        advisorCanGetAlert = false;

  final ShareLevel shareLevel;
  final bool allowEarlyWarning;
  final bool allowProgramStatistic;

  /// Penjelasan konsekuensi pilihan — dikirim backend agar teks kebijakan
  /// tidak terduplikasi (dan tidak berbeda) antara server dan klien.
  final String effect;

  final bool advisorCanSeeIndicator;
  final bool advisorCanSeeTrend;
  final bool advisorCanGetAlert;

  PrivacySetting copyWith({
    ShareLevel? shareLevel,
    bool? allowEarlyWarning,
    bool? allowProgramStatistic,
  }) {
    return PrivacySetting(
      shareLevel: shareLevel ?? this.shareLevel,
      allowEarlyWarning: allowEarlyWarning ?? this.allowEarlyWarning,
      allowProgramStatistic: allowProgramStatistic ?? this.allowProgramStatistic,
      effect: effect,
      advisorCanSeeIndicator: advisorCanSeeIndicator,
      advisorCanSeeTrend: advisorCanSeeTrend,
      advisorCanGetAlert: advisorCanGetAlert,
    );
  }

  @override
  List<Object?> get props => [shareLevel, allowEarlyWarning, allowProgramStatistic];
}

/// Pilihan tingkat berbagi beserta deskripsinya (dari backend).
class PrivacyOption extends Equatable {
  const PrivacyOption({
    required this.level,
    required this.label,
    required this.description,
  });

  final ShareLevel level;
  final String label;
  final String description;

  @override
  List<Object?> get props => [level, label, description];
}
