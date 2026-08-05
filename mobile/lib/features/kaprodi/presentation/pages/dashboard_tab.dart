import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';

class KaprodiDashboardTab extends StatelessWidget {
  const KaprodiDashboardTab({super.key});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Kaprodi',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.midnight),
                      ),
                      Text(
                        'Program Studi S1 Teknik Informatika',
                        style: TextStyle(fontSize: 13, color: AppColors.warmTextSecondary),
                      ),
                    ],
                  ),
                  WavyBadge(text: 'k-Anonymity ≥ 5', color: AppColors.moodDisgustBg),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                '6 Metrik Agregat Program Studi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.midnight),
              ),
              const SizedBox(height: AppSpacing.sm),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricTile('Total Mahasiswa Aktif', '420', AppColors.moodFearBg),
                  _buildMetricTile('Partisipasi Check-in', '78%', AppColors.moodDisgustBg),
                  _buildMetricTile('Indeks Stres Prodi', '2.4 / 5', AppColors.moodAngerBg),
                  _buildMetricTile('Status EWS Risk', '12 Mhs', AppColors.moodAngerBg),
                  _buildMetricTile('Rata-rata Tidur', '6.8 Jam', AppColors.moodSadnessBg),
                  _buildMetricTile('Bantuan Terkirim', '34 Kali', AppColors.lavenderBg),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Sebaran EWS Angkatan
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sebaran Early Warning System (EWS)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight)),
                    SizedBox(height: 8),
                    Text('• EWS Normal: 310 Mahasiswa (74%)', style: TextStyle(fontSize: 13, color: AppColors.moodDisgust)),
                    Text('• EWS Watch: 78 Mahasiswa (18%)', style: TextStyle(fontSize: 13, color: AppColors.moodAnger)),
                    Text('• EWS Risk: 32 Mahasiswa (8%)', style: TextStyle(fontSize: 13, color: AppColors.ewsIntervention)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warmTextSecondary)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.midnight)),
        ],
      ),
    );
  }
}
