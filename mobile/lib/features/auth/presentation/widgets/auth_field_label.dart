import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Label di atas sebuah isian formulir.
///
/// Wajib/opsional ditandai eksplisit di label, bukan hanya lewat pesan error
/// setelah tombol ditekan: pendaftar berhak tahu apa yang harus ia siapkan
/// sebelum mulai mengetik.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              '(opsional)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
