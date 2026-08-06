import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../domain/entities/group_condition.dart';
import '../cubit/kondisi_cubit.dart';

/// Tab Kondisi — agregat kelompok bimbingan (L-KON-01..04).
class DosenKondisiTab extends StatelessWidget {
  const DosenKondisiTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KondisiCubit(context.read<MentorRepository>())..load(),
      child: const _KondisiView(),
    );
  }
}

class _KondisiView extends StatelessWidget {
  const _KondisiView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<KondisiCubit, KondisiState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<KondisiCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SectionHeader(
                    title: 'Kondisi Kelompok',
                    subtitle: 'Gambaran agregat seluruh mahasiswa bimbingan',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _PeriodSelector(
                    selected: state.periodDays,
                    enabled: !state.isLoading,
                    onSelect: (days) =>
                        context.read<KondisiCubit>().selectPeriod(days),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.isLoading)
                    const LoadingState(label: 'Memuat agregat kelompok…')
                  else if (state.status == KondisiStatus.failure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context.read<KondisiCubit>().load(),
                    )
                  else if (state.isInsufficient)
                    InsufficientDataCard(
                      minimumGroupSize: state.condition.minimumGroupSize,
                      context: 'kelompok bimbingan Anda',
                    )
                  else
                    _SufficientContent(condition: state.condition),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onSelect,
    this.enabled = true,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.creamAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Row(
        children: [
          for (final days in KondisiCubit.allowedPeriods)
            Expanded(
              child: GestureDetector(
                onTap: enabled ? () => onSelect(days) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: days == selected ? AppColors.midnight : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '$days hari',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: days == selected
                          ? Colors.white
                          : AppColors.warmTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SufficientContent extends StatelessWidget {
  const _SufficientContent({required this.condition});

  final GroupCondition condition;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Privacy Note Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.lavenderBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.lavenderDark, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.lavenderDark, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Agregat ${condition.groupSize} mahasiswa yang membagikan indikator (K-anonymity aktif).',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Responsive Metrics Grid using LayoutBuilder
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobileNarrow = constraints.maxWidth < 360;

            final tileMood = _AggregateTile(
              label: 'Rata-rata Mood',
              value: condition.avgMood,
              unit: '/ 5',
              color: AppColors.moodHappinessBg,
              icon: Icons.sentiment_satisfied_alt_rounded,
            );

            final tileStress = _AggregateTile(
              label: 'Rata-rata Stres',
              value: condition.avgStress,
              unit: '/ 5',
              color: AppColors.moodAngerBg,
              icon: Icons.bolt_rounded,
            );

            final tileSleep = _AggregateTile(
              label: 'Rata-rata Tidur',
              value: condition.avgSleepHours,
              unit: 'jam',
              color: AppColors.moodSadnessBg,
              icon: Icons.bedtime_outlined,
            );

            if (isMobileNarrow) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: tileMood),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: tileStress),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  tileSleep,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: tileMood),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: tileStress),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: tileSleep),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        const Text(
          'Sebaran Tingkat Perhatian',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.midnight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (condition.hasEwsDistribution)
          _EwsDistributionCard(condition: condition)
        else
          InsufficientDataCard(
            minimumGroupSize: condition.minimumGroupSize,
            context: 'mahasiswa yang mengizinkan peringatan dini',
          ),

        const SizedBox(height: AppSpacing.lg),

        const Text(
          'Sebaran Emosi Kelompok',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.midnight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (condition.hasEmotionDistribution)
          _EmotionDistributionCard(shares: condition.emotionDistribution)
        else
          const EmptyStateCard(
            icon: Icons.donut_large_outlined,
            title: 'Belum ada hasil analisis emosi',
            description:
                'Belum ada catatan emosi pada periode ini untuk kelompok Anda.',
          ),
      ],
    );
  }
}

class _AggregateTile extends StatelessWidget {
  const _AggregateTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final double? value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.midnight),
          const SizedBox(height: 4),
          Text(
            value == null ? '—' : value!.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.midnight,
            ),
          ),
          Text(
            value == null ? 'tidak tersedia' : unit,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.warmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EwsDistributionCard extends StatelessWidget {
  const _EwsDistributionCard({required this.condition});

  final GroupCondition condition;

  @override
  Widget build(BuildContext context) {
    final total = condition.ewsTotal;

    return StateCard(
      child: Column(
        children: [
          for (final entry in condition.orderedEwsDistribution)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: EwsLevelBadge(level: entry.key, dense: true),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : entry.value / total,
                        minHeight: 8,
                        backgroundColor: AppColors.creamAlt,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.ewsLevel(entry.key),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: AppColors.midnight,
                      ),
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

class _EmotionDistributionCard extends StatelessWidget {
  const _EmotionDistributionCard({required this.shares});

  final List<EmotionShare> shares;

  static const _emotionColor = {
    'JOY': AppColors.moodHappiness,
    'CALM': AppColors.moodDisgust,
    'NEUTRAL': AppColors.warmTextMuted,
    'SAD': AppColors.moodSadness,
    'ANXIOUS': AppColors.moodFear,
    'ANGRY': AppColors.moodAnger,
    'TIRED': AppColors.lavender,
  };

  @override
  Widget build(BuildContext context) {
    return StateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (final share in shares)
                    Expanded(
                      flex: (share.percentage * 100).round().clamp(1, 1000000),
                      child: Container(
                        color: _emotionColor[share.emotionLabel] ??
                            AppColors.lavender,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 8,
            children: [
              for (final share in shares)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _emotionColor[share.emotionLabel] ??
                            AppColors.lavender,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${share.displayLabel} ${share.percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midnight,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
