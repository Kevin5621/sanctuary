part of 'kelola_akun_cubit.dart';

enum AkunStatus { initial, loading, ready, failure }

class KelolaAkunState extends Equatable {
  const KelolaAkunState({
    this.status = AkunStatus.initial,
    this.users = const [],
    this.options = const StaffFormOptions.empty(),
    this.roleFilter,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.fieldErrors = const {},
  });

  final AkunStatus status;
  final List<ManagedUser> users;
  final StaffFormOptions options;

  /// Null berarti seluruh peran staf ditampilkan.
  final String? roleFilter;

  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  /// Pesan error per field (dipetakan dari `field_errors` backend).
  final Map<String, String> fieldErrors;

  bool get isLoading =>
      status == AkunStatus.loading || status == AkunStatus.initial;

  bool get isEmpty => status == AkunStatus.ready && users.isEmpty;

  int get activeCount => users.where((user) => user.isActive).length;

  /// Formulir tidak dapat dibuka tanpa daftar peran & program studi: menebak
  /// nilainya di klien berarti mengirim akun ke prodi yang belum tentu ada.
  bool get canOpenForm => !options.isEmpty;

  List<StudyProgram> get studyPrograms => options.studyPrograms;

  List<RoleOption> get roles => options.roles;

  KelolaAkunState copyWith({
    AkunStatus? status,
    List<ManagedUser>? users,
    StaffFormOptions? options,
    String? roleFilter,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    Map<String, String>? fieldErrors,
    bool clearMessages = false,
    bool clearRoleFilter = false,
  }) {
    return KelolaAkunState(
      status: status ?? this.status,
      users: users ?? this.users,
      options: options ?? this.options,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      fieldErrors: clearMessages ? const {} : (fieldErrors ?? this.fieldErrors),
    );
  }

  @override
  List<Object?> get props => [
        status,
        users,
        options.roles,
        options.studyPrograms,
        roleFilter,
        isSaving,
        errorMessage,
        successMessage,
        fieldErrors,
      ];
}
