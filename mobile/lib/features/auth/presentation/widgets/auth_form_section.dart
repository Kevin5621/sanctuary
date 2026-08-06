import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Pengelompokan isian pada formulir panjang.
///
/// Formulir pendaftaran memuat tiga hal yang berbeda sifatnya — identitas
/// diri, data akademik, dan kredensial. Memberi masing-masing judul membuat
/// pendaftar tahu ia sedang mengisi apa, alih-alih menghadapi satu tumpukan
/// kotak isian yang tampak sama semua.
class AuthFormSection extends StatelessWidget {
  const AuthFormSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(description!, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.md),
        ...children,
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
