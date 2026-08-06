part of 'mood_history_cubit.dart';

enum MoodHistoryStatus { initial, loading, ready, failure }

class MoodHistoryState extends Equatable {
  const MoodHistoryState({
    this.status = MoodHistoryStatus.initial,
    this.monthly = const MonthlyMood.empty(),
    this.stats = const MoodStats.empty(),
    this.month = '',
    this.periodDays = 30,
    this.isMonthLoading = false,
    this.isStatsLoading = false,
    this.errorMessage,
  });

  final MoodHistoryStatus status;
  final MonthlyMood monthly;
  final MoodStats stats;

  /// Bulan yang sedang ditampilkan kalender (YYYY-MM); kosong = bulan berjalan.
  final String month;

  /// Periode grafik & sebaran emosi, terpisah dari bulan kalender.
  final int periodDays;

  final bool isMonthLoading;
  final bool isStatsLoading;
  final String? errorMessage;

  bool get isLoading => status == MoodHistoryStatus.loading || status == MoodHistoryStatus.initial;

  /// Belum pernah check-in sama sekali — layar menampilkan ajakan memulai,
  /// bukan kalender kosong yang terlihat seperti kegagalan memuat.
  bool get isEmpty =>
      status == MoodHistoryStatus.ready && stats.checkinCount == 0 && monthly.checkinCount == 0;

  MoodHistoryState copyWith({
    MoodHistoryStatus? status,
    MonthlyMood? monthly,
    MoodStats? stats,
    String? month,
    int? periodDays,
    bool? isMonthLoading,
    bool? isStatsLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MoodHistoryState(
      status: status ?? this.status,
      monthly: monthly ?? this.monthly,
      stats: stats ?? this.stats,
      month: month ?? this.month,
      periodDays: periodDays ?? this.periodDays,
      isMonthLoading: isMonthLoading ?? this.isMonthLoading,
      isStatsLoading: isStatsLoading ?? this.isStatsLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        monthly,
        stats,
        month,
        periodDays,
        isMonthLoading,
        isStatsLoading,
        errorMessage,
      ];
}
