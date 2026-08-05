import '../../../../core/network/dio_client.dart';
import '../../domain/entities/emergency_contact.dart';

/// Repository layanan bantuan darurat (Full Online — tanpa cache lokal).
///
/// Baca: seluruh peran terautentikasi. Tulis: hanya Admin — ditegakkan backend
/// lewat RBAC, bukan dengan menyembunyikan tombol di klien.
///
/// A-BAN-02: penyaringan `is_active` juga dilakukan SERVER berdasarkan peran
/// pemanggil. Klien tidak perlu (dan tidak boleh) menyaringnya sendiri —
/// peran non-Admin memang tidak pernah menerima baris nonaktif.
class EmergencyContactRepository {
  const EmergencyContactRepository(this._client);

  final DioClient _client;

  static const _basePath = '/support/emergency-contacts';

  Future<List<EmergencyContact>> fetchAll({int page = 1}) async {
    final result = await _client.get<List<EmergencyContact>>(
      _basePath,
      query: {'page': page, 'sort_by': 'sort_order'},
      parser: (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EmergencyContact.fromJson)
          .toList(),
    );
    return result.data;
  }

  /// Pilihan jenis layanan untuk form Admin (A-BAN-01).
  Future<List<ServiceTypeOption>> fetchServiceTypes() async {
    final result = await _client.get<List<ServiceTypeOption>>(
      '/support/service-types',
      parser: (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ServiceTypeOption.fromJson)
          .toList(),
    );
    return result.data;
  }

  Future<EmergencyContact> create(EmergencyContact contact) async {
    final result = await _client.post<EmergencyContact>(
      _basePath,
      body: contact.toRequestBody(),
      parser: (data) =>
          EmergencyContact.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }

  Future<EmergencyContact> update(EmergencyContact contact) async {
    final result = await _client.put<EmergencyContact>(
      '$_basePath/${contact.id}',
      body: contact.toRequestBody(),
      parser: (data) =>
          EmergencyContact.fromJson(data as Map<String, dynamic>? ?? const {}),
    );
    return result.data;
  }

  Future<void> delete(String id) async {
    await _client.delete<void>('$_basePath/$id', parser: (_) {});
  }
}
