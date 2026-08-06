import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';

class EdukasiModelPage extends StatelessWidget {
  const EdukasiModelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Edukasi Model IndoBERT'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
            ),
            child: const Column(
              children: [
                CartoonMoodBlob(mood: MoodType.fear, size: 80),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Bagaimana Analisis Emosi Bekerja?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.midnight),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Sanctuary menggunakan model bahasa alami IndoBERT yang dilatih secara spesifik menggunakan korpus bahasa Indonesia konteks akademik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.warmTextSecondary, fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoSection(
            icon: Icons.psychology_outlined,
            title: '1. Deteksi Emosi kontekstual',
            desc: 'IndoBERT tidak hanya mencocokkan kata kunci, melainkan memahami nuansa kalimat seperti stres akademik, kelelahan, rasa cemas, hingga harapan positif.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoSection(
            icon: Icons.lock_outline_rounded,
            title: '2. Enkripsi & Jaminan Privasi',
            desc: 'Teks catatan jurnalmu dianalisis secara terenkripsi. Hasilnya digunakan khusus untuk merekomendasikan strategi pertolongan diri (coping).',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoSection(
            icon: Icons.warning_amber_rounded,
            title: '3. Batasan Model & Bukan Diagnosis',
            desc: 'Analisis IndoBERT bukan merupakan diagnosis medis profesional. Bila membutuhkan pendampingan, kamu disarankan menghubungi psikolog/konselor.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.lavenderBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.midnight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 13, color: AppColors.warmTextSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
