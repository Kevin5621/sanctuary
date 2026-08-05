part of 'emergency_contact_cubit.dart';

enum ContactStatus { initial, loading, ready, failure }

class EmergencyContactState extends Equatable {
  const EmergencyContactState({
    this.status = ContactStatus.initial,
    this.contacts = const [],
    this.serviceTypes = const [],
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final ContactStatus status;
  final List<EmergencyContact> contacts;
  final List<ServiceTypeOption> serviceTypes;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading =>
      status == ContactStatus.loading || status == ContactStatus.initial;

  /// A-BAN-03 — daftar kosong.
  ///
  /// Layar mahasiswa/dosen/kaprodi wajib menampilkan "nomor layanan belum
  /// diatur" pada kondisi ini, dan TIDAK BOLEH menampilkan nomor bawaan apa pun
  /// sebagai pengganti: nomor tebakan yang sudah mati lebih berbahaya daripada
  /// mengaku belum ada.
  bool get isEmpty => status == ContactStatus.ready && contacts.isEmpty;

  /// Jumlah nomor yang masih bertanda belum diverifikasi (A-BAN-04).
  int get unverifiedCount => contacts.where((c) => c.needsVerification).length;

  int get activeCount => contacts.where((c) => c.isActive).length;

  /// Hanya yang aktif — dipakai layar baca peran non-Admin.
  ///
  /// Untuk peran non-Admin server memang sudah menyaringnya, jadi getter ini
  /// bersifat idempoten di sana. Nilainya ada agar pratinjau di layar Admin
  /// dapat menunjukkan apa yang benar-benar dilihat mahasiswa.
  List<EmergencyContact> get activeContacts =>
      contacts.where((c) => c.isActive).toList();

  EmergencyContactState copyWith({
    ContactStatus? status,
    List<EmergencyContact>? contacts,
    List<ServiceTypeOption>? serviceTypes,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return EmergencyContactState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        contacts,
        serviceTypes,
        isSaving,
        errorMessage,
        successMessage,
      ];
}
