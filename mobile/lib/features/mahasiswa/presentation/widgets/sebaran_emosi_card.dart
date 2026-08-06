import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clay_container.dart';
import '../../domain/entities/journal.dart';
import '../cubit/sebaran_emosi_cubit.dart';

/// Kartu "Sebaran Emosi" (M-MOOD-04) untuk tab Mood.
///
/// Bentuk grafik: batang horizontal, bukan donat. Alasannya diukur, bukan
/// selera — palet pastel Sanctuary tidak lolos ambang keterbedaan buta warna
/// (NEUTRAL vs TIRED hanya berjarak ΔE 8.5 bahkan untuk penglihatan normal).
/// Donat memaksa mata mencocokkan irisan dengan legenda lewat WARNA, dan itu
/// persis yang gagal pada palet ini. Batang berlabel langsung membuat warna
/// menjadi penguat, bukan satu-satunya penanda identitas.
class SebaranEmosiCard extends StatelessWidget {
  const SebaranEmosiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SebaranEmosiCubit, SebaranEmosiState>(
      builder: (context, state) {
        return ClayContainer(
          color: AppColors.cardBg,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(state: state),
              const SizedBox(height: AppSpacing.md),
              if (state.isLoading)
                const _LoadingState()
              else if (state.status == SebaranEmosiStatus.failure)
                _FailureState(
                  message: state.errorMessage ?? 'Gagal memuat sebaran emosi.',
                  onRetry: context.read<SebaranEmosiCubit>().refresh,
                )
              else if (state.isEmpty)
                _EmptyState(message: state.distribution.message)
              else
                _DistributionChart(distribution: state.distribution),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final SebaranEmosiState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sebaran Emosi',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: 2),
              // Sumber data disebut eksplisit (D-3): angka ini berasal dari
              // jurnal yang dianalisis, BUKAN dari check-in mood harian.
              Text(
                'Dari ${state.distribution.totalAnalyzed} jurnal yang dianalisis',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.warmTextSecondary,
                ),
              ),
            ],
          ),
        ),
        _RangeSelector(state: state),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.state});

  final SebaranEmosiState state;

  static const _options = <int, String>{7: '7h', 30: '30h', 90: '90h'};

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SebaranEmosiCubit>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _options.entries.map((entry) {
        final isActive = state.rangeDays == entry.key;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: ClayContainer(
            type: isActive ? ClayType.concave : ClayType.flat,
            color: isActive ? AppColors.lavenderBg : AppColors.creamAlt,
            borderRadius: AppSpacing.radiusPill,
            depth: 6,
            spread: 3,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            onTap: state.isLoading ? null : () => cubit.changeRange(entry.key),
            child: Text(
              entry.value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? AppColors.midnight : AppColors.warmTextSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DistributionChart extends StatelessWidget {
  const _DistributionChart({required this.distribution});

  final EmotionDistribution distribution;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...distribution.distribution.map(
          (share) => _EmotionBar(share: share),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1, color: AppColors.cartoonBorder),
        const SizedBox(height: AppSpacing.sm),
        _Footer(distribution: distribution),
      ],
    );
  }
}

/// Satu batang: label teks + jumlah + persentase selalu terlihat, sehingga
/// identitas tidak pernah bergantung pada warna saja.
class _EmotionBar extends StatelessWidget {
  const _EmotionBar({required this.share});

  final EmotionShare share;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.emotion(share.emotion);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cartoonBorder),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  share.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    // Teks memakai token tinta, bukan warna seri.
                    color: AppColors.midnight,
                  ),
                ),
              ),
              Text(
                '${share.count} · ${_formatPercent(share.percentage)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warmTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final fraction = (share.percentage / 100).clamp(0.0, 1.0);
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.creamAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                    height: 10,
                    // Batang selalu punya lebar minimum agar kategori bernilai
                    // kecil tetap terlihat, bukan hilang jadi garis nol.
                    width: (constraints.maxWidth * fraction).clamp(6.0, constraints.maxWidth),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatPercent(double value) {
    if (value >= 10 || value == value.roundToDouble()) {
      return '${value.round()}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.distribution});

  final EmotionDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final negativePercent = (distribution.negativeRatio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (distribution.dominantEmotionText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Emosi paling sering: ${distribution.dominantEmotionText} · '
              '$negativePercent% catatan bernada negatif',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warmTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        // Transparansi model: angka di atas adalah keluaran model versi ini,
        // dengan segala keterbatasannya.
        Text(
          'Model: ${distribution.modelVersion}',
          style: const TextStyle(fontSize: 10.5, color: AppColors.warmTextMuted),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Empty state jujur: menyebut sebabnya dan langkah berikutnya, bukan grafik
/// kosong yang terbaca seolah "emosimu nol".
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded,
              size: 22, color: AppColors.warmTextMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message.isNotEmpty
                  ? message
                  : 'Belum ada jurnal yang dianalisis pada rentang ini. '
                      'Tulis catatan lalu tekan Analisis Emosi.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 20, color: AppColors.warmTextMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
