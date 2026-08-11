import '../../../../core/network/dio_client.dart';
import '../../domain/entities/daily_metric.dart';

/// Repository check-in mood dan riwayatnya (Full Online — tanpa cache lokal).
///
/// Endpoint berada di bawah /students/me sehingga backend selalu memakai
/// identitas dari token; klien tidak pernah mengirim user id.
class DailyMetricRepository {
  const DailyMetricRepository(this._client);

  final DioClient _client;

  static const _basePath = '/students/me/daily-metrics';

  /// Pilihan check-in (skala, emosi, pemicu, batas backdate) — dimuat sekali
  /// lalu dipakai form. Klien tidak menyimpan daftarnya sendiri.
  Future<CheckinOptions> fetchOptions() async {
    final result = await _client.get<CheckinOptions>(
      '$_basePath/options',
      parser: (data) => CheckinOptions.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<WeeklyMoodSummary> fetchWeeklySummary() async {
    final result = await _client.get<WeeklyMoodSummary>(
      '$_basePath/weekly-summary',
      parser: (data) => WeeklyMoodSummary.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  /// [month] berformat YYYY-MM; kosong berarti bulan berjalan.
  Future<MonthlyMood> fetchMonthly({String month = ''}) async {
    final result = await _client.get<MonthlyMood>(
      '$_basePath/monthly',
      query: month.isEmpty ? null : {'month': month},
      parser: (data) => MonthlyMood.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<MoodStats> fetchStats({int periodDays = 30}) async {
    final result = await _client.get<MoodStats>(
      '$_basePath/stats',
      query: {'period_days': periodDays},
      parser: (data) => MoodStats.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  /// Menyimpan check-in. Server melakukan upsert per tanggal, sehingga
  /// mengirim ulang tanggal yang sama berarti memperbaiki, bukan menduplikasi.
  Future<DailyMetric> saveDailyMetric({
    required int moodScore,
    required int stressLevel,
    required double sleepHours,
    String academicTrigger = '',
    String? metricDate,
  }) async {
    final payload = <String, dynamic>{
      'mood_score': moodScore,
      'stress_level': stressLevel,
      'sleep_hours': sleepHours,
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
