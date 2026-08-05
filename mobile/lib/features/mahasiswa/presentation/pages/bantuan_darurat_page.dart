import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../../support/data/repositories/emergency_contact_repository.dart';
import '../../../support/domain/entities/emergency_contact.dart';
import '../../../support/presentation/cubit/emergency_contact_cubit.dart';

/// Layar Bantuan Darurat (M-PRO-04, A-BAN-02..04).
///
/// Seluruh nomor berasal dari server. Layar ini TIDAK PERNAH memuat nomor
/// bawaan sebagai cadangan: bila Admin belum mengatur apa pun, yang tampil
/// adalah pengakuan jujur "nomor layanan belum diatur" (A-BAN-03). Nomor
/// tebakan yang ternyata sudah mati lebih berbahaya daripada tidak ada nomor —
/// orang yang menekannya sedang tidak dalam keadaan bisa mencari alternatif.
class BantuanDaruratPage extends StatelessWidget {
  const BantuanDaruratPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EmergencyContactCubit(context.read<EmergencyContactRepository>())
            ..load(),
      child: const _BantuanDaruratView(),
    );
  }
}

class _BantuanDaruratView extends StatelessWidget {
  const _BantuanDaruratView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        backgroundColor: AppColors.creamBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.midnight,
        title: const Text(
          'Layanan Bantuan Darurat',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.midnight,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<EmergencyContactCubit, EmergencyContactState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<EmergencyContactCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const _UrgentBanner(),
                  const SizedBox(height: AppSpacing.md),

                  if (state.isLoading)
                    const LoadingState(label: 'Memuat nomor layanan…')
                  else if (state.status == ContactStatus.failure)
                    ErrorStateCard(
                      title: 'Gagal memuat nomor layanan',
                      message: state.errorMessage ??
                          'Periksa koneksi internetmu lalu coba lagi.',
                      onRetry: () => context.read<EmergencyContactCubit>().load(),
                    )
                  else if (state.isEmpty)
                    // A-BAN-03 — jujur, bukan nomor tebakan.
                    const _NoServiceConfiguredCard()
                  else
                    for (final contact in state.activeContacts)
                      _ContactCard(contact: contact),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner();

  @override
  Widget build(BuildContext context) {
    return const StateCard(
      color: AppColors.moodAngerBg,
      borderColor: AppColors.ewsIntervention,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_rounded,
              color: AppColors.ewsIntervention, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kalau kamu sedang merasa tidak aman dengan dirimu sendiri, '
              'kamu tidak harus menghadapinya sendirian. Hubungi salah satu '
              'nomor di bawah ini.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.midnight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A-BAN-03 — daftar kosong.
///
/// Sengaja tidak menawarkan nomor apa pun, termasuk 119 atau 112 sebagai
/// "cadangan yang pasti benar": begitu klien punya satu nomor bawaan, nomor itu
/// akan tetap tampil bertahun-tahun setelah tidak ada yang memeriksanya lagi.
class _NoServiceConfiguredCard extends StatelessWidget {
  const _NoServiceConfiguredCard();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      icon: Icons.phone_disabled_outlined,
      title: 'Nomor layanan belum diatur',
      description:
          'Administrator kampus belum mengatur daftar nomor layanan bantuan. '
          'Kamu tetap bisa menghubungi dosen pembimbing atau unit konseling '
          'kampus lewat jalur yang biasa kamu pakai.',
      footnote: 'Aplikasi ini tidak menampilkan nomor yang belum dipastikan '
          'masih aktif — menelepon nomor mati saat sedang butuh bantuan akan '
          'lebih menyakitkan daripada membantu.',
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final EmergencyContact contact;

  Future<void> _copyNumber(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: contact.dialNumber));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Nomor ${contact.phone} disalin'),
          backgroundColor: AppColors.midnight,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return StateCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  contact.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              if (contact.is24Hours)
                const WavyBadge(
                  text: '24 jam',
                  color: AppColors.moodDisgustBg,
                  borderColor: AppColors.ewsNormal,
                ),
            ],
          ),
          if (contact.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              contact.description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
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
              // A-BAN-04 — status verifikasi juga terlihat mahasiswa.
              // Menyembunyikannya berarti menyajikan nomor yang belum
              // dipastikan seolah-olah sudah pasti benar.
              if (contact.needsVerification) const VerificationBadge(dense: true),
            ],
          ),
          if (contact.needsVerification) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Nomor ini belum diverifikasi ulang oleh pihak kampus. '
              'Bila tidak tersambung, coba nomor lain pada daftar ini.',
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: AppColors.ewsIntervention,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => _copyNumber(context),
            icon: const Icon(Icons.content_copy_rounded, size: 17),
            label: Text('Salin ${contact.phone}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midnight,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
