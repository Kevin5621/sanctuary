import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class KaprodiProfilTab extends StatelessWidget {
  const KaprodiProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(title: const Text('Profil Kaprodi'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.moodFearBg,
                  child: Text('🏛️', style: TextStyle(fontSize: 26)),
                ),
                SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prof. Dr. Maya Putri, M.T.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.midnight)),
                    Text('Ketua Program Studi S1 Teknik Informatika', style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary)),
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
