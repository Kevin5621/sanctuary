import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';

/// Pemetaan kode emosi backend ke bentuk visual.
///
/// Backend mengenal tujuh label emosi check-in, sementara ilustrasi hanya punya
/// lima wajah. Pemetaannya dikumpulkan di satu tempat supaya kalender, grafik,
/// dan kartu ringkasan tidak pernah menggambar emosi yang sama dengan wajah
/// berbeda.
class MoodVisuals {
  const MoodVisuals._();

  static const _byEmotion = <String, MoodType>{
    'JOY': MoodType.happiness,
    'CALM': MoodType.happiness,
    'NEUTRAL': MoodType.disgust,
    'TIRED': MoodType.disgust,
    'ANXIOUS': MoodType.fear,
    'SAD': MoodType.sadness,
    'ANGRY': MoodType.anger,
  };

  /// Wajah untuk sebuah label emosi; jatuh kembali ke skor mood bila catatan
  /// itu tidak punya label (emosi bersifat opsional saat check-in).
  static MoodType forEmotion(String emotionLabel, {int moodScore = 3}) {
    final mapped = _byEmotion[emotionLabel];
    if (mapped != null) return mapped;
    return forScore(moodScore);
  }

  static MoodType forScore(int moodScore) {
    if (moodScore >= 5) return MoodType.great;
    if (moodScore == 4) return MoodType.happiness;
    if (moodScore == 3) return MoodType.disgust;
    if (moodScore == 2) return MoodType.fear;
    return MoodType.sadness;
  }

  /// Warna sel kalender berdasarkan skor mood 1..5.
  static Color colorForScore(int moodScore) {
    switch (moodScore) {
      case 5:
        return AppColors.moodGreat;
      case 4:
        return AppColors.moodHappiness;
      case 3:
        return AppColors.moodDisgust;
      case 2:
        return AppColors.moodFear;
      case 1:
        return AppColors.moodSadness;
      default:
        return AppColors.creamAlt;
    }
  }

  static Color backgroundForScore(int moodScore) {
    switch (moodScore) {
      case 5:
        return AppColors.moodGreatBg;
      case 4:
        return AppColors.moodHappinessBg;
      case 3:
        return AppColors.moodDisgustBg;
      case 2:
        return AppColors.moodFearBg;
      case 1:
        return AppColors.moodSadnessBg;
      default:
        return AppColors.creamAlt;
    }
  }
}

/// Sel kosong pada kalender — hari yang memang tidak diisi.
///
/// Sengaja dibedakan dari hari bermood rendah: tidak mengisi bukan berarti
/// sedang buruk, dan menyamakan keduanya akan menyesatkan pembacanya.
class EmptyDayCell extends StatelessWidget {
  const EmptyDayCell({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.creamAlt,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Icon(
        Icons.horizontal_rule_rounded,
        size: size * 0.5,
        color: AppColors.warmTextMuted,
      ),
    );
  }
}
