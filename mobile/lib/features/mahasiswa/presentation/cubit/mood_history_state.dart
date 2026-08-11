part of 'mood_history_cubit.dart';

enum MoodHistoryStatus { initial, loading, ready, failure }

class MoodHistoryState extends Equatable {
  const MoodHistoryState({
    this.status = MoodHistoryStatus.initial,
    this.monthly = const MonthlyMood.empty(),
    this.stats = const MoodStats.empty(),
    this.options = const CheckinOptions.empty(),
    this.month = '',
    this.periodDays = 30,
    this.isMonthLoading = false,
    this.isStatsLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final MoodHistoryStatus status;
  final MonthlyMood monthly;
  final MoodStats stats;

  /// Pilihan check-in dari server — dipakai form yang dibuka dari kalender.
  /// Selama belum termuat, tidak ada tanggal yang boleh diketuk: form tidak
  /// boleh menampilkan skala atau daftar emosi versi klien.
  final CheckinOptions options;

  /// Bulan yang sedang ditampilkan kalender (YYYY-MM); kosong = bulan berjalan.
  final String month;

  /// Periode grafik & sebaran emosi, terpisah dari bulan kalender.
  final int periodDays;

  final bool isMonthLoading;
  final bool isStatsLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == MoodHistoryStatus.loading || status == MoodHistoryStatus.initial;

  /// Belum pernah check-in sama sekali — layar menampilkan ajakan memulai,
  /// bukan kalender kosong yang terlihat seperti kegagalan memuat.
  bool get isEmpty =>
      status == MoodHistoryStatus.ready && stats.checkinCount == 0 && monthly.checkinCount == 0;

  /// Apakah [date] masih boleh diisi check-in dari kalender.
  ///
  /// Batas mundurnya (maxBackdateDays) datang dari server dan tetap divalidasi
  /// di sana; pemeriksaan ini hanya menjaga agar form tidak terbuka untuk
  /// tanggal yang sudah pasti ditolak.
  bool canCheckInOn(DateTime date) {
    if (!options.isLoaded) return false;

    final today = _dateOnly(DateTime.now());
    final target = _dateOnly(date);

    if (target.isAfter(today)) return false;
    return !target.isBefore(_dateOnly(options.earliestDate(today)));
  }

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  MoodHistoryState copyWith({
    MoodHistoryStatus? status,
    MonthlyMood? monthly,
    MoodStats? stats,
    CheckinOptions? options,
    String? month,
    int? periodDays,
    bool? isMonthLoading,
    bool? isStatsLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return MoodHistoryState(
      status: status ?? this.status,
      monthly: monthly ?? this.monthly,
      stats: stats ?? this.stats,
      options: options ?? this.options,
      month: month ?? this.month,
      periodDays: periodDays ?? this.periodDays,
      isMonthLoading: isMonthLoading ?? this.isMonthLoading,
      isStatsLoading: isStatsLoading ?? this.isStatsLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        monthly,
        stats,
        options,
        month,
        periodDays,
        isMonthLoading,
        isStatsLoading,
        isSaving,
        errorMessage,
        successMessage,
      ];
}
