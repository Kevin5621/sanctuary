import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../domain/entities/managed_user.dart';

/// Kartu satu akun dosen / kaprodi.
///
/// Akun nonaktif diredupkan supaya Admin langsung melihat siapa yang saat ini
/// tidak dapat masuk, mengikuti pola kartu layanan bantuan (A-BAN-02).
class ManagedUserCard extends StatelessWidget {
  const ManagedUserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onToggleActive,
  });

  final ManagedUser user;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: user.isActive ? 1 : 0.6,
      child: StateCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(initials: user.initials),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warmTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.warmTextSecondary),
                  onSelected: (value) => switch (value) {
                    'edit' => onEdit(),
                    'toggle' => onToggleActive(),
                    _ => null,
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(user.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                WavyBadge(
                  text: user.roleLabel,
                  color: AppColors.lavenderBg,
                  borderColor: AppColors.lavenderDark,
                  textColor: AppColors.lavenderDark,
                ),
                WavyBadge(
                  text: user.isActive ? 'Aktif' : 'Nonaktif',
                  color: user.isActive
                      ? AppColors.moodDisgustBg
                      : AppColors.creamAlt,
                  borderColor: user.isActive
                      ? AppColors.ewsNormal
                      : AppColors.warmTextMuted,
                  textColor: user.isActive
                      ? AppColors.midnight
                      : AppColors.warmTextSecondary,
                ),
                if (user.hasNeverSignedIn)
                  const WavyBadge(
                    text: 'Belum pernah masuk',
                    color: AppColors.moodAngerBg,
                    borderColor: AppColors.ewsWatch,
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            _MetaRow(
              icon: Icons.school_outlined,
              text: user.studyProgram ?? 'Program studi belum diisi',
            ),
            if (user.lecturerNumber.isNotEmpty)
              _MetaRow(
                icon: Icons.badge_outlined,
                text: 'NIDN ${user.lecturerNumber}',
              ),
            if (user.phone.isNotEmpty)
              _MetaRow(icon: Icons.call_outlined, text: user.phone),

            if (!user.isActive) ...[
              const SizedBox(height: AppSpacing.sm),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14, color: AppColors.warmTextMuted),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Akun ini tidak dapat masuk, dan sesi yang sedang '
                      'berjalan sudah diakhiri.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: AppColors.warmTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.lavenderBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.midnight, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.midnight,
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.warmTextMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
