part of 'privacy_cubit.dart';

enum PrivacyStatus { initial, loading, ready, failure }

class PrivacyState extends Equatable {
  const PrivacyState({
    this.status = PrivacyStatus.initial,
    this.saved = const PrivacySetting.initial(),
    this.draft = const PrivacySetting.initial(),
    this.options = const [],
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final PrivacyStatus status;

  /// Nilai yang tersimpan di server.
  final PrivacySetting saved;

  /// Nilai yang sedang diubah pengguna (belum dikirim).
  final PrivacySetting draft;

  final List<PrivacyOption> options;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  bool get hasChanges => draft != saved;
  bool get isLoading => status == PrivacyStatus.loading;

  PrivacyState copyWith({
    PrivacyStatus? status,
    PrivacySetting? saved,
    PrivacySetting? draft,
    List<PrivacyOption>? options,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PrivacyState(
      status: status ?? this.status,
      saved: saved ?? this.saved,
      draft: draft ?? this.draft,
      options: options ?? this.options,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        saved,
        draft,
        options,
        isSaving,
        errorMessage,
        successMessage,
      ];
}
