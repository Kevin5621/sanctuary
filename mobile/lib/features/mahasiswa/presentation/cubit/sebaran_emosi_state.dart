part of 'sebaran_emosi_cubit.dart';

enum SebaranEmosiStatus { initial, loading, ready, failure }

class SebaranEmosiState extends Equatable {
  const SebaranEmosiState({
    this.status = SebaranEmosiStatus.initial,
    this.distribution = const EmotionDistribution.initial(),
    this.rangeDays = 30,
    this.errorMessage,
  });

  final SebaranEmosiStatus status;
  final EmotionDistribution distribution;
  final int rangeDays;
  final String? errorMessage;

  bool get isLoading =>
      status == SebaranEmosiStatus.loading || status == SebaranEmosiStatus.initial;

  /// Empty state ditentukan server (is_empty), bukan disimpulkan dari panjang
  /// list — supaya "belum ada jurnal dianalisis" dan "gagal memuat" tidak
  /// pernah tampil sebagai layar yang sama.
  bool get isEmpty =>
      status == SebaranEmosiStatus.ready && distribution.isEmpty;

  bool get hasData =>
      status == SebaranEmosiStatus.ready && !distribution.isEmpty;

  SebaranEmosiState copyWith({
    SebaranEmosiStatus? status,
    EmotionDistribution? distribution,
    int? rangeDays,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SebaranEmosiState(
      status: status ?? this.status,
      distribution: distribution ?? this.distribution,
      rangeDays: rangeDays ?? this.rangeDays,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, distribution, rangeDays, errorMessage];
}
