part of 'terapis_ai_cubit.dart';

enum TerapisAiStatus { initial, loading, ready, failure }

class TerapisAiState extends Equatable {
  const TerapisAiState({
    this.status = TerapisAiStatus.initial,
    this.consent = const AiConsentStatus.unknown(),
    this.history = const AiChatHistory.empty(),
    this.isSending = false,
    this.isSubmittingConsent = false,
    this.showCrisisCard = false,
    this.crisisMessage = '',
    this.lastFailedMessage = '',
    this.forceConsentView = false,
    this.errorMessage,
  });

  final TerapisAiStatus status;
  final AiConsentStatus consent;
  final AiChatHistory history;

  /// Menunggu balasan model.
  final bool isSending;
  final bool isSubmittingConsent;

  final bool showCrisisCard;
  final String crisisMessage;

  /// Teks yang gagal terkirim, disimpan agar tombol "Coba lagi" punya isi.
  final String lastFailedMessage;

  /// Mahasiswa yang menolak meminta membaca ulang pemberitahuan.
  final bool forceConsentView;

  final String? errorMessage;

  bool get isLoading => status == TerapisAiStatus.loading;

  /// Layar yang harus ditampilkan tab ini.
  ///
  /// Urutannya penting: consent diperiksa SEBELUM apa pun yang lain, sehingga
  /// tidak ada jalan menuju layar chat tanpa melewati keputusan D-5.
  TerapisAiView get view {
    if (status == TerapisAiStatus.initial || status == TerapisAiStatus.loading) {
      return TerapisAiView.loading;
    }
    if (consent.mustShowConsent || forceConsentView) return TerapisAiView.consent;
    if (consent.hasDeclined) return TerapisAiView.selfHelp;
    if (!consent.serviceAvailable) return TerapisAiView.serviceUnavailable;
    if (status == TerapisAiStatus.failure) return TerapisAiView.failure;
    return TerapisAiView.chat;
  }

  bool get hasRetryableMessage => lastFailedMessage.isNotEmpty;

  TerapisAiState copyWith({
    TerapisAiStatus? status,
    AiConsentStatus? consent,
    AiChatHistory? history,
    bool? isSending,
    bool? isSubmittingConsent,
    bool? showCrisisCard,
    String? crisisMessage,
    String? lastFailedMessage,
    bool? forceConsentView,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TerapisAiState(
      status: status ?? this.status,
      consent: consent ?? this.consent,
      history: history ?? this.history,
      isSending: isSending ?? this.isSending,
      isSubmittingConsent: isSubmittingConsent ?? this.isSubmittingConsent,
      showCrisisCard: showCrisisCard ?? this.showCrisisCard,
      crisisMessage: crisisMessage ?? this.crisisMessage,
      lastFailedMessage: lastFailedMessage ?? this.lastFailedMessage,
      forceConsentView: forceConsentView ?? this.forceConsentView,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        consent,
        history,
        isSending,
        isSubmittingConsent,
        showCrisisCard,
        crisisMessage,
        lastFailedMessage,
        forceConsentView,
        errorMessage,
      ];
}

/// Layar aktif tab Terapis AI.
enum TerapisAiView {
  loading,

  /// Pemberitahuan pihak ketiga + pilihan Setuju/Tolak (M-AI-01).
  consent,

  /// Mahasiswa menolak — tab tetap ada, isinya latihan mandiri (M-PRO-05).
  selfHelp,

  /// Sudah setuju tapi server belum mengonfigurasi penyedia AI.
  serviceUnavailable,

  chat,
  failure,
}
