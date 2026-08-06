import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// Tab Profil Admin (A-PRO-01).
///
/// Batas akses admin ditulis di klien — dan itu disengaja: tidak ada endpoint
/// `/admin/me/profile`, karena membuatnya berarti membangun jalur API baru untuk
/// peran yang justru tidak boleh punya akses ke data apa pun. Daftar di bawah
/// adalah salinan aturan yang ditegakkan RBAC backend, bukan sumbernya.
class AdminProfilTab extends StatelessWidget {
  const AdminProfilTab({super.key});

  static const _accessLimits = [
    'Anda tidak dapat melihat data mahasiswa apa pun — indikator maupun agregat.',
    'Anda tidak dapat membaca jurnal maupun percakapan Terapis AI.',
    'Anda tidak dapat melihat daftar bimbingan dosen atau dashboard prodi.',
    'Peran Anda mengelola konfigurasi layanan, bukan mengawasi orang.',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;

    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SectionHeader(
              title: 'Profil',
              subtitle: 'Administrator Sistem',
            ),
            const SizedBox(height: AppSpacing.lg),

            StateCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.moodFearBg,
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

            const AccessLimitsCard(limits: _accessLimits),
            const SizedBox(height: AppSpacing.lg),

            const _LogoutButton(roleTitle: 'akun Administrator'),
            const SizedBox(height: 96),
          ],
        ),
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
