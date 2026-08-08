import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Identitas visual di puncak layar masuk & daftar.
///
/// Satu widget untuk dua layar: kalau lambang atau kalimat pengantarnya
/// berubah, keduanya ikut berubah — pengguna tidak menemui dua "Sanctuary"
/// yang terasa berasal dari aplikasi berbeda.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.assetPath = 'assets/icon/app_icon.png',
    this.icon,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceAlt
                : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: icon != null
                  ? Icon(
                      icon,
                      size: 32,
                      color: isDark
                          ? AppColors.lavender
                          : theme.colorScheme.onPrimaryContainer,
                    )
                  : Image.asset(
                      assetPath,
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.spa_rounded,
                        size: 32,
                        color: isDark
                            ? AppColors.lavender
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
