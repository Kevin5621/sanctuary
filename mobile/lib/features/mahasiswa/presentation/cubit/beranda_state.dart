part of 'beranda_cubit.dart';

enum BerandaStatus { initial, loading, ready, failure }

class BerandaState extends Equatable {
  const BerandaState({
    this.status = BerandaStatus.initial,
    this.summary = const WeeklyMoodSummary.empty(),
    this.options = const CheckinOptions.empty(),
    this.contact = const ContactRequestState.empty(),
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final BerandaStatus status;
  final WeeklyMoodSummary summary;

  /// Pilihan check-in dari server. Form hanya dibuka setelah ini terisi,
  /// supaya tidak ada layar yang menampilkan daftar emosi versi klien.
  final CheckinOptions options;

  final ContactRequestState contact;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == BerandaStatus.loading || status == BerandaStatus.initial;
  bool get canCheckIn => options.isLoaded;
  bool get hasCheckedInToday => summary.hasCheckedInToday;

  /// Pengguna yang belum punya satu pun check-in minggu ini — layar
  /// menampilkan ajakan memulai, bukan kalender kosong.
  bool get isFirstTime => status == BerandaStatus.ready && summary.isEmpty;

  BerandaState copyWith({
    BerandaStatus? status,
    WeeklyMoodSummary? summary,
    CheckinOptions? options,
    ContactRequestState? contact,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BerandaState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      options: options ?? this.options,
      contact: contact ?? this.contact,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        options,
        contact,
        isSaving,
        errorMessage,
        successMessage,
      ];
}
