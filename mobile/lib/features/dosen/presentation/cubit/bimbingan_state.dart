part of 'bimbingan_cubit.dart';

enum BimbinganStatus { initial, loading, ready, failure }

class BimbinganState extends Equatable {
  const BimbinganState({
    this.status = BimbinganStatus.initial,
    this.advisees = const [],
    this.contactRequests = const [],
    this.totalAdvisees = 0,
    this.errorMessage,
  });

  final BimbinganStatus status;
  final List<Advisee> advisees;
  final List<ContactRequest> contactRequests;
  final int totalAdvisees;
  final String? errorMessage;

  bool get isLoading =>
      status == BimbinganStatus.loading || status == BimbinganStatus.initial;

  bool get isEmpty => status == BimbinganStatus.ready && advisees.isEmpty;

  bool get hasContactRequests => contactRequests.isNotEmpty;

  /// Jumlah mahasiswa yang perlu disapa lebih dulu — dipakai badge ringkasan.
  /// Menghitung dari level yang benar-benar dibagikan; mahasiswa yang tidak
  /// membagikan EWS tidak diasumsikan aman, hanya tidak ikut dihitung.
  int get needAttentionCount => advisees
      .where((a) => a.ewsLevel == 'INTERVENTION' || a.ewsLevel == 'RISK')
      .length;

  BimbinganState copyWith({
    BimbinganStatus? status,
    List<Advisee>? advisees,
    List<ContactRequest>? contactRequests,
    int? totalAdvisees,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BimbinganState(
      status: status ?? this.status,
      advisees: advisees ?? this.advisees,
      contactRequests: contactRequests ?? this.contactRequests,
      totalAdvisees: totalAdvisees ?? this.totalAdvisees,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, advisees, contactRequests, totalAdvisees, errorMessage];
}
