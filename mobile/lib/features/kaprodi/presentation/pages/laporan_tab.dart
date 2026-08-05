import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class KaprodiLaporanTab extends StatelessWidget {
  const KaprodiLaporanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text('Laporan Evaluasi Per Angkatan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.midnight)),
            const SizedBox(height: 2),
            const Text('Tunduk pada ambang k-anonymity (min 5 mahasiswa per kelompok)', style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary)),
            const SizedBox(height: AppSpacing.lg),
            _buildCohortReportTile('Angkatan 2023 (Tingkat 4 / Skripsi)', 'Stres Sedang - Pemicu: Tugas Akhir & Kelulusan'),
            _buildCohortReportTile('Angkatan 2024 (Tingkat 3)', 'Stres Rendah - Kepatuhan Check-in: 88%'),
            _buildCohortReportTile('Angkatan 2025 (Tingkat 2)', 'Stres Rendah - Kepatuhan Check-in: 92%'),
          ],
        ),
      ),
    );
  }

  Widget _buildCohortReportTile(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.warmTextSecondary)),
        ],
      ),
    );
  }
}
