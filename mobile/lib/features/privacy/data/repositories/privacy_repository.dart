import '../../../../core/network/dio_client.dart';
import '../../domain/entities/privacy_setting.dart';

/// Repository privasi (Full Online — tidak ada cache lokal).
///
/// Endpoint berada di bawah /students/me sehingga backend selalu memakai
/// identitas dari token; klien tidak pernah mengirim user id.
class PrivacyRepository {
  const PrivacyRepository(this._client);

  final DioClient _client;

  static const _basePath = '/students/me/privacy-settings';

  Future<PrivacySetting> fetch() async {
    final result = await _client.get<PrivacySetting>(
      _basePath,
      parser: (data) => _parseSetting(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<List<PrivacyOption>> fetchOptions() async {
    final result = await _client.get<List<PrivacyOption>>(
      '$_basePath/options',
      parser: (data) => (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => PrivacyOption(
              level: ShareLevel.fromCode(json['value'] as String?),
              label: json['label'] as String? ?? '',
              description: json['description'] as String? ?? '',
            ),
          )
          .toList(),
    );
    return result.data;
  }

  Future<PrivacySetting> update(PrivacySetting setting) async {
    final result = await _client.put<PrivacySetting>(
      _basePath,
      body: {
        'share_level': setting.shareLevel.code,
        'allow_early_warning': setting.allowEarlyWarning,
        'allow_program_statistic': setting.allowProgramStatistic,
      },
      parser: (data) => _parseSetting(data as Map<String, dynamic>),
    );
    return result.data;
  }

  PrivacySetting _parseSetting(Map<String, dynamic> json) => PrivacySetting(
        shareLevel: ShareLevel.fromCode(json['share_level'] as String?),
        allowEarlyWarning: json['allow_early_warning'] as bool? ?? false,
        allowProgramStatistic: json['allow_program_statistic'] as bool? ?? false,
        effect: json['effect'] as String? ?? '',
        advisorCanSeeIndicator: json['advisor_can_see_indicator'] as bool? ?? false,
        advisorCanSeeTrend: json['advisor_can_see_trend'] as bool? ?? false,
        advisorCanGetAlert: json['advisor_can_get_alert'] as bool? ?? false,
      );
}
