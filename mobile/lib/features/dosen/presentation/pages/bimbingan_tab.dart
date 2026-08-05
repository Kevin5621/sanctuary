import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../domain/entities/advisee.dart';
import '../cubit/bimbingan_cubit.dart';
import 'student_detail_page.dart';

/// Tab Bimbingan (L-BIM-01..03, L-BIM-05).
///
/// Peran dosen di sini adalah PEMANTAU, bukan pembaca: layar ini hanya
/// menampilkan hasil hitungan dan permintaan eksplisit mahasiswa. Tidak ada
/// tombol mengirim pesan — kontak dilakukan di luar aplikasi (PRD §3.3).
class DosenBimbinganTab extends StatelessWidget {
  const DosenBimbinganTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BimbinganCubit(context.read<MentorRepository>())..load(),
      child: const _BimbinganView(),
    );
  }
}

class _BimbinganView extends StatelessWidget {
  const _BimbinganView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<BimbinganCubit, BimbinganState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<BimbinganCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  SectionHeader(
                    title: 'Daftar Bimbingan',
                    subtitle: 'Diurutkan dari yang paling perlu disapa',
                    trailing: state.status == BimbinganStatus.ready
                        ? WavyBadge(
                            text: '${state.totalAdvisees} Mahasiswa',
                            color: AppColors.lavenderBg,
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.isLoading)
                    const LoadingState(label: 'Memuat daftar bimbingan…')
                  else if (state.status == BimbinganStatus.failure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context.read<BimbinganCubit>().load(),
                    )
                  else ...[
                    // Permintaan dihubungi tampil paling atas: ini satu-satunya
                    // kanal di mana mahasiswa yang memulai (D-7).
                    if (state.hasContactRequests) ...[
                      _ContactRequestSection(requests: state.contactRequests),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    if (state.isEmpty)
                      const EmptyStateCard(
                        icon: Icons.groups_outlined,
                        title: 'Belum ada mahasiswa bimbingan',
                        description:
                            'Belum ada mahasiswa yang ditetapkan sebagai bimbingan '
                            'Anda. Hubungi bagian akademik bila ini tidak sesuai.',
                      )
                    else ...[
                      const _ListLegend(),
                      const SizedBox(height: AppSpacing.md),
                      for (final advisee in state.advisees)
                        _AdviseeCard(advisee: advisee),
                    ],
                  ],

                  // Ruang untuk floating bottom navbar.
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

// ------------------------------------------------------------------
// L-BIM-03 — daftar "minta dihubungi": NAMA & WAKTU SAJA
// ------------------------------------------------------------------

class _ContactRequestSection extends StatelessWidget {
  const _ContactRequestSection({required this.requests});

  final List<ContactRequest> requests;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      color: AppColors.moodAngerBg,
      borderColor: AppColors.ewsIntervention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pan_tool_alt_rounded,
                  color: AppColors.ewsIntervention, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Minta dihubungi (${requests.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Mahasiswa berikut secara aktif meminta dihubungi. '
            'Anda menerima nama dan waktunya saja — alasannya mereka sampaikan '
            'sendiri saat Anda menyapa.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final request in requests)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 18, color: AppColors.midnight),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.midnight,
                          ),
                        ),
                        Text(
                          [
                            if (request.studentNumber != null)
                              'NIM ${request.studentNumber}',
                            _formatDateTime(request.requestedAt),
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.warmTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Kartu satu mahasiswa bimbingan
// ------------------------------------------------------------------

class _AdviseeCard extends StatelessWidget {
  const _AdviseeCard({required this.advisee});

  final Advisee advisee;

  @override
  Widget build(BuildContext context) {
    final isClosed = advisee.shareLevel.isClosed;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: advisee.hasOpenContactRequest
              ? AppColors.ewsIntervention
              : AppColors.cartoonBorder,
          width: advisee.hasOpenContactRequest ? 2 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudentDetailPage(
                studentId: advisee.studentId,
                fallbackName: advisee.fullName,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(name: advisee.fullName, level: advisee.ewsLevel),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            advisee.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.midnight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitleFor(advisee),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.warmTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.warmTextMuted),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // L-BIM-05: mahasiswa tanpa EWS TIDAK ditandai "Normal".
                    // Badge-nya menyebut apa adanya bahwa datanya tidak dibagikan.
                    if (advisee.hasEws)
                      EwsLevelBadge(
                        level: advisee.ews!.level,
                        label: advisee.ews!.levelLabel,
                      )
                    else if (isClosed)
                      const WavyBadge(
                        text: '🔒 Tidak berbagi',
                        color: AppColors.creamAlt,
                        borderColor: AppColors.warmTextMuted,
                        textColor: AppColors.warmTextSecondary,
                      )
                    else
                      const WavyBadge(
                        text: '🔕 Peringatan dini nonaktif',
                        color: AppColors.creamAlt,
                        borderColor: AppColors.warmTextMuted,
                        textColor: AppColors.warmTextSecondary,
                      ),

                    if (advisee.hasOpenContactRequest)
                      const WavyBadge(
                        text: '✋ Minta dihubungi',
                        color: AppColors.moodAngerBg,
                        borderColor: AppColors.ewsIntervention,
                        textColor: AppColors.ewsIntervention,
                      ),

                    WavyBadge(
                      text: advisee.shareLevelLabel,
                      color: AppColors.lavenderBg,
                      borderColor: AppColors.lavenderDark,
                      textColor: AppColors.lavenderDark,
                    ),
                  ],
                ),

                // Alasan data tidak tampil dinyatakan terus terang, memakai
                // kalimat dari server supaya sama persis dengan aturan yang
                // ditegakkan backend.
                if (advisee.privacyNotice?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClosedShareCard(notice: advisee.privacyNotice, compact: true),
                ],

                // Indikator yang menyala — membantu dosen tahu APA yang perlu
                // disapa, tanpa membuka satu kalimat pun tulisan mahasiswa.
                if (advisee.ews?.triggeredIndicators.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final indicator in advisee.ews!.triggeredIndicators)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.creamAlt,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: Text(
                            indicator.label,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warmTextSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _subtitleFor(Advisee advisee) {
    final parts = <String>[
      if (advisee.studentNumber != null) 'NIM ${advisee.studentNumber}',
      if (advisee.cohortYear != null) 'Angkatan ${advisee.cohortYear}',
    ];

    // Tanggal check-in terakhir hanya ada bila mahasiswa berbagi indikator.
    // Saat tidak ada, jangan menulis "belum pernah check-in" — kita tidak tahu
    // itu, yang kita tahu hanya bahwa datanya tidak dibagikan.
    if (advisee.lastCheckinDate != null) {
      parts.add('Check-in ${_formatDate(advisee.lastCheckinDate!)}');
    }
    return parts.isEmpty ? 'Mahasiswa bimbingan' : parts.join(' · ');
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.level});

  final String name;
  final String? level;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final color = level == null
        ? AppColors.warmTextMuted
        : AppColors.ewsLevel(level);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.8),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.midnight,
          ),
        ),
      ),
    );
  }
}

class _ListLegend extends StatelessWidget {
  const _ListLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.lavenderBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lavenderDark, width: 1.2),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.lavenderDark),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Anda melihat hasil hitungan, bukan tulisan mahasiswa. '
              'Jurnal dan percakapan Terapis AI tidak dapat dibuka siapa pun '
              'selain pemiliknya.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.midnight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Format tanggal — dibiarkan sederhana & tanpa locale eksternal supaya
// tidak memerlukan inisialisasi intl di seluruh aplikasi.
// ------------------------------------------------------------------

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _formatDate(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;

  final now = DateTime.now();
  final date = DateTime(parsed.year, parsed.month, parsed.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(date).inDays;

  if (diff == 0) return 'hari ini';
  if (diff == 1) return 'kemarin';
  if (diff > 1 && diff < 7) return '$diff hari lalu';
  return '${date.day} ${_monthNames[date.month - 1]}';
}

String _formatDateTime(String isoDateTime) {
  final parsed = DateTime.tryParse(isoDateTime);
  if (parsed == null) return isoDateTime;

  final local = parsed.toLocal();
  final time =
      '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';
  return '${_formatDate(isoDateTime)}, $time';
}
