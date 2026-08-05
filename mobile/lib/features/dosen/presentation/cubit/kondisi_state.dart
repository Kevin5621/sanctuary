part of 'kondisi_cubit.dart';

enum KondisiStatus { initial, loading, ready, failure }

class KondisiState extends Equatable {
  const KondisiState({
    this.status = KondisiStatus.initial,
    this.condition = const GroupCondition.initial(),
    this.periodDays = 30,
    this.errorMessage,
  });

  final KondisiStatus status;
  final GroupCondition condition;
  final int periodDays;
  final String? errorMessage;

  bool get isLoading =>
      status == KondisiStatus.loading || status == KondisiStatus.initial;

  /// True bila server menolak mengeluarkan angka karena kelompok < ambang.
  ///
  /// Dibaca dari `is_sufficient`, BUKAN dari angka yang kebetulan null —
  /// membedakan keduanya penting supaya kegagalan parsing tidak menyamar
  /// sebagai state privasi yang sah.
  bool get isInsufficient =>
      status == KondisiStatus.ready && !condition.isSufficient;

  KondisiState copyWith({
    KondisiStatus? status,
    GroupCondition? condition,
    int? periodDays,
    String? errorMessage,
    bool clearError = false,
  }) {
    return KondisiState(
      status: status ?? this.status,
      condition: condition ?? this.condition,
      periodDays: periodDays ?? this.periodDays,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, condition, periodDays, errorMessage];
}
