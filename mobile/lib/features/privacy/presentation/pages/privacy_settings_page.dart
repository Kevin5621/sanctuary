import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clay_container.dart';
import '../../../../core/widgets/responsive.dart';
import '../../domain/entities/privacy_setting.dart';
import '../cubit/privacy_cubit.dart';

/// Layar Privasi & Berbagi Data.
///
/// Tiga tingkat berbagi (radio, saling eksklusif) + dua izin terpisah (toggle).
/// Perubahan disimpan eksplisit lewat tombol Simpan.
class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PrivacyCubit(context.read())..load(),
      child: const _PrivacySettingsView(),
    );
  }
}

class _PrivacySettingsView extends StatelessWidget {
  const _PrivacySettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<PrivacyCubit, PrivacyState>(
      listenWhen: (previous, current) =>
          previous.successMessage != current.successMessage ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final message = state.successMessage ?? state.errorMessage;
        if (message == null) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        final cubit = context.read<PrivacyCubit>();
        final draft = state.draft;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Privasi & Berbagi Data'),
            actions: [
              if (state.hasChanges)
                TextButton(
                  onPressed: state.isSaving ? null : cubit.discardChanges,
                  child: const Text('Batalkan'),
                ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ContentContainer(
                  child: ListView(
                    children: [
                      _IntroCard(theme: theme),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'Tingkat berbagi ke pembimbing',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      for (final option in state.options) ...[
                        _ShareLevelTile(
                          option: option,
                          selected: draft.shareLevel == option.level,
                          onSelected: () => cubit.selectShareLevel(option.level),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      const SizedBox(height: AppSpacing.md),
                      Text('Izin tambahan', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),

                      _PermissionTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Peringatan Dini ke Pembimbing',
                        description:
                            'Pembimbing menerima status peringatan dini bila polamu menunjukkan tanda risiko.',
                        value: draft.allowEarlyWarning,
                        // Pada tingkat Tertutup tidak ada indikator yang mengalir,
                        // sehingga izin ini tidak dapat diaktifkan.
                        enabled: draft.shareLevel != ShareLevel.closed,
                        disabledHint:
                            'Aktifkan tingkat Ringkasan terlebih dahulu untuk memakai fitur ini.',
                        onChanged: cubit.toggleEarlyWarning,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      _PermissionTile(
                        icon: Icons.groups_2_outlined,
                        title: 'Ikut Statistik Prodi',
                        description:
                            'Datamu ikut dihitung sebagai angka kelompok. Kaprodi tidak pernah melihat data individu, '
                            'dan angka hanya keluar bila kelompok minimal 5 mahasiswa.',
                        value: draft.allowProgramStatistic,
                        onChanged: cubit.toggleProgramStatistic,
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      _EffectSummary(setting: draft),
                      const SizedBox(height: AppSpacing.lg),

                      ClayButton(
                        label: 'Simpan pengaturan',
                        icon: Icons.check_rounded,
                        isLoading: state.isSaving,
                        onPressed:
                            state.hasChanges && !state.isSaving ? cubit.save : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      color: theme.colorScheme.secondaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded,
              color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Isi jurnal dan percakapan dengan Terapis AI tidak pernah dibagikan '
              'ke siapa pun, apa pun pilihanmu di halaman ini. Pengaturan berikut '
              'hanya mengatur indikator kondisi.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareLevelTile extends StatelessWidget {
  const _ShareLevelTile({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final PrivacyOption option;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Semantics eksplisit: pembaca layar tetap mengenali kelompok pilihan
    // walau indikator radio digambar sendiri agar menyatu dengan gaya clay.
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: option.label,
      hint: option.description,
      child: ClayContainer(
        onTap: onSelected,
        // Pilihan terpilih memakai permukaan cekung — bahasa visual
        // claymorphism untuk "ditekan".
        type: selected ? ClayType.concave : ClayType.convex,
        color: selected ? theme.colorScheme.primaryContainer : null,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(option.description, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.disabledHint,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(description, style: theme.textTheme.bodySmall),
            if (!enabled && disabledHint != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                disabledHint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ringkasan konsekuensi pilihan — ditulis dengan sudut pandang mahasiswa
/// supaya keputusan privasi dapat diambil sadar.
class _EffectSummary extends StatelessWidget {
  const _EffectSummary({required this.setting});

  final PrivacySetting setting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lines = <String>[
      switch (setting.shareLevel) {
        ShareLevel.closed =>
          'Pembimbing tidak melihat indikator kondisimu sama sekali.',
        ShareLevel.summary =>
          'Pembimbing melihat indikator kondisi, tanpa grafik tren.',
        ShareLevel.summaryTrend =>
          'Pembimbing melihat indikator kondisi dan grafik tren mingguan.',
      },
      setting.allowEarlyWarning
          ? 'Pembimbing menerima peringatan dini bila terdeteksi tanda risiko.'
          : 'Pembimbing tidak menerima peringatan dini.',
      setting.allowProgramStatistic
          ? 'Datamu ikut dihitung dalam statistik kelompok prodi.'
          : 'Datamu tidak ikut dihitung dalam statistik prodi.',
    ];

    return ClayCard(
      title: 'Yang akan terjadi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(line, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
