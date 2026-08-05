import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/program_repository.dart';
import '../../domain/entities/program_dashboard.dart';
import '../cubit/kaprodi_cubit.dart';

/// Tab Pembimbing (K-PEM-01) — daftar dosen dan beban bimbingannya.
///
/// Jumlah bimbingan adalah data ADMINISTRATIF, bukan data wellbeing, sehingga
/// tidak tunduk k-anonymity dan ditampilkan apa adanya.
///
/// SENGAJA TIDAK ADA di layar ini: jumlah mahasiswa berisiko per dosen.
/// Angka itu adalah data kondisi pada kelompok kecil — persis yang dilarang
/// dilihat kaprodi (PRD §3.3) — dan backend memang tidak mengirimkannya.
class KaprodiPembimbingTab extends StatelessWidget {
  const KaprodiPembimbingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PembimbingCubit(context.read<ProgramRepository>())..load(),
      child: const _PembimbingView(),
    );
  }
}

class _PembimbingView extends StatelessWidget {
  const _PembimbingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<PembimbingCubit, PembimbingState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<PembimbingCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  SectionHeader(
                    title: 'Dosen Pembimbing',
                    subtitle: 'Sebaran beban bimbingan di program studi',
                    trailing: state.status.isReady
                        ? WavyBadge(
                            text: '${state.advisors.length} Dosen',
                            color: AppColors.lavenderBg,
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.status.isLoading)
                    const LoadingState(label: 'Memuat data pembimbing…')
                  else if (state.status.isFailure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context.read<PembimbingCubit>().load(),
                    )
                  else if (state.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.school_outlined,
                      title: 'Belum ada dosen pembimbing',
                      description:
                          'Belum ada dosen yang terdaftar pada program studi ini.',
                    )
                  else ...[
                    _SummaryBar(state: state),
                    const SizedBox(height: AppSpacing.md),
                    for (final advisor in state.advisors)
                      _AdvisorCard(
                        advisor: advisor,
                        maxLoad: state.advisors
                            .map((a) => a.adviseeCount)
                            .fold(1, (a, b) => a > b ? a : b),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    const _AdministrativeNote(),
                  ],

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

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.state});

  final PembimbingState state;

  @override
  Widget build(BuildContext context) {
    final average = state.advisors.isEmpty
        ? 0.0
        : state.totalAdvisees / state.advisors.length;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${state.totalAdvisees}',
            label: 'Total bimbingan',
            color: AppColors.moodDisgustBg,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            value: average.toStringAsFixed(1),
            label: 'Rata-rata per dosen',
            color: AppColors.moodFearBg,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: AppColors.midnight,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.warmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  const _AdvisorCard({required this.advisor, required this.maxLoad});

  final AdvisorLoad advisor;

  /// Beban tertinggi di prodi — dipakai sebagai skala batang agar perbandingan
  /// antar dosen terbaca, bukan sebagai penilaian atas dosennya.
  final int maxLoad;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.lavenderBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.midnight, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    advisor.fullName.trim().isEmpty
                        ? '?'
                        : advisor.fullName.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advisor.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.midnight,
                      ),
                    ),
                    Text(
                      [
                        if (advisor.lecturerNumber.isNotEmpty)
                          'NIP ${advisor.lecturerNumber}',
                        advisor.email,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              WavyBadge(
                text: '${advisor.adviseeCount}',
                color: AppColors.moodDisgustBg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: maxLoad == 0 ? 0 : advisor.adviseeCount / maxLoad,
              minHeight: 8,
              backgroundColor: AppColors.creamAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.moodDisgust),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${advisor.adviseeCount} mahasiswa bimbingan',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.warmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdministrativeNote extends StatelessWidget {
  const _AdministrativeNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.creamAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.warmTextMuted),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Angka di halaman ini adalah beban administratif, bukan data '
              'kondisi. Kondisi mahasiswa per dosen tidak ditampilkan kepada '
              'kaprodi — kelompok sekecil itu akan menunjuk orang tertentu.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
