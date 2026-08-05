import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/emergency_contact_repository.dart';
import '../../domain/entities/emergency_contact.dart';

part 'emergency_contact_state.dart';

/// Cubit layanan bantuan darurat.
///
/// Dipakai dua layar berbeda:
///   · Admin  — CRUD penuh (A-BAN-01..04)
///   · Peran lain — daftar baca saja (A-BAN-03)
///
/// [loadServiceTypes] hanya dipanggil layar Admin, karena hanya form Admin yang
/// membutuhkan daftar pilihan jenis layanan.
class EmergencyContactCubit extends Cubit<EmergencyContactState> {
  EmergencyContactCubit(this._repository)
      : super(const EmergencyContactState());

  final EmergencyContactRepository _repository;

  Future<void> load({bool withServiceTypes = false}) async {
    emit(state.copyWith(status: ContactStatus.loading, clearMessages: true));

    try {
      final contacts = await _repository.fetchAll();
      final serviceTypes = withServiceTypes && state.serviceTypes.isEmpty
          ? await _repository.fetchServiceTypes()
          : state.serviceTypes;

      emit(state.copyWith(
        status: ContactStatus.ready,
        contacts: contacts,
        serviceTypes: serviceTypes,
        clearMessages: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: ContactStatus.failure,
        errorMessage: error.message,
      ));
    }
  }

  Future<void> refresh() => load(withServiceTypes: state.serviceTypes.isEmpty);

  Future<bool> save(EmergencyContact contact) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));

    try {
      // Id kosong berarti entri baru; selain itu memperbarui yang sudah ada.
      final saved = contact.id.isEmpty
          ? await _repository.create(contact)
          : await _repository.update(contact);

      // Muat ulang daftar penuh alih-alih menyisipkan hasil di memori:
      // urutan (sort_order) dan penyaringan aktif ditentukan server, jadi
      // menebaknya di klien berisiko menyimpang dari yang sebenarnya tersimpan.
      await load();

      emit(state.copyWith(
        isSaving: false,
        successMessage: contact.id.isEmpty
            ? 'Layanan "${saved.name}" ditambahkan.'
            : 'Layanan "${saved.name}" diperbarui.',
      ));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.message));
      return false;
    }
  }

  Future<bool> delete(EmergencyContact contact) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));

    try {
      await _repository.delete(contact.id);
      await load();
      emit(state.copyWith(
        isSaving: false,
        successMessage: 'Layanan "${contact.name}" dihapus.',
      ));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.message));
      return false;
    }
  }

  /// Mengaktifkan / menonaktifkan tanpa membuka form.
  ///
  /// Menonaktifkan berarti nomor itu hilang sepenuhnya dari tampilan peran
  /// lain (A-BAN-02) — bukan sekadar ditandai — sehingga dipakai saat sebuah
  /// nomor diragukan tetapi belum ingin dihapus.
  Future<bool> toggleActive(EmergencyContact contact) =>
      save(contact.copyWith(isActive: !contact.isActive));

  void clearMessages() => emit(state.copyWith(clearMessages: true));
}
