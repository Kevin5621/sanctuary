import 'package:equatable/equatable.dart';

/// Layanan bantuan darurat.
///
/// Dibaca semua peran, dikelola Admin (A-BAN-01..04). Ditempatkan sebagai
/// fitur lintas-peran — bukan di dalam `features/admin` — karena mahasiswa,
/// dosen, dan kaprodi juga membacanya, mengikuti pola `features/privacy/`.
class EmergencyContact extends Equatable {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.serviceType,
    required this.serviceTypeLabel,
    this.description = '',
    this.is24Hours = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.needsVerification = false,
    this.updatedAt = '',
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        serviceType: json['service_type'] as String? ?? 'OTHER',
        serviceTypeLabel: json['service_type_label'] as String? ?? 'Lainnya',
        description: json['description'] as String? ?? '',
        is24Hours: json['is_24_hours'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: json['sort_order'] as int? ?? 0,
        // A-BAN-04 — server yang menentukan, klien tidak mem-parsing teks
        // penanda sendiri agar aturannya hanya ada di satu tempat.
        needsVerification: json['needs_verification'] as bool? ?? false,
        updatedAt: json['updated_at'] as String? ?? '',
      );

  final String id;
  final String name;
  final String phone;
  final String serviceType;
  final String serviceTypeLabel;
  final String description;
  final bool is24Hours;
  final bool isActive;
  final int sortOrder;
  final bool needsVerification;
  final String updatedAt;

  /// Nomor siap dial — spasi, tanda kurung, dan strip dibuang.
  String get dialNumber => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  Map<String, dynamic> toRequestBody() => {
        'name': name,
        'phone': phone,
        'description': description,
        'service_type': serviceType,
        'is_24_hours': is24Hours,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? serviceType,
    String? serviceTypeLabel,
    String? description,
    bool? is24Hours,
    bool? isActive,
    int? sortOrder,
    bool? needsVerification,
    String? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      serviceType: serviceType ?? this.serviceType,
      serviceTypeLabel: serviceTypeLabel ?? this.serviceTypeLabel,
      description: description ?? this.description,
      is24Hours: is24Hours ?? this.is24Hours,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      needsVerification: needsVerification ?? this.needsVerification,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        serviceType,
        serviceTypeLabel,
        description,
        is24Hours,
        isActive,
        sortOrder,
        needsVerification,
        updatedAt,
      ];
}

/// Satu pilihan pada dropdown "jenis layanan" form Admin.
/// Daftarnya berasal dari server (`GET /support/service-types`) supaya nilai
/// enum tidak ditulis ulang di klien dan berisiko menyimpang.
class ServiceTypeOption extends Equatable {
  const ServiceTypeOption({required this.value, required this.label});

  factory ServiceTypeOption.fromJson(Map<String, dynamic> json) =>
      ServiceTypeOption(
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  final String value;
  final String label;

  @override
  List<Object?> get props => [value, label];
}
