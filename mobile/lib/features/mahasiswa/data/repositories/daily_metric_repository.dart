import '../../../../core/network/dio_client.dart';
import '../../domain/entities/daily_metric.dart';

/// Repository ringkasan mood mingguan (Full Online — tidak ada cache lokal).
///
/// Endpoint berada di bawah /students/me sehingga backend selalu memakai
/// identitas dari token; klien tidak pernah mengirim user id.
class DailyMetricRepository {
  const DailyMetricRepository(this._client);

  final DioClient _client;

  static const _basePath = '/students/me/daily-metrics';

  Future<WeeklyMoodSummary> fetchWeeklySummary() async {
    final result = await _client.get<WeeklyMoodSummary>(
      '$_basePath/weekly-summary',
      parser: (data) => WeeklyMoodSummary.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<DailyMetric> saveDailyMetric({
    required int moodScore,
    int stressLevel = 2,
    double sleepHours = 7.0,
    String emotionLabel = '',
    String academicTrigger = '',
    String? metricDate,
  }) async {
    final payload = <String, dynamic>{
      'mood_score': moodScore,
      'stress_level': stressLevel,
      'sleep_hours': sleepHours,
      'emotion_label': emotionLabel,
      'academic_trigger': academicTrigger,
      if (metricDate != null && metricDate.isNotEmpty) 'metric_date': metricDate,
    };

    final result = await _client.post<DailyMetric>(
      _basePath,
      body: payload,
      parser: (data) => DailyMetric.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }
}

