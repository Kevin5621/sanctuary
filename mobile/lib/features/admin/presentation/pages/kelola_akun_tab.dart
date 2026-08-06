import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/user_admin_repository.dart';
import '../../domain/entities/managed_user.dart';
import '../cubit/kelola_akun_cubit.dart';
import '../widgets/managed_user_card.dart';
import '../widgets/role_filter_bar.dart';
import 'staff_form_page.dart';

/// Tab Kelola Akun Admin (A-AKN-01..03) — akun dosen & kaprodi.
///
/// SENGAJA TIDAK ADA di layar ini: akun mahasiswa. Mereka mendaftar sendiri,
/// dan menampilkan daftarnya di sini akan memberi Admin sebuah direktori
/// mahasiswa yang tidak ia butuhkan untuk tugasnya.
class KelolaAkunTab extends StatelessWidget {
  const KelolaAkunTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KelolaAkunCubit(context.read<UserAdminRepository>())
        ..load(withOptions: true),
      child: const _KelolaAkunView(),
    );
  }
}

class _KelolaAkunView extends StatelessWidget {
  const _KelolaAkunView();

  Future<void> _openForm(BuildContext context, {ManagedUser? existing}) {
    final cubit = context.read<KelolaAkunCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        // Cubit yang sama diteruskan agar daftar di belakang ikut segar
        // setelah simpan, tanpa perlu memuat ulang manual.
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: StaffFormPage(
            existing: existing,
            roles: cubit.state.roles,
            studyPrograms: cubit.state.studyPrograms,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmToggle(BuildContext context, ManagedUser user) async {
    final cubit = context.read<KelolaAkunCubit>();

    if (user.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Nonaktifkan akun?'),
          content: Text(
            '${user.fullName} tidak akan dapat masuk, dan sesinya yang sedang '
            'berjalan langsung diakhiri.\n\nData bimbingannya tetap tersimpan '
            'dan kembali dapat diakses begitu akun diaktifkan lagi.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ewsIntervention,
              ),
              child: const Text('Nonaktifkan'),
            ),
          ],
        ),
      );
      if (!(confirmed ?? false)) return;
    }

    await cubit.toggleActive(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<KelolaAkunCubit, KelolaAkunState>(
          listenWhen: (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            final message = state.successMessage ?? state.errorMessage;
            if (message == null) return;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: state.successMessage != null
                      ? AppColors.midnight
                      : AppColors.ewsIntervention,
                ),
              );
            context.read<KelolaAkunCubit>().clearMessages();
          },
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<KelolaAkunCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  SectionHeader(
                    title: 'Kelola Akun',
                    subtitle: 'Akun dosen pembimbing & kaprodi',
                    trailing: state.status == AkunStatus.ready
                        ? WavyBadge(
                            text: '${state.activeCount} aktif',
                            color: AppColors.moodDisgustBg,
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ElevatedButton.icon(
                    onPressed: state.canOpenForm && !state.isSaving
                        ? () => _openForm(context)
                        : null,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Buat Akun Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.midnight,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  RoleFilterBar(
                    roles: state.roles,
                    selected: state.roleFilter,
                    onSelected: (role) =>
                        context.read<KelolaAkunCubit>().filterByRole(role),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (state.isLoading)
                    const LoadingState(label: 'Memuat daftar akun…')
                  else if (state.status == AkunStatus.failure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context
                          .read<KelolaAkunCubit>()
                          .load(withOptions: true),
                    )
                  else if (state.isEmpty)
                    _EmptyState(hasFilter: state.roleFilter != null)
                  else ...[
                    for (final user in state.users)
                      ManagedUserCard(
                        user: user,
                        onEdit: () => _openForm(context, existing: user),
                        onToggleActive: () => _confirmToggle(context, user),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    const _StudentAccountNote(),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    if (hasFilter) {
      return const EmptyStateCard(
        icon: Icons.filter_alt_off_outlined,
        title: 'Tidak ada akun pada peran ini',
        description: 'Coba pilih "Semua" untuk melihat seluruh akun staf.',
      );
    }

    return const EmptyStateCard(
      icon: Icons.person_off_outlined,
      title: 'Belum ada akun dosen atau kaprodi',
      description:
          'Selama daftar ini kosong, mahasiswa yang mendaftar tidak akan '
          'memiliki dosen pembimbing, dan tidak ada seorang pun yang menerima '
          'peringatan dini dari sistem.',
      footnote: 'Buat akun dosen terlebih dahulu, lalu serahkan kredensial '
          'awalnya lewat jalur pribadi.',
    );
  }
}

/// Menjelaskan ketiadaan mahasiswa di daftar ini sebagai keputusan, bukan bug.
class _StudentAccountNote extends StatelessWidget {
  const _StudentAccountNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.creamAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.warmTextMuted),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Akun mahasiswa tidak muncul di sini. Mereka mendaftar sendiri, '
              'dan Admin tidak membutuhkan direktori mahasiswa untuk '
              'menjalankan tugasnya.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
