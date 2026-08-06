import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'auth_field_label.dart';

/// Isian kata sandi dengan tombol tampilkan/sembunyikan.
///
/// Tombol itu bukan hiasan: kata sandi yang tidak dapat dilihat sama sekali
/// mendorong orang memilih sandi pendek yang mudah diketik ulang.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.enabled = true,
    this.helperText,
    this.errorText,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final bool enabled;
  final String? helperText;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFieldLabel(widget.label),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          enabled: widget.enabled,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          onFieldSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscured = !_obscured),
              tooltip: _obscured
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              icon: Icon(
                _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
