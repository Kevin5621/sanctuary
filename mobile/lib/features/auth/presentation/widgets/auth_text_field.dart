import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import 'auth_field_label.dart';

/// Isian teks berlabel untuk formulir masuk & daftar.
///
/// Gaya visualnya sengaja mengambil `inputDecorationTheme` aplikasi apa adanya
/// (radius, border, warna isi) alih-alih mendefinisikan ulang — supaya layar
/// autentikasi tidak perlahan menyimpang dari layar lain saat tema berubah.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.enabled = true,
    this.optional = false,
    this.errorText,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool enabled;
  final bool optional;

  /// Pesan error dari server (`field_errors`), terpisah dari validasi lokal.
  final String? errorText;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFieldLabel(label, optional: optional),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          enabled: enabled,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            // counterText kosong: batas panjang tetap ditegakkan, tetapi
            // penghitung karakter di bawah setiap isian membuat formulir
            // sepanjang ini terlihat jauh lebih berat daripada sebenarnya.
            counterText: '',
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
