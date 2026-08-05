import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'bantuan_darurat_page.dart';
import 'dass21_screening_page.dart';
import 'edukasi_model_page.dart';
import 'latihan_napas_page.dart';
import 'pengingat_settings_page.dart';
import 'privacy_settings_page.dart';
import 'riwayat_analisis_page.dart';

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header Profil Mahasiswa
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cartoonShadow,
                  offset: Offset(0, 4),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.moodHappinessBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.midnight, width: 2),
                  ),
                  child: const Center(
                    child: Text('🎓', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Charlie Pratama',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.midnight,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mahasiswa · NIM: 22010198\nS1 Teknik Informatika',
                        style: TextStyle(
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

          const SizedBox(height: AppSpacing.lg),

          const Text(
            'Pengaturan & Riwayat (7 Menu)',
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
            destination: const MahasiswaPrivacySettingsPage(),
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

          // 4. Edukasi Model
          _buildMenuTile(
            context,
            icon: Icons.psychology_outlined,
            title: '4. Edukasi Model IndoBERT',
            subtitle: 'Bagaimana analisis emosi bekerja dan batasannya.',
            destination: const EdukasiModelPage(),
          ),

          // 5. Layanan Bantuan Darurat
          _buildMenuTile(
            context,
            icon: Icons.emergency_outlined,
            title: '5. Layanan Bantuan Darurat',
            subtitle: 'Nomor pendamping profesional 24/7.',
            destination: const BantuanDaruratPage(),
          ),

          // 6. Latihan Napas & Grounding
          _buildMenuTile(
            context,
            icon: Icons.air_rounded,
            title: '6. Latihan Napas & Grounding',
            subtitle: 'Panduan singkat untuk menenangkan diri (4-7-8).',
            destination: const LatihanNapasPage(),
          ),

          // 7. Pengingat & Mode Gelap
          _buildMenuTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: '7. Pengingat & Mode Gelap',
            subtitle: 'Atur notifikasi check-in dan tampilan aplikasi.',
            destination: const PengingatSettingsPage(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Tombol Keluar Sesi
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Keluar Sesi'),
                  content: const Text(
                      'Apakah Anda yakin ingin keluar dari akun Mahasiswa?'),
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
            icon: const Icon(Icons.logout_rounded, color: AppColors.midnight),
            label: const Text('Keluar Sesi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.creamAlt,
              foregroundColor: AppColors.midnight,
              minimumSize: const Size.fromHeight(48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                side: const BorderSide(color: AppColors.cartoonBorder, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.lavenderBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.midnight, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.midnight),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.midnight),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),
    );
  }
}
