import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/privacy_states.dart';

/// Elemen formulir kelola akun Admin.
///
/// Gayanya mengikuti formulir layanan bantuan (kartu krem, border tegas,
/// radius besar) supaya kedua layar Admin terasa satu halaman, bukan dua
/// aplikasi yang kebetulan bersebelahan.

const _fieldRadius = AppSpacing.radiusMd;

InputDecoration adminInputDecoration(String hint, {String? errorText}) {
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    counterText: '',
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
    filled: true,
    fillColor: AppColors.cardBg,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: const BorderSide(color: AppColors.midnight, width: 1.8),
    ),
  );
}

class StaffFieldLabel extends StatelessWidget {
  const StaffFieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.midnight,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: AppSpacing.sm),
            const Text(
              '(opsional)',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: AppColors.warmTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StaffTextField extends StatelessWidget {
  const StaffTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.optional = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.enabled = true,
    this.maxLength,
    this.helperText,
    this.errorText,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool optional;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final int? maxLength;
  final String? helperText;
  final String? errorText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffFieldLabel(label, optional: optional),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          maxLength: maxLength,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppColors.midnight),
          decoration: adminInputDecoration(hintText, errorText: errorText),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              helperText!,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.warmTextMuted,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class StaffDropdownItem<T> {
  const StaffDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

class StaffDropdownField<T> extends StatelessWidget {
  const StaffDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    required this.hintText,
    this.value,
    this.enabled = true,
    this.errorText,
    this.validator,
  });

  final String label;
  final List<StaffDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hintText;
  final T? value;
  final bool enabled;
  final String? errorText;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffFieldLabel(label),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          validator: validator,
          onChanged: enabled ? onChanged : null,
          style: const TextStyle(fontSize: 14, color: AppColors.midnight),
          decoration: adminInputDecoration(hintText, errorText: errorText),
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

/// Sakelar status akun beserta akibatnya, ditulis apa adanya.
///
/// "Nonaktif" di sini bukan sekadar label: pemiliknya langsung tidak dapat
/// masuk dan sesinya yang sedang berjalan diakhiri. Admin berhak tahu itu
/// sebelum menggeser sakelarnya, bukan sesudah seseorang menelepon bertanya
/// kenapa ia tiba-tiba keluar sendiri.
class StaffActiveSwitch extends StatelessWidget {
  const StaffActiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        activeTrackColor: AppColors.midnight,
        onChanged: onChanged,
        title: const Text(
          'Akun aktif',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.midnight,
          ),
        ),
        subtitle: Text(
          value
              ? 'Pemilik akun dapat masuk seperti biasa.'
              : 'Pemilik akun tidak dapat masuk, dan sesinya yang sedang '
                  'berjalan langsung diakhiri.',
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.3,
            color: AppColors.warmTextSecondary,
          ),
        ),
      ),
    );
  }
}
