import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/program_repository.dart';
import '../../domain/entities/program_dashboard.dart';
import '../cubit/kaprodi_cubit.dart';

/// Tab Laporan (K-LAP-01) — ringkasan per angkatan.
///
/// Angkatan dengan anggota di bawah ambang tetap muncul di daftar (agar kaprodi
/// tahu angkatan itu ada) tetapi tanpa satu angka pun — termasuk tanpa jumlah
/// mahasiswanya.
class KaprodiLaporanTab extends StatelessWidget {
  const KaprodiLaporanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LaporanCubit(context.read<ProgramRepository>())..load(),
      child: const _LaporanView(),
    );
  }
}

class _LaporanView extends StatelessWidget {
  const _LaporanView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<LaporanCubit, LaporanState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<LaporanCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SectionHeader(
                    title: 'Laporan Angkatan',
                    subtitle: 'Evaluasi kondisi per angkatan mahasiswa',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _PeriodSelector(
                    selected: state.periodDays,
                    enabled: !state.status.isLoading,
                    onSelect: (days) =>
                        context.read<LaporanCubit>().selectPeriod(days),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.status.isLoading)
                    const LoadingState(label: 'Menyusun laporan angkatan…')
                  else if (state.status.isFailure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context.read<LaporanCubit>().load(),
                    )
                  else if (state.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.assessment_outlined,
                      title: 'Belum ada angkatan terdaftar',
                      description:
                          'Belum ada mahasiswa dengan tahun angkatan pada prodi ini.',
                    )
                  else
                    for (final report in state.reports)
                      _CohortCard(report: report),

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
          for (final days in LaporanCubit.allowedPeriods)
            Expanded(
              child: GestureDetector(
                onTap: enabled ? () => onSelect(days) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        days == selected ? AppColors.midnight : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '$days hari',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

class _CohortCard extends StatelessWidget {
  const _CohortCard({required this.report});

  final CohortReport report;

  @override
  Widget build(BuildContext context) {
    // Angkatan di bawah ambang: judulnya tetap tampil, isinya diganti kartu
    // "Data belum cukup" — tanpa jumlah anggota (I-4).
    if (!report.isSufficient) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CohortTitle(year: report.cohortYear, isSufficient: false),
            const SizedBox(height: AppSpacing.sm),
            InsufficientDataCard(
              minimumGroupSize: report.minimumGroupSize,
              context: 'angkatan ${report.cohortYear}',
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CohortTitle(year: report.cohortYear, isSufficient: true),
          const SizedBox(height: AppSpacing.sm),
          StateCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CohortMetric(
                        label: 'Mood',
                        value: report.avgMood,
                        unit: '/ 5',
                        color: AppColors.moodHappinessBg,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _CohortMetric(
                        label: 'Stres',
                        value: report.avgStress,
                        unit: '/ 5',
                        color: AppColors.moodAngerBg,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _CohortMetric(
                        label: 'Tidur',
                        value: report.avgSleepHours,
                        unit: 'jam',
                        color: AppColors.moodSadnessBg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.groups_outlined,
                        size: 16, color: AppColors.warmTextSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${report.groupSize} peserta statistik'
                      '${report.activeStudents != null ? ' · ${report.activeStudents} aktif 7 hari terakhir' : ''}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CohortTitle extends StatelessWidget {
  const _CohortTitle({required this.year, required this.isSufficient});

  final int year;
  final bool isSufficient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Angkatan $year',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.midnight,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (!isSufficient)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.creamAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: AppColors.warmTextMuted, width: 1),
            ),
            child: const Text(
              'Belum cukup',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _CohortMetric extends StatelessWidget {
  const _CohortMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final double? value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            // Null tetap "—": angka yang tidak dikirim server tidak boleh
            // berubah menjadi 0 di klien.
            value == null ? '—' : value!.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: AppColors.midnight,
            ),
          ),
          Text(
            value == null ? '' : unit,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.warmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
