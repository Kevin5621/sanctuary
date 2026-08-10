import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../privacy/presentation/pages/privacy_settings_page.dart';
import '../../data/repositories/contact_request_repository.dart';
import '../../domain/entities/advisor.dart';
import '../cubit/my_advisors_cubit.dart';
import 'bantuan_darurat_page.dart';
import 'dass21_screening_page.dart';
import 'latihan_napas_page.dart';
import 'pengingat_settings_page.dart';
import 'riwayat_analisis_page.dart';

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MyAdvisorsCubit(context.read<ContactRequestRepository>())..load(),
      child: const _ProfilView(),
    );
  }
}

class _ProfilView extends StatelessWidget {
  const _ProfilView();

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
              subtitle: 'Mahasiswa',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header Profil Mahasiswa
            StateCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.moodHappinessBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.midnight, width: 1.8),
                    ),
                    child: Center(
                      child: Text(
                        (user?.fullName.trim().isNotEmpty ?? false)
                            ? user!.fullName.trim()[0].toUpperCase()
                            : '🎓',
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
                          user?.fullName ?? 'Mahasiswa',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'S1 Teknik Informatika',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warmTextSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Kartu pembimbing berada tepat di atas menu privasi dengan sengaja:
            // pilihan "seberapa banyak yang boleh dilihat" baru bermakna kalau
            // mahasiswa lebih dulu tahu siapa saja yang melihatnya.
            const _AdvisorsCard(),

            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Pengaturan & Riwayat',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 1. Privasi & Berbagi Data
            _buildMenuTile(
              context,
              icon: Icons.shield_outlined,
              title: '1. Privasi & Berbagi Data',
              subtitle: 'Atur seberapa banyak pembimbing dapat melihat.',
              destination: const PrivacySettingsPage(),
            ),

            // 2. Skrining DASS-21
            _buildMenuTile(
              context,
              icon: Icons.fact_check_outlined,
              title: '2. Skrining DASS-21',
              subtitle: 'Isi kuesioner dan lihat riwayat hasilmu.',
              destination: const Dass21ScreeningPage(),
            ),

            // 3. Riwayat Analisis
            _buildMenuTile(
              context,
              icon: Icons.analytics_outlined,
              title: '3. Riwayat Analisis',
              subtitle: 'Hasil analisis emosi dari jurnalmu.',
              destination: const RiwayatAnalisisPage(),
            ),

            // 4. Layanan Bantuan Darurat
            _buildMenuTile(
              context,
              icon: Icons.emergency_outlined,
              title: '4. Layanan Bantuan Darurat',
              subtitle: 'Nomor pendamping profesional 24/7.',
              destination: const BantuanDaruratPage(),
            ),

            // 5. Latihan Napas & Grounding
            _buildMenuTile(
              context,
              icon: Icons.air_rounded,
              title: '5. Latihan Napas & Grounding',
              subtitle: 'Panduan singkat untuk menenangkan diri (4-7-8).',
              destination: const LatihanNapasPage(),
            ),

            // 6. Pengingat Notifikasi
            _buildMenuTile(
              context,
              icon: Icons.notifications_none_rounded,
              title: '6. Pengingat Notifikasi',
              subtitle: 'Atur notifikasi check-in dan jadwal harian.',
              destination: const PengingatSettingsPage(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Tombol Keluar Sesi
            const _LogoutButton(roleTitle: 'akun Mahasiswa'),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.lavenderBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.midnight, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.midnight,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.warmTextSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.midnight,
          size: 24,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),
    );
  }
}

/// Kartu "Pembimbingmu" — daftar dosen yang membimbing mahasiswa ini.
///
/// Ditampilkan sebagai daftar (bukan satu baris teks) karena seorang mahasiswa
/// dapat dibimbing lebih dari satu dosen, dan semuanya punya akses yang sama.
class _AdvisorsCard extends StatelessWidget {
  const _AdvisorsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyAdvisorsCubit, MyAdvisorsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const StateCard(
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.midnight,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Memuat data pembimbing…',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.warmTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.isFailure) {
          return ErrorStateCard(
            message: state.errorMessage ??
                'Data pembimbing gagal dimuat. Coba lagi sebentar.',
            onRetry: () => context.read<MyAdvisorsCubit>().load(),
          );
        }

        final advisors = state.advisors;
        return StateCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_outlined,
                      size: 18, color: AppColors.midnight),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Pembimbingmu',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                  ),
                  if (!advisors.isEmpty)
                    WavyBadge(
                      text: '${advisors.total} Dosen',
                      color: AppColors.lavenderBg,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (advisors.isEmpty)
                const Text(
                  'Belum ada dosen pembimbing yang ditetapkan.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.warmTextSecondary,
                  ),
                )
              else
                for (final advisor in advisors.advisors)
                  _AdvisorRow(advisor: advisor),

              const SizedBox(height: AppSpacing.sm),
              // Kalimat konsekuensi ditulis server — satu rumusan yang sama
              // dengan yang ditegakkan API.
              Text(
                advisors.notice,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: AppColors.warmTextMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdvisorRow extends StatelessWidget {
  const _AdvisorRow({required this.advisor});

  final Advisor advisor;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (advisor.lecturerNumber.isNotEmpty) 'NIDN ${advisor.lecturerNumber}',
      if (advisor.email.isNotEmpty) advisor.email,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.lavenderBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                advisor.initial,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.midnight,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advisor.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.midnight,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warmTextSecondary,
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
