import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../support/data/repositories/emergency_contact_repository.dart';
import '../../../support/domain/entities/emergency_contact.dart';
import '../../../support/presentation/cubit/emergency_contact_cubit.dart';

/// Layar "Butuh Bantuan Sekarang" untuk mahasiswa (baca saja).
///
/// Daftar layanan berasal dari konfigurasi Admin. Tidak ada nomor cadangan
/// yang ditanam di aplikasi: nomor krisis yang salah lebih berbahaya daripada
/// mengaku belum ada.
class BantuanDaruratPage extends StatelessWidget {
  const BantuanDaruratPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EmergencyContactCubit(context.read<EmergencyContactRepository>())..load(),
      child: const _BantuanView(),
    );
  }
}

class _BantuanView extends StatelessWidget {
  const _BantuanView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(title: const Text('Butuh Bantuan Sekarang'), elevation: 0),
      body: BlocBuilder<EmergencyContactCubit, EmergencyContactState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.midnight));
          }

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
                if (state.status == ContactStatus.failure)
                  _ErrorCard(message: state.errorMessage)
                else if (state.isEmpty)
                  const _NotConfiguredCard()
                else
                  // activeContacts: server sudah menyaring untuk peran non-Admin,
                  // pemanggilan ini hanya menjaga kalau nanti layar ini dipakai
                  // ulang oleh peran yang menerima baris nonaktif.
                  for (final contact in state.activeContacts) _ContactCard(contact: contact),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.moodAngerBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.ewsIntervention, width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.favorite_rounded, color: AppColors.ewsIntervention, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kalau kamu atau seseorang yang kamu kenal sedang dalam bahaya, '
              'hubungi salah satu layanan di bawah ini sekarang.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.midnight,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
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
              WavyBadge(
                text: contact.is24Hours ? 'Tersedia 24 jam' : 'Jam layanan terbatas',
                color: contact.is24Hours ? AppColors.moodDisgustBg : AppColors.creamAlt,
              ),
            ],
          ),
          if (contact.serviceTypeLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              contact.serviceTypeLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ],
          if (contact.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              contact.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warmTextSecondary,
                height: 1.35,
              ),
            ),
          ],

          // A-BAN-04: nomor yang belum diverifikasi tetap ditampilkan, tetapi
          // ditandai. Menyembunyikannya membuat mahasiswa mengira tidak ada
          // bantuan; menampilkannya tanpa peringatan berisiko menyesatkan.
          if (contact.needsVerification) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.moodAngerBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.ewsRisk),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nomor ini belum diverifikasi pengelola.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midnight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => _copyNumber(context, contact.phone),
            icon: const Icon(Icons.phone_rounded, size: 18),
            label: Text(contact.phone),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midnight,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyNumber(BuildContext context, String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Nomor $phone disalin')));
  }
}

/// A-BAN-03 — Admin belum mengatur satu pun layanan.
///
/// Ini bukan error: server menjawab dengan benar dan isinya memang kosong.
/// Nomor nasional disebut sebagai penjelasan darurat, bukan sebagai daftar
/// bawaan yang berpura-pura menjadi konfigurasi kampus.
class _NotConfiguredCard extends StatelessWidget {
  const _NotConfiguredCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: const Column(
        children: [
          Icon(Icons.phone_disabled_rounded, size: 40, color: AppColors.warmTextMuted),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Nomor layanan belum diatur',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.midnight,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pengelola aplikasi belum mengisi daftar layanan bantuan. '
            'Untuk keadaan darurat, hubungi 119 ekstensi 8 (SEJIWA) atau 112.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.warmTextSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message ?? 'Gagal memuat daftar layanan.',
            style: const TextStyle(fontSize: 13, color: AppColors.midnight),
          ),
          const SizedBox(height: 6),
          const Text(
            'Untuk keadaan darurat sekarang: 119 ekstensi 8 (SEJIWA) atau 112.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => context.read<EmergencyContactCubit>().load(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.midnight,
              side: const BorderSide(color: AppColors.midnight, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
