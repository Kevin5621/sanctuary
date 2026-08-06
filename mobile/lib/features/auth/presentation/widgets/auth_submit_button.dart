import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Tombol aksi utama layar autentikasi.
///
/// Saat [isLoading] tombol menjadi nonaktif, bukan sekadar berganti ikon:
/// dua kali tekan pada formulir pendaftaran berarti dua permintaan akun.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.6),
          disabledForegroundColor:
              theme.colorScheme.onPrimary.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(icon, size: 18, color: theme.colorScheme.onPrimary),
                ],
              ),
      ),
    );
  }
}
