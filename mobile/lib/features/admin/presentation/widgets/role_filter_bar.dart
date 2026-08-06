import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/managed_user.dart';

/// Penyaring peran pada daftar kelola akun.
///
/// Pilihan perannya berasal dari server (`/admin/user-options`), bukan ditulis
/// ulang di klien — daftar filter yang menawarkan peran di luar kelola akun
/// hanya akan menghasilkan hasil kosong yang membingungkan.
class RoleFilterBar extends StatelessWidget {
  const RoleFilterBar({
    super.key,
    required this.roles,
    required this.selected,
    required this.onSelected,
  });

  final List<RoleOption> roles;

  /// Null berarti "Semua".
  final String? selected;

  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Semua',
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final role in roles)
            _FilterChip(
              label: role.label,
              isSelected: selected == role.value,
              onTap: () => onSelected(role.value),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.midnight : AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: isSelected ? AppColors.midnight : AppColors.cartoonBorder,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: isSelected ? Colors.white : AppColors.warmTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
