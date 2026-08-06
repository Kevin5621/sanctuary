import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/ai_chat_repository.dart';
import '../../domain/entities/ai_chat.dart';

part 'terapis_ai_state.dart';

/// Cubit tab Terapis AI.
///
/// Alur yang dijaga di sini:
///   1. Buka tab  → muat status consent (BUKAN riwayat).
///   2. Consent ok → baru muat riwayat percakapan.
///   3. Belum/tolak → tidak ada satu pun request ke endpoint isi chat.
///
/// Urutan itu penting: memuat riwayat lebih dulu akan memicu
/// AI_CONSENT_REQUIRED pada mahasiswa yang belum memutuskan, dan menampilkan
/// error merah di layar yang seharusnya menampilkan pemberitahuan privasi.
class TerapisAiCubit extends Cubit<TerapisAiState> {
  TerapisAiCubit(this._repository) : super(const TerapisAiState());

  final AiChatRepository _repository;

  /// Dipanggil saat tab dibuka.
  Future<void> load() async {
    emit(state.copyWith(status: TerapisAiStatus.loading, clearError: true));

    try {
      final consent = await _repository.fetchConsentStatus();

      if (!consent.canChat) {
        // Belum setuju / menolak / layanan mati: berhenti di sini.
        emit(state.copyWith(status: TerapisAiStatus.ready, consent: consent));
        return;
      }

      final history = await _repository.fetchHistory();
      emit(state.copyWith(
        status: TerapisAiStatus.ready,
        consent: consent,
        history: history,
        crisisMessage: history.crisisMessage,
        showCrisisCard: history.crisisMessage.isNotEmpty,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: TerapisAiStatus.failure,
        errorMessage: error.message,
      ));
    }
  }

  Future<void> refresh() => load();

  /// Merekam keputusan consent.
  Future<void> decideConsent({required bool accepted}) async {
    final version = state.consent.notice.noticeVersion;
    if (version.isEmpty) {
      // Tanpa versi pemberitahuan, tidak ada yang bisa disetujui secara sah.
      await load();
      return;
    }

    emit(state.copyWith(isSubmittingConsent: true, clearError: true));

    try {
      final consent = await _repository.submitConsent(
        accepted: accepted,
        noticeVersion: version,
      );

      if (!consent.canChat) {
        emit(state.copyWith(
          status: TerapisAiStatus.ready,
          consent: consent,
          isSubmittingConsent: false,
          forceConsentView: false,
          // Menolak berarti riwayat sudah dihapus server — bersihkan juga di UI
          // supaya tidak ada sisa percakapan yang masih terlihat.
          history: const AiChatHistory.empty(),
          showCrisisCard: false,
          crisisMessage: '',
        ));
        return;
      }

      final history = await _repository.fetchHistory();
      emit(state.copyWith(
        status: TerapisAiStatus.ready,
        consent: consent,
        history: history,
        isSubmittingConsent: false,
        forceConsentView: false,
      ));
    } on ApiException catch (error) {
      // Versi pemberitahuan berubah di tengah jalan: muat ulang agar mahasiswa
      // membaca teks terbaru sebelum memutuskan.
      if (error.code == ApiErrorCode.aiConsentVersionMismatch) {
        emit(state.copyWith(isSubmittingConsent: false));
        await load();
        return;
      }
      emit(state.copyWith(
        isSubmittingConsent: false,
        status: TerapisAiStatus.failure,
        errorMessage: error.message,
      ));
    }
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return;

    // Tampilkan pesan mahasiswa lebih dulu agar layar terasa responsif.
    final optimistic = List<AiChatMessage>.from(state.history.messages)
      ..add(AiChatMessage.pendingFromStudent(text));

    emit(state.copyWith(
      history: state.history.copyWith(messages: optimistic),
      isSending: true,
      clearError: true,
      lastFailedMessage: '',
    ));

    try {
      final result = await _repository.sendMessage(text);

      // Ganti pesan sementara dengan yang benar-benar tersimpan di server.
      final settled = List<AiChatMessage>.from(state.history.messages)
        ..removeWhere((message) => message.isPending)
        ..add(result.userMessage)
        ..add(result.aiMessage.copyWith(isFallback: result.isFallback));

      emit(state.copyWith(
        history: state.history.copyWith(messages: settled),
        isSending: false,
        // Kartu krisis muncul begitu server menandainya, dan tetap tampil
        // sampai mahasiswa menutupnya sendiri.
        showCrisisCard: result.isCrisisFlagged || state.showCrisisCard,
        crisisMessage:
            result.crisisMessage.isNotEmpty ? result.crisisMessage : state.crisisMessage,
      ));
    } on ApiException catch (error) {
      // Buang pesan sementara dan simpan teksnya supaya bisa dikirim ulang —
      // tulisan mahasiswa tidak boleh hilang begitu saja karena gangguan.
      final reverted = List<AiChatMessage>.from(state.history.messages)
        ..removeWhere((message) => message.isPending);

      if (error.code == ApiErrorCode.aiConsentRequired) {
        // Gate ditutup di server (mis. consent dicabut dari perangkat lain).
        emit(state.copyWith(
          history: state.history.copyWith(messages: reverted),
          isSending: false,
          lastFailedMessage: text,
        ));
        await load();
        return;
      }

      emit(state.copyWith(
        history: state.history.copyWith(messages: reverted),
        isSending: false,
        errorMessage: error.message,
        lastFailedMessage: text,
      ));
    }
  }

  /// Mengirim ulang pesan terakhir yang gagal.
  Future<void> retryLastMessage() async {
    final pending = state.lastFailedMessage;
    if (pending.isEmpty) return;
    await sendMessage(pending);
  }

  /// Menampilkan ulang layar consent bagi mahasiswa yang sebelumnya menolak.
  ///
  /// Keputusan menolak tidak boleh menjadi jalan buntu: mahasiswa harus bisa
  /// membaca kembali pemberitahuannya dan berubah pikiran tanpa harus mencari
  /// menu tersembunyi.
  void reopenConsent() => emit(state.copyWith(forceConsentView: true));

  void dismissCrisisCard() => emit(state.copyWith(showCrisisCard: false));

  void clearError() => emit(state.copyWith(clearError: true, lastFailedMessage: ''));
}
