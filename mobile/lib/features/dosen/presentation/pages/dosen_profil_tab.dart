import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class DosenProfilTab extends StatelessWidget {
  const DosenProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Profil Dosen Pembimbing'),
        elevation: 0,
      ),
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
                  backgroundColor: AppColors.lavenderBg,
                  child: Text('👨‍🏫', style: TextStyle(fontSize: 26)),
                ),
                SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. Ir. Hendra Wijaya, M.T.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.midnight)),
                    Text('NIP: 198203152010121002\nDosen Pembimbing Akademik', style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.midnight),
            title: const Text('Kebijakan Akses Bimbingan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: const Text('Hanya dapat melihat ringkasan sesuai izin mahasiswa'),
          ),
        ],
      ),
    );
  }
}
