import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../data/repositories/journal_repository.dart';
import '../../domain/entities/journal.dart';
import '../cubit/emotion_history_cubit.dart';
import '../widgets/mood_visuals.dart';

/// Menu "Riwayat Analisis Emosi" di tab Profil.
///
/// Yang ditampilkan adalah hasil analisis, bukan tulisan lengkapnya —
/// cuplikan disertakan hanya supaya pemiliknya mengenali catatan mana.
class RiwayatAnalisisPage extends StatelessWidget {
  const RiwayatAnalisisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EmotionHistoryCubit(context.read<JournalRepository>())..load(),
      child: const _RiwayatAnalisisView(),
    );
  }
}

class _RiwayatAnalisisView extends StatelessWidget {
  const _RiwayatAnalisisView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(title: const Text('Riwayat Analisis Emosi'), elevation: 0),
      body: BlocBuilder<EmotionHistoryCubit, EmotionHistoryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.midnight));
          }
          if (state.status == EmotionHistoryStatus.failure) {
            return _ErrorView(message: state.errorMessage);
          }
          if (state.isEmpty) {
            return _EmptyView(message: state.history.message);
          }

          final history = state.history;

          return RefreshIndicator(
            color: AppColors.midnight,
            backgroundColor: Colors.white,
            onRefresh: () => context.read<EmotionHistoryCubit>().refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _SummaryCard(history: history),
                if (history.distribution.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _DistributionCard(history: history),
                ],
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Setiap Hasil',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final item in history.items) _HistoryCard(item: item),
                const SizedBox(height: AppSpacing.md),
                _ModelNoteCard(modelVersion: history.modelVersion),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.history});

  final EmotionHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (history.dominantEmotion.isNotEmpty)
                CartoonMoodBlob(
                  mood: MoodVisuals.forEmotion(history.dominantEmotion),
                  size: 48,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.dominantEmotionText.isEmpty
                          ? '${history.totalAnalyzed} catatan dianalisis'
                          : 'Paling sering: ${history.dominantEmotionText}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${history.totalAnalyzed} hasil · ${history.negativePercent}% bernada negatif',
                      style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Server menyatakan datanya belum membentuk pola. Menyebutnya "tren"
          // pada titik ini akan melebih-lebihkan apa yang sebenarnya diketahui.
          if (!history.isSufficient && history.message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.creamAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                history.message,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.warmTextSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],

          if (history.crisisFlaggedCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.favorite_rounded, size: 16, color: AppColors.ewsIntervention),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${history.crisisFlaggedCount} catatan menyentuh hal berat. '
                    'Bantuan tersedia kapan saja lewat menu Butuh Bantuan Sekarang.',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ewsIntervention,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.history});

  final EmotionHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sebaran Emosi Terdeteksi',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final slice in history.distribution)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        slice.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.midnight,
                        ),
                      ),
                      Text(
                        '${slice.percentage.toStringAsFixed(0)}% · ${slice.count}x',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.midnight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: slice.fraction,
                      minHeight: 8,
                      backgroundColor: AppColors.creamAlt,
                      color: MoodVisuals.forEmotion(slice.emotion).color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final EmotionHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: item.isCrisisFlagged ? AppColors.ewsIntervention : AppColors.cartoonBorder,
          width: item.isCrisisFlagged ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CartoonMoodBlob(mood: MoodVisuals.forEmotion(item.emotionLabel), size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? item.emotionLabelText : item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                    Text(
                      _formatDate(item.journalDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                    ),
                  ],
                ),
              ),
              WavyBadge(text: '${item.confidencePercent}%', color: AppColors.lavenderBg),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MoodVisuals.forEmotion(item.emotionLabel).bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 18, color: AppColors.midnight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Terdeteksi: ${item.emotionLabelText}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.preview,
            style: const TextStyle(fontSize: 13, color: AppColors.midnight, height: 1.4),
          ),
          if (item.copingSuggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.spa_outlined, size: 16, color: AppColors.moodDisgust),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.copingSuggestions.first,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warmTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _ModelNoteCard extends StatelessWidget {
  const _ModelNoteCard({required this.modelVersion});

  final String modelVersion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.creamAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology_outlined, size: 18, color: AppColors.warmTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Label emosi dihasilkan analisis otomatis ($modelVersion) dan bisa keliru. '
              'Kamu yang paling tahu perasaanmu — hasil ini hanya bahan refleksi.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warmTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, size: 44, color: AppColors.warmTextMuted),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Belum ada hasil analisis',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.isEmpty
                  ? 'Tulis catatan di tab Jurnal lalu tekan Analisis Emosi.'
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.warmTextSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.ewsRisk),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ?? 'Gagal memuat riwayat analisis.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.warmTextSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.read<EmotionHistoryCubit>().load(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.midnight,
                side: const BorderSide(color: AppColors.midnight, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
