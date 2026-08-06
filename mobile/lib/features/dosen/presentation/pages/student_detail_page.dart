import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../domain/entities/advisor_note.dart';
import '../../domain/entities/advisee.dart';
import '../cubit/student_detail_cubit.dart';

/// Halaman detail mahasiswa (L-BIM-04) berformat TAB:
///   Section 1: Informasi General
///   Section 2: Tab Bar (Kondisi & Indikator vs Riwayat Pendampingan) tanpa border.
class StudentDetailPage extends StatelessWidget {
  const StudentDetailPage({
    super.key,
    required this.studentId,
    this.fallbackName,
  });

  final String studentId;
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StudentDetailCubit(context.read<MentorRepository>(), studentId)..load(),
      child: _StudentDetailView(studentId: studentId, fallbackName: fallbackName),
    );
  }
}

class _StudentDetailView extends StatefulWidget {
  const _StudentDetailView({required this.studentId, this.fallbackName});

  final String studentId;
  final String? fallbackName;

  @override
  State<_StudentDetailView> createState() => _StudentDetailViewState();
}

class _StudentDetailViewState extends State<_StudentDetailView> {
  List<AdvisorNote> _advisorNotes = [];
  bool _isLoadingNotes = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoadingNotes = true);
    try {
      final repo = context.read<MentorRepository>();
      final notes = await repo.fetchAdvisorNotes(widget.studentId);
      if (mounted) {
        setState(() {
          _advisorNotes = notes;
          _isLoadingNotes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingNotes = false);
    }
  }

  Future<void> _addNote(String channel, String status, String remark) async {
    try {
      final repo = context.read<MentorRepository>();
      final newNote = await repo.createAdvisorNote(
        studentId: widget.studentId,
        channel: channel,
        status: status,
        remark: remark,
      );
      if (mounted) {
        setState(() {
          _advisorNotes = [newNote, ..._advisorNotes];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan pendampingan berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan catatan pendampingan')),
        );
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      final repo = context.read<MentorRepository>();
      await repo.deleteAdvisorNote(studentId: widget.studentId, noteId: noteId);
      if (mounted) {
        setState(() {
          _advisorNotes.removeWhere((n) => n.id == noteId);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.creamBg,
        appBar: AppBar(
          backgroundColor: AppColors.creamBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.midnight,
          title: BlocBuilder<StudentDetailCubit, StudentDetailState>(
            builder: (context, state) => Text(
              state.indicator?.fullName ?? widget.fallbackName ?? 'Detail Mahasiswa',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.midnight,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<StudentDetailCubit, StudentDetailState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const LoadingState(label: 'Memuat indikator…');
              }

              if (state.status == StudentDetailStatus.failure) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ErrorStateCard(
                    title: state.isForbidden
                        ? 'Tidak dapat diakses'
                        : 'Gagal memuat indikator',
                    message: state.errorMessage ??
                        'Periksa koneksi internet Anda lalu coba lagi.',
                    onRetry: state.isForbidden
                        ? null
                        : () => context.read<StudentDetailCubit>().load(),
                  ),
                );
              }

              final indicator = state.indicator;
              if (indicator == null) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: EmptyStateCard(
                    title: 'Data tidak tersedia',
                    description: 'Tidak ada indikator yang dapat ditampilkan.',
                  ),
                );
              }

              return Column(
                children: [
                  // ---- Section 1: Informasi General ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: _IdentityCard(indicator: indicator),
                  ),
                  const SizedBox(height: 6),

                  // ---- Section 2: Tab Bar (Tanpa Border) ----
                  const TabBar(
                    indicatorColor: AppColors.midnight,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 3,
                    dividerColor: Colors.transparent, // Hapus garis border pembatas
                    labelColor: AppColors.midnight,
                    unselectedLabelColor: AppColors.warmTextSecondary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                    tabs: [
                      Tab(text: 'Kondisi & Indikator'),
                      Tab(text: 'Riwayat Pendampingan'),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // ---- TabBarView Content ----
                  Expanded(
                    child: TabBarView(
                      children: [
                        // TAB 1: Kondisi & Indikator
                        ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            if (indicator.shareLevel.isClosed) ...[
                              ClosedShareCard(
                                studentName: indicator.fullName,
                                notice: indicator.privacyNotice,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _NoIndicatorExplanation(),
                            ] else ...[
                              // Status EWS
                              if (indicator.ews != null) ...[
                                _EwsCard(ews: indicator.ews!),
                                const SizedBox(height: AppSpacing.md),
                              ] else ...[
                                EarlyWarningOffCard(notice: indicator.privacyNotice),
                                const SizedBox(height: AppSpacing.md),
                              ],

                              // Indikator kondisi
                              if (indicator.summary != null) ...[
                                _SummaryCard(summary: indicator.summary!),
                                const SizedBox(height: AppSpacing.md),
                              ],

                              // Grafik tren dengan Academic Markers
                              if (indicator.hasTrend)
                                _TrendCard(points: indicator.trend)
                              else
                                _TrendUnavailableCard(shareLevel: indicator.shareLevel),
                            ],

                            const SizedBox(height: 80),
                          ],
                        ),

                        // TAB 2: Riwayat Pendampingan (History UI)
                        _AdvisorNotesHistoryTab(
                          studentName: indicator.fullName,
                          notes: _advisorNotes,
                          isLoading: _isLoadingNotes,
                          onAddNote: () => _showAddNoteSheet(context),
                          onDeleteNote: _deleteNote,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddNoteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddNoteSheet(
          onSubmit: (channel, status, remark) {
            Navigator.pop(context);
            _addNote(channel, status, remark);
          },
        );
      },
    );
  }
}

// ------------------------------------------------------------------
// TAB 2: Riwayat Pendampingan (History UI Component)
// ------------------------------------------------------------------

class _AdvisorNotesHistoryTab extends StatelessWidget {
  const _AdvisorNotesHistoryTab({
    required this.studentName,
    required this.notes,
    required this.isLoading,
    required this.onAddNote,
    required this.onDeleteNote,
  });

  final String studentName;
  final List<AdvisorNote> notes;
  final bool isLoading;
  final VoidCallback onAddNote;
  final ValueChanged<String> onDeleteNote;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Top Action Bar
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Pendampingan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.midnight,
                    ),
                  ),
                  Text(
                    'Jejak bimbingan privat Anda untuk $studentName',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warmTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onAddNote,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Catat', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midnight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(30),
            child: LoadingState(label: 'Memuat riwayat pendampingan…'),
          )
        else if (notes.isEmpty)
          const EmptyStateCard(
            icon: Icons.history_rounded,
            title: 'Belum Ada Riwayat Pendampingan',
            description:
                'Anda belum mencatat hasil bimbingan/sapaan untuk mahasiswa ini. Tekan tombol "+ Catat" untuk menambahkan catatan baru.',
          )
        else
          // Timeline List of Notes
          for (int i = 0; i < notes.length; i++)
            _TimelineHistoryCard(
              note: notes[i],
              isLast: i == notes.length - 1,
              onDelete: () => onDeleteNote(notes[i].id),
            ),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _TimelineHistoryCard extends StatelessWidget {
  const _TimelineHistoryCard({
    required this.note,
    required this.isLast,
    required this.onDelete,
  });

  final AdvisorNote note;
  final bool isLast;
  final VoidCallback onDelete;

  IconData _channelIcon(String channel) {
    switch (channel) {
      case 'TATAP_MUKA':
        return Icons.record_voice_over_rounded;
      case 'WHATSAPP':
        return Icons.chat_bubble_outline_rounded;
      case 'EMAIL':
        return Icons.mail_outline_rounded;
      case 'TELEPON':
        return Icons.phone_outlined;
      default:
        return Icons.bookmark_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator Bar
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.lavenderBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lavenderDark, width: 1.5),
                ),
                child: Icon(
                  _channelIcon(note.channel),
                  size: 16,
                  color: AppColors.midnight,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.cartoonBorder,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cartoonShadow,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      WavyBadge(
                        text: note.channelLabel,
                        color: AppColors.lavenderBg,
                      ),
                      const SizedBox(width: 6),
                      WavyBadge(
                        text: note.statusLabel,
                        color: AppColors.moodHappinessBg,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.warmTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.remark,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 13, color: AppColors.warmTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                        note.interactionDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warmTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Bottom Sheet Form for Adding Advisor Note
// ------------------------------------------------------------------

class _AddNoteSheet extends StatefulWidget {
  const _AddNoteSheet({required this.onSubmit});

  final Function(String channel, String status, String remark) onSubmit;

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  String _selectedChannel = 'TATAP_MUKA';
  String _selectedStatus = 'DISAPA';
  final _remarkController = TextEditingController();

  final _channels = [
    ('TATAP_MUKA', 'Tatap Muka'),
    ('WHATSAPP', 'WhatsApp'),
    ('EMAIL', 'Email'),
    ('TELEPON', 'Telepon'),
    ('LAINNYA', 'Lainnya'),
  ];

  final _statuses = [
    ('DISAPA', 'Telah Disapa'),
    ('KONSULTASI', 'Konsultasi'),
    ('DIRUJUK', 'Dirujuk Kampus'),
    ('STABIL', 'Kondisi Membaik'),
  ];

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Catatan Pendampingan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16.5,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Catatan ini khusus untuk Anda sebagai pengingat pendampingan.',
            style: TextStyle(fontSize: 11.5, color: AppColors.warmTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          const Text('Media Komunikasi:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _channels.map((c) {
              final isSel = _selectedChannel == c.$1;
              return ChoiceChip(
                showCheckmark: false,
                label: Text(c.$2, style: const TextStyle(fontSize: 11)),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedChannel = c.$1),
                selectedColor: AppColors.midnight,
                labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.midnight),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.md),
          const Text('Status Pendampingan:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _statuses.map((s) {
              final isSel = _selectedStatus == s.$1;
              return ChoiceChip(
                showCheckmark: false,
                label: Text(s.$2, style: const TextStyle(fontSize: 11)),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedStatus = s.$1),
                selectedColor: AppColors.midnight,
                labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.midnight),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _remarkController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tuliskan catatan hasil sapaan / bimbingan…',
              hintStyle: const TextStyle(fontSize: 12.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final text = _remarkController.text.trim();
                if (text.isEmpty) return;
                widget.onSubmit(_selectedChannel, _selectedStatus, text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midnight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text('Simpan Catatan',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Sub-components: Identity, EWS, Summary, Trend Cards
// ------------------------------------------------------------------

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.indicator});

  final StudentIndicator indicator;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lavenderBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.midnight, width: 1.8),
                ),
                child: Center(
                  child: Text(
                    indicator.fullName.trim().isEmpty
                        ? '?'
                        : indicator.fullName.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indicator.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.midnight,
                      ),
                    ),
                    if (indicator.studentNumber != null)
                      Text(
                        'NIM ${indicator.studentNumber}',
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
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              WavyBadge(
                text: 'Berbagi: ${indicator.shareLevelLabel}',
                color: AppColors.lavenderBg,
                borderColor: AppColors.lavenderDark,
                textColor: AppColors.lavenderDark,
              ),
              if (indicator.hasOpenContactRequest)
                const WavyBadge(
                  text: '✋ Minta dihubungi',
                  color: AppColors.moodAngerBg,
                  borderColor: AppColors.ewsIntervention,
                  textColor: AppColors.ewsIntervention,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EwsCard extends StatelessWidget {
  const _EwsCard({required this.ews});

  final EwsSummary ews;

  @override
  Widget build(BuildContext context) {
    if (!ews.isSufficient) {
      return StateCard(
        color: AppColors.creamAlt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EwsLevelBadge(level: ews.level, label: ews.levelLabel),
                const Spacer(),
                Text(
                  '${ews.dataPoints} check-in / ${ews.windowDays} hari',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warmTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Titik data harian belum cukup untuk menyimpulkan tingkat perhatian.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final color = AppColors.ewsLevel(ews.level);

    return StateCard(
      borderColor: color,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tingkat Perhatian',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: AppColors.midnight,
                ),
              ),
              const Spacer(),
              EwsLevelBadge(level: ews.level, label: ews.levelLabel),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Skor ${ews.score} · dari ${ews.dataPoints} check-in (${ews.windowDays} hari)',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final indicator in ews.indicators)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    indicator.triggered
                        ? Icons.error_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: indicator.triggered
                        ? AppColors.ewsRisk
                        : AppColors.ewsNormal,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          indicator.label,
                          style: TextStyle(
                            fontWeight: indicator.triggered
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12.5,
                            color: AppColors.midnight,
                          ),
                        ),
                        Text(
                          indicator.detail,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.3,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ConditionSummary summary;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indikator ${summary.windowDays} Hari Terakhir',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              color: AppColors.midnight,
            ),
          ),
          Text(
            'Dihitung dari ${summary.checkinCount} check-in',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Rata-rata mood',
                  value: summary.avgMood.toStringAsFixed(1),
                  unit: '/ 5',
                  color: AppColors.moodHappinessBg,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'Rata-rata stres',
                  value: summary.avgStress.toStringAsFixed(1),
                  unit: '/ 5',
                  color: AppColors.moodAngerBg,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'Rata-rata tidur',
                  value: summary.avgSleepHours.toStringAsFixed(1),
                  unit: 'jam',
                  color: AppColors.moodSadnessBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: AppColors.midnight,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: AppColors.warmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});

  final List<WeeklyTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tren Mingguan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: AppColors.midnight,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.creamAlt,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: AppColors.cartoonBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.event_outlined, size: 11, color: AppColors.warmTextSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Milestone Akademik',
                      style: TextStyle(fontSize: 10, color: AppColors.warmTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Academic Context Overlay Chips
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AcademicMarkerChip(label: '📍 M7: UTS'),
                SizedBox(width: 6),
                _AcademicMarkerChip(label: '📍 M14: Skripsi/Batas Tugas'),
                SizedBox(width: 6),
                _AcademicMarkerChip(label: '📍 M16: UAS'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minY: 1,
                maxY: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.cartoonBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.warmTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _weekLabel(points[index].weekStart),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.warmTextSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _line(points.map((p) => p.avgMood).toList(),
                      AppColors.moodHappiness),
                  _line(points.map((p) => p.avgStress).toList(),
                      AppColors.moodAnger),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              _LegendDot(color: AppColors.moodHappiness, label: 'Mood'),
              SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.moodAnger, label: 'Stres'),
            ],
          ),
        ],
      ),
    );
  }

  static LineChartBarData _line(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
    );
  }

  static String _weekLabel(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return '';
    return '${parsed.day}/${parsed.month}';
  }
}

class _AcademicMarkerChip extends StatelessWidget {
  const _AcademicMarkerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.creamAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.cartoonBorder, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.midnight,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.warmTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _TrendUnavailableCard extends StatelessWidget {
  const _TrendUnavailableCard({required this.shareLevel});

  final ShareLevel shareLevel;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.show_chart_rounded,
      title: 'Grafik tren tidak dibagikan',
      description: shareLevel == ShareLevel.summary
          ? 'Mahasiswa memilih tingkat berbagi Ringkasan, sehingga grafik tren mingguan tidak dikirim.'
          : 'Belum ada titik tren yang dapat ditampilkan untuk periode ini.',
    );
  }
}

class _NoIndicatorExplanation extends StatelessWidget {
  const _NoIndicatorExplanation();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      icon: Icons.visibility_off_outlined,
      title: 'Tidak ada indikator untuk ditampilkan',
      description:
          'Karena mahasiswa memilih tingkat berbagi Tertutup, tidak ada indikator kondisi yang dikirim kepada Anda.',
    );
  }
}
