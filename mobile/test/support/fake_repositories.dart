import 'package:sanctuary/core/network/api_exception.dart';
import 'package:sanctuary/core/network/dio_client.dart';
import 'package:sanctuary/core/network/token_storage.dart';
import 'package:sanctuary/features/mahasiswa/data/repositories/contact_request_repository.dart';
import 'package:sanctuary/features/mahasiswa/data/repositories/daily_metric_repository.dart';
import 'package:sanctuary/features/mahasiswa/data/repositories/dass_repository.dart';
import 'package:sanctuary/features/mahasiswa/data/repositories/journal_repository.dart';
import 'package:sanctuary/features/mahasiswa/domain/entities/advisor.dart';
import 'package:sanctuary/features/mahasiswa/domain/entities/contact_request.dart';
import 'package:sanctuary/features/mahasiswa/domain/entities/daily_metric.dart';
import 'package:sanctuary/features/mahasiswa/domain/entities/dass21.dart';
import 'package:sanctuary/features/mahasiswa/domain/entities/journal.dart';

/// Repository palsu untuk pengujian cubit.
///
/// Tidak ada yang menyentuh jaringan. Repository asli berupa kelas konkret,
/// jadi setiap fake meng-override method-nya sambil mewarisi konstruktor —
/// pola yang sama dipakai pengujian privasi yang sudah ada.

DioClient dummyClient() => DioClient(
      tokenStorage: TokenStorage(),
      onSessionExpired: () async {},
    );

const networkError = ApiException(
  code: ApiErrorCode.networkError,
  message: 'Tidak dapat terhubung ke server.',
);

// ------------------------------------------------------------------

class FakeDailyMetricRepository extends DailyMetricRepository {
  FakeDailyMetricRepository({
    WeeklyMoodSummary? summary,
    MonthlyMood? monthly,
    MoodStats? stats,
    CheckinOptions? options,
    this.failWeekly = false,
    this.failOptions = false,
    this.failSave = false,
  })  : summary = summary ?? emptyWeekly(),
        monthly = monthly ?? const MonthlyMood.empty(),
        stats = stats ?? const MoodStats.empty(),
        options = options ?? defaultOptions(),
        super(dummyClient());

  WeeklyMoodSummary summary;
  MonthlyMood monthly;
  MoodStats stats;
  CheckinOptions options;

  bool failWeekly;
  bool failOptions;
  bool failSave;

  /// Argumen check-in terakhir — dipakai memastikan klien tidak mengarang nilai.
  Map<String, dynamic>? lastSaved;
  String? lastRequestedMonth;
  int? lastRequestedPeriod;

  static WeeklyMoodSummary emptyWeekly() => WeeklyMoodSummary(
        weekStart: DateTime(2026, 8, 3),
        weekEnd: DateTime(2026, 8, 9),
        today: null,
        days: const [],
      );

  static CheckinOptions defaultOptions() => const CheckinOptions(
        moodScale: [
          ScaleOption(value: 1, label: 'Sangat buruk'),
          ScaleOption(value: 3, label: 'Biasa saja'),
          ScaleOption(value: 5, label: 'Sangat baik'),
        ],
        stressScale: [
          ScaleOption(value: 1, label: 'Sangat santai'),
          ScaleOption(value: 5, label: 'Sangat tertekan'),
        ],
        academicTriggers: [],
        maxBackdateDays: 30,
      );

  @override
  Future<CheckinOptions> fetchOptions() async {
    if (failOptions) throw networkError;
    return options;
  }

  @override
  Future<WeeklyMoodSummary> fetchWeeklySummary() async {
    if (failWeekly) throw networkError;
    return summary;
  }

  @override
  Future<MonthlyMood> fetchMonthly({String month = ''}) async {
    lastRequestedMonth = month;
    return monthly;
  }

  @override
  Future<MoodStats> fetchStats({int periodDays = 30}) async {
    lastRequestedPeriod = periodDays;
    return stats;
  }

  @override
  Future<DailyMetric> saveDailyMetric({
    required int moodScore,
    required int stressLevel,
    required double sleepHours,
    String academicTrigger = '',
    String? metricDate,
  }) async {
    if (failSave) throw networkError;

    lastSaved = {
      'mood_score': moodScore,
      'stress_level': stressLevel,
      'sleep_hours': sleepHours,
      'academic_trigger': academicTrigger,
      'metric_date': metricDate,
    };

    return DailyMetric(
      date: DateTime.now(),
      moodScore: moodScore,
      stressLevel: stressLevel,
      sleepHours: sleepHours,
      academicTrigger: academicTrigger,
    );
  }
}

// ------------------------------------------------------------------

class FakeContactRequestRepository extends ContactRequestRepository {
  FakeContactRequestRepository({ContactRequestState? state})
      : state = state ?? withAdvisor(),
        super(dummyClient());

  ContactRequestState state;
  bool cancelled = false;
  String? lastNote;

  static ContactRequestState withAdvisor({
    bool hasOpenRequest = false,
    int advisorCount = 1,
  }) =>
      ContactRequestState(
        hasOpenRequest: hasOpenRequest,
        request: hasOpenRequest
            ? ContactRequest(
                id: 'req-1',
                status: 'OPEN',
                note: '',
                createdAt: DateTime(2026, 8, 6),
                isOpen: true,
              )
            : null,
        advisors: [
          for (var i = 0; i < advisorCount; i++)
            Advisor(id: 'advisor-$i', fullName: 'Pembimbing ${i + 1}'),
        ],
        canRequest: !hasOpenRequest,
        explanation: 'Pembimbingmu hanya melihat namamu dan waktu permintaan.',
      );

  @override
  Future<ContactRequestState> fetchState() async => state;

  @override
  Future<ContactRequest> create({String note = ''}) async {
    lastNote = note;
    state = withAdvisor(hasOpenRequest: true);
    return state.request!;
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
    state = withAdvisor();
  }
}

// ------------------------------------------------------------------

class FakeJournalRepository extends JournalRepository {
  FakeJournalRepository({
    List<JournalListItem>? entries,
    EmotionHistory? emotionHistory,
    EmotionDistribution? emotionDistribution,
    this.hasNextPage = false,
    this.failList = false,
  })  : entries = entries ?? const [],
        emotionHistory = emotionHistory ?? const EmotionHistory.empty(),
        emotionDistribution = emotionDistribution ?? const EmotionDistribution.initial(),
        super(dummyClient());

  List<JournalListItem> entries;
  EmotionHistory emotionHistory;
  EmotionDistribution emotionDistribution;
  bool hasNextPage;
  bool failList;

  String? lastContent;
  String? lastJournalDate;
  bool? lastAnalyzeNow;
  String? analyzedId;
  String? deletedId;
  JournalAnalysis? nextAnalysis;

  static JournalListItem item(String id, {bool analyzed = true, bool crisis = false}) =>
      JournalListItem(
        id: id,
        title: 'Catatan $id',
        preview: 'Cuplikan catatan $id',
        journalDate: DateTime(2026, 8, 5),
        emotionLabel: analyzed ? 'ANXIOUS' : '',
        emotionLabelText: analyzed ? 'Cemas' : '',
        isCrisisFlagged: crisis,
        analyzedAt: analyzed ? DateTime(2026, 8, 5, 20) : null,
      );

  static JournalAnalysis analysis({bool crisis = false}) => JournalAnalysis(
        journalId: 'j1',
        emotionLabel: crisis ? 'SAD' : 'ANXIOUS',
        emotionLabelText: crisis ? 'Sedih' : 'Cemas',
        emotionConfidence: 0.82,
        sentimentScore: crisis ? -0.95 : -0.6,
        isCrisisFlagged: crisis,
        copingSuggestions: const ['Coba latihan napas 4-7-8.'],
        crisisMessage: crisis ? 'Kamu tidak harus menghadapinya sendirian.' : '',
        modelVersion: 'mock-lexicon-v1',
      );

  @override
  Future<JournalPage> fetchPage({int page = 1}) async {
    if (failList) throw networkError;
    return JournalPage(items: entries, hasNextPage: hasNextPage, page: page);
  }

  @override
  Future<JournalCreationResult> create({
    required String content,
    String title = '',
    String? journalDate,
    bool analyzeNow = true,
  }) async {
    lastContent = content;
    lastJournalDate = journalDate;
    lastAnalyzeNow = analyzeNow;

    return JournalCreationResult(
      journal: Journal(
        id: 'j-new',
        title: title,
        content: content,
        journalDate: DateTime(2026, 8, 6),
        emotionLabel: analyzeNow ? 'ANXIOUS' : '',
        isCrisisFlagged: false,
        analyzedAt: analyzeNow ? DateTime(2026, 8, 6, 20) : null,
      ),
      analysis: analyzeNow ? (nextAnalysis ?? analysis()) : null,
    );
  }

  @override
  Future<JournalAnalysis> analyze(String id) async {
    analyzedId = id;
    return nextAnalysis ?? analysis();
  }

  @override
  Future<void> delete(String id) async {
    deletedId = id;
    entries = entries.where((entry) => entry.id != id).toList();
  }

  @override
  Future<EmotionHistory> fetchEmotionHistory() async {
    if (failList) throw networkError;
    return emotionHistory;
  }

  @override
  Future<EmotionDistribution> fetchEmotionDistribution({int rangeDays = 30}) async {
    if (failList) throw networkError;
    return emotionDistribution;
  }
}

// ------------------------------------------------------------------

class FakeDassRepository extends DassRepository {
  FakeDassRepository({
    DassQuestionnaire? questionnaire,
    DassHistory? history,
  })  : questionnaire = questionnaire ?? sampleQuestionnaire(),
        history = history ?? const DassHistory.empty(),
        super(dummyClient());

  DassQuestionnaire questionnaire;
  DassHistory history;
  List<int>? submittedAnswers;

  /// Kuesioner ringkas (3 soal) — cukup untuk menguji aturan kelengkapan
  /// tanpa menyalin seluruh katalog milik server.
  static DassQuestionnaire sampleQuestionnaire() => const DassQuestionnaire(
        version: 'dass21-id-v1',
        instruction: 'Pilih yang paling menggambarkan keadaanmu seminggu terakhir.',
        disclaimer: 'Hasil ini skrining awal, bukan diagnosis.',
        questions: [
          DassQuestion(number: 1, text: 'Sulit menenangkan diri', subscale: 'STRESS', subscaleLabel: 'Stres'),
          DassQuestion(number: 2, text: 'Mulut kering', subscale: 'ANXIETY', subscaleLabel: 'Kecemasan'),
          DassQuestion(number: 3, text: 'Tidak ada perasaan positif', subscale: 'DEPRESSION', subscaleLabel: 'Depresi'),
        ],
        options: [
          DassAnswerOption(value: 0, label: 'Tidak pernah'),
          DassAnswerOption(value: 3, label: 'Hampir selalu'),
        ],
      );

  static DassResult sampleResult({bool severe = false}) => DassResult(
        id: 'dass-1',
        takenAt: DateTime(2026, 8, 6, 10),
        takenDate: '2026-08-06',
        depression: DassSubscaleResult(
          subscale: 'DEPRESSION',
          label: 'Depresi',
          score: severe ? 24 : 4,
          maxScore: 42,
          severity: severe ? 'SEVERE' : 'NORMAL',
          severityLabel: severe ? 'Parah' : 'Normal',
          isSevere: severe,
        ),
        anxiety: const DassSubscaleResult(
          subscale: 'ANXIETY',
          label: 'Kecemasan',
          score: 4,
          maxScore: 42,
          severity: 'NORMAL',
          severityLabel: 'Normal',
          isSevere: false,
        ),
        stress: const DassSubscaleResult(
          subscale: 'STRESS',
          label: 'Stres',
          score: 6,
          maxScore: 42,
          severity: 'NORMAL',
          severityLabel: 'Normal',
          isSevere: false,
        ),
        totalScore: severe ? 34 : 14,
        hasSevere: severe,
        disclaimer: 'Hasil ini skrining awal, bukan diagnosis.',
        copingSuggestions: const ['Hubungi Unit Konseling kampus.'],
      );

  @override
  Future<DassQuestionnaire> fetchQuestionnaire() async => questionnaire;

  @override
  Future<DassHistory> fetchHistory() async => history;

  @override
  Future<DassResult> submit(List<int> answers) async {
    submittedAnswers = answers;
    final result = sampleResult();
    history = DassHistory(
      latest: result,
      results: [result],
      trend: const [],
      totalDelta: null,
      changeLabel: 'Belum ada pembanding',
      count: 1,
    );
    return result;
  }
}
