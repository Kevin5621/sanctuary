import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class DosenKondisiTab extends StatelessWidget {
  const DosenKondisiTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gambaran Agregat Kelompok',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.midnight),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ringkasan kondisi 30/90/120 hari bimbingan',
                style: TextStyle(fontSize: 13, color: AppColors.warmTextSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Banner Compliance k-Anonymity (N >= 5 Rule)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lavenderBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.midnight, width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: AppColors.midnight, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Privasi k-Anonymity Aktif: Data individual jurnal terlindungi secara otomatis.',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.midnight, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Stat Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Rata-rata Mood', '3.8 / 5', AppColors.moodHappinessBg),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatCard('Tingkat Stres', 'Sedang', AppColors.moodAngerBg),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Kepatuhan Check-in', '84%', AppColors.moodDisgustBg),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatCard('Risiko Krisis', '0 Mahasiswa', AppColors.moodFearBg),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.midnight)),
        ],
      ),
    );
  }
}
