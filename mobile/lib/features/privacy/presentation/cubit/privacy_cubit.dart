import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/privacy_repository.dart';
import '../../domain/entities/privacy_setting.dart';

part 'privacy_state.dart';

/// Cubit layar Privasi & Berbagi Data.
///
/// Perubahan bersifat eksplisit: pilihan pengguna disimpan sebagai draft dan
/// baru dikirim saat menekan Simpan, sehingga tidak ada perubahan izin privasi
/// yang terjadi tanpa disadari.
class PrivacyCubit extends Cubit<PrivacyState> {
  PrivacyCubit(this._repository) : super(const PrivacyState());

  final PrivacyRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: PrivacyStatus.loading, clearError: true));

    try {
      final results = await Future.wait([
        _repository.fetch(),
        _repository.fetchOptions(),
      ]);

      final setting = results[0] as PrivacySetting;
      final options = results[1] as List<PrivacyOption>;

      emit(state.copyWith(
        status: PrivacyStatus.ready,
        saved: setting,
        draft: setting,
        options: options,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: PrivacyStatus.failure,
        errorMessage: error.message,
      ));
    }
  }

  void selectShareLevel(ShareLevel level) {
    var draft = state.draft.copyWith(shareLevel: level);

    // Cerminan aturan backend: pada tingkat Tertutup, peringatan dini
    // otomatis ikut nonaktif. Ditampilkan langsung agar pengguna melihat
    // konsekuensinya sebelum menyimpan.
    if (level == ShareLevel.closed) {
      draft = draft.copyWith(allowEarlyWarning: false);
    }
    emit(state.copyWith(draft: draft, clearError: true, clearSuccess: true));
  }

  void toggleEarlyWarning(bool value) {
    if (state.draft.shareLevel == ShareLevel.closed && value) return;
    emit(state.copyWith(
      draft: state.draft.copyWith(allowEarlyWarning: value),
      clearError: true,
      clearSuccess: true,
    ));
  }

  void toggleProgramStatistic(bool value) {
    emit(state.copyWith(
      draft: state.draft.copyWith(allowProgramStatistic: value),
      clearError: true,
      clearSuccess: true,
    ));
  }

  Future<void> save() async {
    if (!state.hasChanges) return;
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));

    try {
      final updated = await _repository.update(state.draft);
      emit(state.copyWith(
        status: PrivacyStatus.ready,
        saved: updated,
        draft: updated,
        isSaving: false,
        successMessage: 'Pengaturan privasi tersimpan.',
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.message));
    }
  }

  void discardChanges() {
    emit(state.copyWith(draft: state.saved, clearError: true, clearSuccess: true));
  }
}
