import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'auth_field_label.dart';

/// Satu pilihan pada [AuthDropdownField].
class AuthDropdownItem<T> {
  const AuthDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Dropdown berlabel dengan gaya yang sama dengan isian teks formulir.
class AuthDropdownField<T> extends StatelessWidget {
  const AuthDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.hintText,
    this.prefixIcon,
    this.enabled = true,
    this.errorText,
    this.validator,
  });

  final String label;
  final List<AuthDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? hintText;
  final IconData? prefixIcon;
  final bool enabled;
  final String? errorText;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFieldLabel(label),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          validator: validator,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
          ),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item.value,
                child: Text(item.label, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
