import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class MahasiswaPrivacySettingsPage extends StatefulWidget {
  const MahasiswaPrivacySettingsPage({super.key});

  @override
  State<MahasiswaPrivacySettingsPage> createState() => _MahasiswaPrivacySettingsPageState();
}

class _MahasiswaPrivacySettingsPageState extends State<MahasiswaPrivacySettingsPage> {
  String _sharingLevel = 'SUMMARY_ONLY'; // FULL, SUMMARY_ONLY, ANONYMOUS
  bool _allowCrisisAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Privasi & Berbagi Data'),
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
              border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.lavenderBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.midnight),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Akses Dosen Pembimbing',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.midnight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Kamu dapat mengontrol seberapa banyak ringkasan kesehatan mentalmu yang dapat dilihat oleh Dosen Pembimbing Akademik.',
                  style: TextStyle(color: AppColors.warmTextSecondary, fontSize: 13, height: 1.4),
                ),
                const Divider(height: 24),
                _buildOptionTile(
                  key: 'ANONYMOUS',
                  title: '1. Sepenuhnya Anonim',
                  desc: 'Dosen hanya melihat statistik agregat prodi tanpa tahu nama atau identitasmu.',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildOptionTile(
                  key: 'SUMMARY_ONLY',
                  title: '2. Ringkasan Kategori (Direkomendasikan)',
                  desc: 'Dosen melihat label kategori umum (misal: "Stres Sedang") tanpa rincian isi jurnal.',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildOptionTile(
                  key: 'FULL',
                  title: '3. Akses Penuh Bimbingan',
                  desc: 'Dosen dapat melihat grafik mood dan riwayat check-in untuk pendampingan intensif.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _allowCrisisAlerts,
                  onChanged: (val) {
                    setState(() {
                      _allowCrisisAlerts = val;
                    });
                  },
                  activeThumbColor: AppColors.midnight,
                  title: const Text(
                    'Notifikasi Otomatis Tanda Krisis',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.midnight),
                  ),
                  subtitle: const Text(
                    'Jika terdeteksi tanda krisis tinggi pada jurnal, sistem akan memberikan rekomendasi kontak darurat.',
                    style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({required String key, required String title, required String desc}) {
    final isSelected = _sharingLevel == key;
    return InkWell(
      onTap: () {
        setState(() {
          _sharingLevel = key;
        });
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.moodFearBg : AppColors.creamBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.midnight : AppColors.cartoonBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.midnight : AppColors.warmTextSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? AppColors.midnight : AppColors.warmTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
