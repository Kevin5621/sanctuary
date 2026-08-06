import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/features/mahasiswa/domain/entities/journal.dart';
import 'package:sanctuary/features/mahasiswa/presentation/cubit/emotion_history_cubit.dart';

import 'support/fake_repositories.dart';

EmotionHistory historyWith({required int total, required bool sufficient, int crisis = 0}) =>
    EmotionHistory(
      items: [
        for (var i = 0; i < total; i++)
          EmotionHistoryItem(
            journalId: 'j$i',
            title: 'Catatan $i',
            preview: 'Cuplikan $i',
            journalDate: DateTime(2026, 8, i + 1),
            analyzedAt: DateTime(2026, 8, i + 1, 20),
            emotionLabel: 'ANXIOUS',
            emotionLabelText: 'Cemas',
            emotionConfidence: 0.82,
            sentimentScore: -0.6,
            isCrisisFlagged: i < crisis,
            copingSuggestions: const ['Coba latihan napas.'],
          ),
      ],
      distribution: const [
        EmotionDistributionSlice(
          emotion: 'ANXIOUS',
          label: 'Cemas',
          count: 3,
          percentage: 100,
          isNegative: true,
        ),
      ],
      trend: const [],
      totalAnalyzed: total,
      crisisFlaggedCount: crisis,
      dominantEmotion: 'ANXIOUS',
      dominantEmotionText: 'Cemas',
      negativeRatio: 1,
      modelVersion: 'mock-lexicon-v1',
      isSufficient: sufficient,
      message: sufficient ? '' : 'Analisis masih sedikit.',
    );

void main() {
  test('memuat riwayat analisis', () async {
    final cubit = EmotionHistoryCubit(
      FakeJournalRepository(emotionHistory: historyWith(total: 5, sufficient: true)),
    );

    await cubit.load();

    expect(cubit.state.status, EmotionHistoryStatus.ready);
    expect(cubit.state.history.totalAnalyzed, 5);
    expect(cubit.state.history.dominantEmotionText, 'Cemas');
    expect(cubit.state.isEmpty, isFalse);
  });

  test('belum ada analisis ditandai isEmpty', () async {
    final cubit = EmotionHistoryCubit(FakeJournalRepository());

    await cubit.load();

    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.history.isSufficient, isFalse);
  });

  // Dua hasil belum membentuk pola; menyebutnya tren melebih-lebihkan apa yang
  // sebenarnya diketahui tentang seseorang.
  test('state belum cukup dibawa apa adanya dari server', () async {
    final cubit = EmotionHistoryCubit(
      FakeJournalRepository(emotionHistory: historyWith(total: 2, sufficient: false)),
    );

    await cubit.load();

    expect(cubit.state.history.isSufficient, isFalse);
    expect(cubit.state.history.message, isNotEmpty);
  });

  test('jumlah penanda krisis diteruskan ke layar', () async {
    final cubit = EmotionHistoryCubit(
      FakeJournalRepository(
        emotionHistory: historyWith(total: 4, sufficient: true, crisis: 2),
      ),
    );

    await cubit.load();

    expect(cubit.state.history.crisisFlaggedCount, 2);
  });

  test('rasio negatif dikonversi ke persen bulat', () async {
    final cubit = EmotionHistoryCubit(
      FakeJournalRepository(emotionHistory: historyWith(total: 3, sufficient: true)),
    );

    await cubit.load();

    expect(cubit.state.history.negativePercent, 100);
  });

  test('gagal memuat menghasilkan status failure', () async {
    final cubit = EmotionHistoryCubit(FakeJournalRepository(failList: true));

    await cubit.load();

    expect(cubit.state.status, EmotionHistoryStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });
}
