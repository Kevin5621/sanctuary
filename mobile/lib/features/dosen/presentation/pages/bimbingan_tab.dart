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
/// Tampilan modern, minimalis, dan berfokus aksi harian dosen.
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

class _BimbinganView extends StatefulWidget {
  const _BimbinganView();

  @override
  State<_BimbinganView> createState() => _BimbinganViewState();
}

class _BimbinganViewState extends State<_BimbinganView> {
  // Default filter: Perlu Intervensi
  String _selectedFilter = 'INTERVENTION';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<BimbinganCubit, BimbinganState>(
          builder: (context, state) {
            final advisees = state.advisees;

            final contactCount = state.contactRequests.length;
            final interventionCount = advisees.where((a) {
              final level = a.ews?.level;
              return level == 'INTERVENTION' || level == 'RISK';
            }).length;

            // Saring daftar berdasarkan filter chip aktif
            final filteredAdvisees = advisees.where((a) {
              if (_selectedFilter == 'CONTACT') return a.hasOpenContactRequest;
              if (_selectedFilter == 'INTERVENTION') {
                final level = a.ews?.level;
                return level == 'INTERVENTION' || level == 'RISK';
              }
              if (_selectedFilter == 'LOW_SLEEP') {
                return a.ews?.triggeredIndicators.any((i) => i.code == 'LOW_SLEEP_NIGHTS') ?? false;
              }
              if (_selectedFilter == 'CLOSED') {
                return a.shareLevel.isClosed;
              }
              return true;
            }).toList();

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
                    subtitle: 'Pemantauan kondisi & tindakan pendampingan',
                    trailing: state.status == BimbinganStatus.ready
                        ? WavyBadge(
                            text: '${state.totalAdvisees} Mahasiswa',
                            color: AppColors.lavenderBg,
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (state.isLoading)
                    const LoadingState(label: 'Memuat daftar bimbingan…')
                  else if (state.status == BimbinganStatus.failure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context.read<BimbinganCubit>().load(),
                    )
                  else ...[
                    // ---- Smart Filter Chips (Tanpa Checkmark, Default INTERVENTION) ----
                    _FilterChips(
                      selected: _selectedFilter,
                      onSelect: (filter) => setState(() => _selectedFilter = filter),
                      totalCount: advisees.length,
                      contactCount: contactCount,
                      interventionCount: interventionCount,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ---- Section Minta Dihubungi (Hanya bila filter ALL atau CONTACT) ----
                    if (state.hasContactRequests &&
                        (_selectedFilter == 'ALL' || _selectedFilter == 'CONTACT')) ...[
                      _ContactRequestSection(requests: state.contactRequests),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ---- Empty State jika filter kosong ----
                    if (filteredAdvisees.isEmpty)
                      EmptyStateCard(
                        icon: Icons.check_circle_outline_rounded,
                        title: _selectedFilter == 'INTERVENTION'
                            ? 'Semua Mahasiswa Stabil'
                            : 'Tidak Ada Data',
                        description: _selectedFilter == 'INTERVENTION'
                            ? 'Tidak ada mahasiswa yang membutuhkan intervensi saat ini.'
                            : 'Tidak ada mahasiswa sesuai filter yang dipilih.',
                      )
                    else
                      for (final advisee in filteredAdvisees)
                        _AdviseeCard(advisee: advisee),
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

// ------------------------------------------------------------------
// Smart Filter Chips (Clean layout without checkmark)
// ------------------------------------------------------------------

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelect,
    required this.totalCount,
    required this.contactCount,
    required this.interventionCount,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final int totalCount;
  final int contactCount;
  final int interventionCount;

  @override
  Widget build(BuildContext context) {
    final chips = [
      ('INTERVENTION', '🔴 Perlu Intervensi ${interventionCount > 0 ? "($interventionCount)" : ""}'),
      ('CONTACT', '✋ Minta Dihubungi ${contactCount > 0 ? "($contactCount)" : ""}'),
      ('LOW_SLEEP', '🌙 Kurang Tidur'),
      ('CLOSED', '🔒 Privasi Tertutup'),
      ('ALL', 'Semua ($totalCount)'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final isSelected = selected == c.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              showCheckmark: false, // Hapus centang saat state aktif sesuai instruksi
              label: Text(c.$2.trim()),
              selected: isSelected,
              onSelected: (_) => onSelect(c.$1),
              selectedColor: AppColors.midnight,
              backgroundColor: AppColors.creamAlt,
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.midnight,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.midnight : AppColors.cartoonBorder,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Contact Request Section
// ------------------------------------------------------------------

class _ContactRequestSection extends StatelessWidget {
  const _ContactRequestSection({required this.requests});

  final List<ContactRequest> requests;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.moodAngerBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.ewsIntervention, width: 1.5),
      ),
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
                    fontSize: 15,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final request in requests)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.cartoonBorder, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 16, color: AppColors.midnight),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
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
                            fontSize: 11,
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
// Advisee Card Component
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
          width: advisee.hasOpenContactRequest ? 2 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 3),
            blurRadius: 6,
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
                              fontSize: 15.5,
                              color: AppColors.midnight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitleFor(advisee),
                            style: const TextStyle(
                              fontSize: 11,
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
                  spacing: 6,
                  runSpacing: 6,
                  children: [
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
                              fontSize: 10,
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
      width: 42,
      height: 42,
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
            fontSize: 16,
            color: AppColors.midnight,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Date Formatter Helpers
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
