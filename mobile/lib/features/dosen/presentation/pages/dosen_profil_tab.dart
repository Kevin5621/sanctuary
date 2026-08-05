import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/mentor_repository.dart';
import '../cubit/dosen_profil_cubit.dart';

/// Tab Profil Dosen (L-PRO-01..04).
class DosenProfilTab extends StatelessWidget {
  const DosenProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DosenProfilCubit(context.read<MentorRepository>())..load(),
      child: const _DosenProfilView(),
    );
  }
}

class _DosenProfilView extends StatelessWidget {
  const _DosenProfilView();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;

    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DosenProfilCubit, DosenProfilState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const SectionHeader(
                  title: 'Profil',
                  subtitle: 'Dosen Pembimbing Akademik',
                ),
                const SizedBox(height: AppSpacing.lg),

                // L-PRO-01 — identitas dari /auth/me
                StateCard(
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.lavenderBg,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.midnight, width: 1.8),
                        ),
                        child: Center(
                          child: Text(
                            (user?.fullName.trim().isNotEmpty ?? false)
                                ? user!.fullName.trim()[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: AppColors.midnight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? '—',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: AppColors.midnight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.warmTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // L-PRO-02 — jumlah mahasiswa bimbingan
                if (state.isLoading)
                  const LoadingState(label: 'Memuat data bimbingan…', padding: 24)
                else if (state.status == DosenProfilStatus.failure)
                  ErrorStateCard(
                    message: state.errorMessage ??
                        'Periksa koneksi internet Anda lalu coba lagi.',
                    onRetry: () => context.read<DosenProfilCubit>().load(),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _CountTile(
                          value: '${state.profile.adviseeCount}',
                          label: 'Mahasiswa bimbingan',
                          color: AppColors.moodDisgustBg,
                          icon: Icons.groups_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CountTile(
                          value: '${state.profile.openContactRequest}',
                          label: 'Minta dihubungi',
                          color: AppColors.moodAngerBg,
                          icon: Icons.pan_tool_alt_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // L-PRO-03 — batas akses eksplisit, teksnya dari server
                  if (state.profile.accessLimits.isNotEmpty)
                    AccessLimitsCard(limits: state.profile.accessLimits),
                ],

                const SizedBox(height: AppSpacing.md),

                // L-PRO-04 — mode gelap, persisten
                const DarkModeCard(),

                const SizedBox(height: AppSpacing.md),
                const _LogoutButton(),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.midnight),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 26,
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

/// Kartu pengaturan mode gelap yang dipakai bersama tab Profil Dosen, Kaprodi,
/// dan Admin (L-PRO-04, K-PRO-01, A-PRO-01 — sama dengan M-PRO-08).
class DarkModeCard extends StatelessWidget {
  const DarkModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final isDark = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    return StateCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 22,
                color: AppColors.midnight,
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode gelap',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.midnight,
                      ),
                    ),
                    Text(
                      'Pilihan ini tersimpan di perangkat Anda',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                activeTrackColor: AppColors.midnight,
                onChanged: (_) => context
                    .read<ThemeCubit>()
                    .toggleDark(isCurrentlyDark: isDark),
              ),
            ],
          ),
          if (themeMode != ThemeMode.system) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    context.read<ThemeCubit>().setMode(ThemeMode.system),
                icon: const Icon(Icons.settings_suggest_outlined, size: 16),
                label: const Text('Ikuti pengaturan sistem'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.warmTextSecondary,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.read<AuthCubit>().logout(),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ewsIntervention,
        side: const BorderSide(color: AppColors.ewsIntervention, width: 1.5),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
      ),
    );
  }
}
