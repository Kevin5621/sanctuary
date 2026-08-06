import 'package:flutter/material.dart';

/// Palet Warna Sanctuary — Light Cartoon Minimalist Aesthetic
/// Terinspirasi dari desain Moodiary dengan palet krem lembut, midnight navy,
/// dan warna blob emosi pastel yang cerah & ramah.
class AppColors {
  const AppColors._();

  // --- Latar Belakang & Netral Utama ---
  static const creamBg = Color(0xFFFAF7F2); // Warm Light Cream (Latar Utama)
  static const creamAlt = Color(0xFFF3ECE0); // Latar Sekunder / Card Alt
  static const cardBg = Color(0xFFFFFFFF); // Soft White Card
  static const midnight = Color(0xFF1B2038); // Midnight Navy (Text Utama & Primary Button)
  static const warmTextSecondary = Color(0xFF6C6A7B); // Text Sekunder
  static const warmTextMuted = Color(0xFF9E9BAE); // Text Muted / Hint

  // --- Backward Compatibility Aliases ---
  static const sage = Color(0xFF94BA87);
  static const sageLight = Color(0xFFE5F2E1);
  static const sageDark = Color(0xFF5F7A57);
  static const lavender = Color(0xFFB5A4E3);
  static const lavenderBg = Color(0xFFECE6F8);
  static const lavenderLight = Color(0xFFECE6F8);
  static const lavenderDark = Color(0xFF6E619A);
  static const calmingBlue = Color(0xFF96B8EE);
  static const calmingBlueLight = Color(0xFFE3EDFF);
  static const cream = Color(0xFFFAF7F2);
  static const warmGrey = Color(0xFF6C6A7B);
  static const warmGreyDark = Color(0xFF1B2038);

  // --- Palet Pastel Mood & Blob Emosi ---
  // 1. Disgust (Jijik / Apatis) - Sage Green
  static const moodDisgust = Color(0xFF94BA87);
  static const moodDisgustBg = Color(0xFFE5F2E1);

  // 2. Fear (Cemas / Takut) - Soft Mint
  static const moodFear = Color(0xFF88CCBA);
  static const moodFearBg = Color(0xFFDFF4EE);

  // 3. Sadness (Sedih / Lesu) - Sky Blue
  static const moodSadness = Color(0xFF96B8EE);
  static const moodSadnessBg = Color(0xFFE3EDFF);

  // 4. Anger (Marah / Kesal) - Warm Peach / Orange
  static const moodAnger = Color(0xFFF5B667);
  static const moodAngerBg = Color(0xFFFDECD4);

  // 5. Happiness (Senang / Baik) - Soft Pink
  static const moodHappiness = Color(0xFFFA9BB0);
  static const moodHappinessBg = Color(0xFFFDE2E8);

  // 6. Great / Sun (Sangat baik) - Sunshine Gold / Amber
  static const moodGreat = Color(0xFFFFB703);
  static const moodGreatBg = Color(0xFFFFF3D6);

  // Extra Mood Accents
  static const sunnyYellow = Color(0xFFFBD76B);

  // --- Status EWS (Early Warning System) ---
  static const ewsNormal = Color(0xFF94BA87);
  static const ewsWatch = Color(0xFFF5B667);
  static const ewsRisk = Color(0xFFE58850);
  static const ewsIntervention = Color(0xFFD95B5B);
  static const ewsInsufficient = Color(0xFF9E9BAE);

  static Color ewsLevel(String? level) => switch (level) {
        'NORMAL' => ewsNormal,
        'WATCH' => ewsWatch,
        'RISK' => ewsRisk,
        'INTERVENTION' => ewsIntervention,
        _ => ewsInsufficient,
      };

  // --- Dark Mode Fallbacks ---
  static const darkBackground = Color(0xFF141724);
  static const darkSurface = Color(0xFF1E2338);
  static const darkSurfaceAlt = Color(0xFF282F48);
  static const darkTextPrimary = Color(0xFFF3ECE0);
  static const darkTextSecondary = Color(0xFFA5A2B8);

  // --- Soft Shadow & Borders ---
  static const cartoonShadow = Color(0x141B2038);
  static const cartoonBorder = Color(0x1A1B2038);
  static const clayHighlightDarkMode = Color(0x14FFFFFF);
  static const clayShadowDarkMode = Color(0x66000000);
  static const clayShadowDarkLight = Color(0x1A5A554D);
  static const clayShadowLight = Color(0x33FFFFFF);
}
