import 'package:flutter/material.dart';

/// Palet Sanctuary — dipilih untuk konteks kesehatan mental:
/// warna rendah saturasi, kontras lembut, tanpa merah menyala kecuali
/// untuk kondisi krisis (di mana urgensi memang diperlukan).
class AppColors {
  const AppColors._();

  // --- Primer ---
  static const sage = Color(0xFF8FAE86); // Soft Sage Green
  static const sageLight = Color(0xFFDCE8D5);
  static const sageDark = Color(0xFF5F7A57);

  static const lavender = Color(0xFF9C8FC4); // Muted Lavender
  static const lavenderLight = Color(0xFFE7E1F4);
  static const lavenderDark = Color(0xFF6E619A);

  static const calmingBlue = Color(0xFF7FA8C9); // Calming Blue
  static const calmingBlueLight = Color(0xFFDCEAF4);

  // --- Netral hangat ---
  static const cream = Color(0xFFFAF6EE); // Soft Cream (background terang)
  static const creamAlt = Color(0xFFF2EDE3);
  static const warmGrey = Color(0xFF7C766D); // Warm Grey (teks sekunder)
  static const warmGreyDark = Color(0xFF4A453E);

  // --- Dark mode ---
  static const darkBackground = Color(0xFF1C1E1D);
  static const darkSurface = Color(0xFF262A28);
  static const darkSurfaceAlt = Color(0xFF2F3431);
  static const darkTextPrimary = Color(0xFFE9E6E0);
  static const darkTextSecondary = Color(0xFFA8A49C);

  // --- Semantik status EWS (selaras dengan konstanta backend) ---
  static const ewsNormal = Color(0xFF8FAE86);
  static const ewsWatch = Color(0xFFD9B26A);
  static const ewsRisk = Color(0xFFD08C5E);
  static const ewsIntervention = Color(0xFFC26B6B);
  static const ewsInsufficient = Color(0xFF9E9A93);

  /// Warna status EWS dari kode level backend.
  static Color ewsLevel(String? level) => switch (level) {
        'NORMAL' => ewsNormal,
        'WATCH' => ewsWatch,
        'RISK' => ewsRisk,
        'INTERVENTION' => ewsIntervention,
        _ => ewsInsufficient,
      };

  // --- Shadow claymorphism ---
  static const clayShadowLight = Color(0x33FFFFFF);
  static const clayShadowDarkLight = Color(0x1A5A554D);
  static const clayShadowDarkMode = Color(0x66000000);
  static const clayHighlightDarkMode = Color(0x14FFFFFF);
}
