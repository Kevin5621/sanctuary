import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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

                // Identitas dari /auth/me
                StateCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.lavenderBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.midnight, width: 1.8),
                        ),
                        child: Center(
                          child: Text(
                            (user?.fullName.trim().isNotEmpty ?? false)
                                ? user!.fullName.trim()[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
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
                                fontSize: 18,
                                color: AppColors.midnight,
                              ),
                            ),
                            const SizedBox(height: 4),
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

                // Data bimbingan
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
                      const SizedBox(width: AppSpacing.md),
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

                  // Batas akses eksplisit dari server
                  if (state.profile.accessLimits.isNotEmpty)
                    AccessLimitsCard(limits: state.profile.accessLimits),
                ],

                const SizedBox(height: AppSpacing.lg),
                const _LogoutButton(roleTitle: 'akun Dosen Pembimbing'),
                const SizedBox(height: 96),
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
          Icon(icon, size: 24, color: AppColors.midnight),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.roleTitle});

  final String roleTitle;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Keluar Sesi'),
            content: Text(
                'Apakah Anda yakin ingin keluar dari $roleTitle?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ewsIntervention,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<AuthCubit>().logout();
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.logout_rounded, size: 24),
      label: const Text(
        'Keluar Sesi',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
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
