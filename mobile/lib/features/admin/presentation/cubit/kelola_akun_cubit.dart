import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/entities/study_program.dart';
import '../../data/repositories/user_admin_repository.dart';
import '../../domain/entities/managed_user.dart';

part 'kelola_akun_state.dart';

/// Cubit halaman kelola akun Admin (A-AKN-01..03).
class KelolaAkunCubit extends Cubit<KelolaAkunState> {
  KelolaAkunCubit(this._repository) : super(const KelolaAkunState());

  final UserAdminRepository _repository;

  Future<void> load({bool withOptions = false}) async {
    emit(state.copyWith(status: AkunStatus.loading, clearMessages: true));

    try {
      final users = await _repository.fetchAll(role: state.roleFilter);
      // Opsi formulir hanya diambil sekali per sesi halaman: isinya data
      // referensi yang jarang berubah, dan mengambilnya di setiap refresh
      // hanya menambah beban tanpa menambah kebenaran.
      final options = withOptions && state.options.isEmpty
          ? await _repository.fetchFormOptions()
          : state.options;

      emit(state.copyWith(
        status: AkunStatus.ready,
        users: users,
        options: options,
        clearMessages: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: AkunStatus.failure,
        errorMessage: error.message,
      ));
    }
  }

  Future<void> refresh() => load(withOptions: state.options.isEmpty);

  /// Menyaring daftar per peran. Null berarti seluruh akun staf.
  Future<void> filterByRole(String? role) async {
    if (role == state.roleFilter) return;
    emit(state.copyWith(roleFilter: role, clearRoleFilter: role == null));
    await load();
  }

  /// [id] kosong berarti membuat akun baru.
  Future<bool> save(StaffAccountDraft draft, {String id = ''}) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));

    try {
      final saved = id.isEmpty
          ? await _repository.create(draft)
          : await _repository.update(id, draft);

      // Muat ulang daftar penuh alih-alih menyisipkan hasil di memori:
      // urutan dan penyaringan ditentukan server, jadi menebaknya di klien
      // berisiko menyimpang dari yang sebenarnya tersimpan.
      await load();

      emit(state.copyWith(
        isSaving: false,
        successMessage: id.isEmpty
            ? 'Akun ${saved.fullName} dibuat.'
            : 'Akun ${saved.fullName} diperbarui.',
      ));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: error.message,
        fieldErrors: {
          for (final field in error.fieldErrors) field.field: field.message,
        },
      ));
      return false;
    }
  }

  /// Mengaktifkan / menonaktifkan tanpa membuka formulir.
  ///
  /// Menonaktifkan akun juga mencabut seluruh sesi aktif miliknya di server —
  /// akun "dinonaktifkan" yang masih dapat membuka data bimbingan adalah
  /// kegagalan keamanan, bukan sekadar keterlambatan tampilan.
  Future<bool> toggleActive(ManagedUser user) => save(
        StaffAccountDraft(
          fullName: user.fullName,
          role: user.role,
          studyProgramId: user.studyProgramId ?? '',
          lecturerNumber: user.lecturerNumber,
          phone: user.phone,
          isActive: !user.isActive,
        ),
        id: user.id,
      );

  void clearMessages() => emit(state.copyWith(clearMessages: true));
}
