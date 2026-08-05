import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../../support/data/repositories/emergency_contact_repository.dart';
import '../../../support/domain/entities/emergency_contact.dart';
import '../../../support/presentation/cubit/emergency_contact_cubit.dart';
import 'emergency_contact_form_page.dart';

/// Tab Bantuan Admin — CRUD layanan darurat (A-BAN-01..04).
class AdminBantuanTab extends StatelessWidget {
  const AdminBantuanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EmergencyContactCubit(context.read<EmergencyContactRepository>())
            ..load(withServiceTypes: true),
      child: const _BantuanView(),
    );
  }
}

class _BantuanView extends StatelessWidget {
  const _BantuanView();

  Future<void> _openForm(
    BuildContext context, {
    EmergencyContact? existing,
  }) {
    final cubit = context.read<EmergencyContactCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        // Cubit yang sama diteruskan agar daftar di belakang ikut segar
        // setelah simpan, tanpa perlu memuat ulang manual.
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: EmergencyContactFormPage(
            existing: existing,
            serviceTypes: cubit.state.serviceTypes,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final cubit = context.read<EmergencyContactCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus layanan?'),
        content: Text(
          '"${contact.name}" akan dihapus dan tidak lagi terlihat oleh '
          'siapa pun.\n\nBila Anda hanya ingin menyembunyikannya sementara, '
          'nonaktifkan saja — datanya tetap tersimpan.',
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await cubit.delete(contact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<EmergencyContactCubit, EmergencyContactState>(
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
            context.read<EmergencyContactCubit>().clearMessages();
          },
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<EmergencyContactCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  SectionHeader(
                    title: 'Layanan Bantuan',
                    subtitle: 'Nomor darurat & konseling untuk seluruh pengguna',
                    trailing: state.status == ContactStatus.ready
                        ? WavyBadge(
                            text: '${state.activeCount} aktif',
                            color: AppColors.moodDisgustBg,
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ElevatedButton.icon(
                    onPressed: state.serviceTypes.isEmpty
                        ? null
                        : () => _openForm(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah Layanan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.midnight,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
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

                  // A-BAN-04 — banner blocker rilis.
                  if (state.unverifiedCount > 0) ...[
                    _UnverifiedBanner(count: state.unverifiedCount),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (state.isLoading)
                    const LoadingState(label: 'Memuat daftar layanan…')
                  else if (state.status == ContactStatus.failure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context
                          .read<EmergencyContactCubit>()
                          .load(withServiceTypes: true),
                    )
                  else if (state.isEmpty)
                    const _AdminEmptyState()
                  else ...[
                    for (final contact in state.contacts)
                      _ContactCard(
                        contact: contact,
                        onEdit: () => _openForm(context, existing: contact),
                        onToggleActive: () => context
                            .read<EmergencyContactCubit>()
                            .toggleActive(contact),
                        onDelete: () => _confirmDelete(context, contact),
                      ),
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

/// A-BAN-04 — pengingat bahwa verifikasi nomor adalah blocker rilis.
class _UnverifiedBanner extends StatelessWidget {
  const _UnverifiedBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      color: AppColors.moodAngerBg,
      borderColor: AppColors.ewsIntervention,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_maybe_rounded,
                  size: 20, color: AppColors.ewsIntervention),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$count nomor belum diverifikasi',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Nomor bertanda [VERIFIKASI] masih berupa placeholder dari data '
            'awal. Telepon setiap nomor, pastikan tersambung ke layanan yang '
            'benar, lalu hapus penanda itu dari keterangannya.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ini blocker rilis — aplikasi tidak boleh naik produksi selama '
            'masih ada nomor yang belum dipastikan.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.ewsIntervention,
            ),
          ),
        ],
      ),
    );
  }
}

/// A-BAN-03 dari sisi Admin: menjelaskan konsekuensi daftar kosong.
class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      icon: Icons.phone_disabled_outlined,
      title: 'Belum ada layanan bantuan',
      description:
          'Selama daftar ini kosong, mahasiswa yang membuka layar bantuan '
          'darurat akan melihat "nomor layanan belum diatur".',
      footnote: 'Aplikasi sengaja tidak menampilkan nomor bawaan apa pun: '
          'nomor tebakan yang ternyata sudah mati lebih berbahaya daripada '
          'mengaku belum ada.',
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      // Baris nonaktif diredupkan supaya Admin langsung melihat mana yang
      // sedang tidak terlihat oleh peran lain (A-BAN-02).
      opacity: contact.isActive ? 1 : 0.6,
      child: StateCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        borderColor: contact.needsVerification
            ? AppColors.ewsIntervention
            : AppColors.cartoonBorder,
        borderWidth: contact.needsVerification ? 2 : 1.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.call_outlined,
                              size: 14, color: AppColors.warmTextSecondary),
                          const SizedBox(width: 5),
                          Text(
                            contact.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warmTextSecondary,
                            ),
                          ),
                        ],
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
                    'delete' => onDelete(),
                    _ => null,
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        contact.isActive ? 'Nonaktifkan' : 'Aktifkan',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Hapus',
                        style: TextStyle(color: AppColors.ewsIntervention),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (contact.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                contact.description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.warmTextSecondary,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                WavyBadge(
                  text: contact.serviceTypeLabel,
                  color: AppColors.lavenderBg,
                  borderColor: AppColors.lavenderDark,
                  textColor: AppColors.lavenderDark,
                ),
                if (contact.is24Hours)
                  const WavyBadge(
                    text: '24 jam',
                    color: AppColors.moodDisgustBg,
                    borderColor: AppColors.ewsNormal,
                  ),
                WavyBadge(
                  text: contact.isActive ? 'Aktif' : 'Nonaktif',
                  color: contact.isActive
                      ? AppColors.moodDisgustBg
                      : AppColors.creamAlt,
                  borderColor: contact.isActive
                      ? AppColors.ewsNormal
                      : AppColors.warmTextMuted,
                  textColor: contact.isActive
                      ? AppColors.midnight
                      : AppColors.warmTextSecondary,
                ),
                if (contact.needsVerification) const VerificationBadge(dense: true),
              ],
            ),

            if (!contact.isActive) ...[
              const SizedBox(height: AppSpacing.sm),
              const Row(
                children: [
                  Icon(Icons.visibility_off_outlined,
                      size: 14, color: AppColors.warmTextMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hanya Anda yang melihat entri ini. Mahasiswa, dosen, dan '
                      'kaprodi tidak menerimanya sama sekali.',
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
