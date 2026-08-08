import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/program_repository.dart';
import '../../domain/entities/program_dashboard.dart';
import '../cubit/kaprodi_cubit.dart';

/// Tab Pembimbing (K-PEM-01) — daftar dosen dan mahasiswa bimbingannya.
///
/// Jumlah dan alokasi bimbingan adalah data ADMINISTRATIF, bukan data wellbeing,
/// sehingga tidak tunduk k-anonymity dan ditampilkan apa adanya.
class KaprodiPembimbingTab extends StatelessWidget {
  const KaprodiPembimbingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PembimbingCubit(context.read<ProgramRepository>())..load(),
      child: const _PembimbingView(),
    );
  }
}

class _PembimbingView extends StatelessWidget {
  const _PembimbingView();

  void _openManageSheet(BuildContext context, {String? preselectedAdvisorId}) {
    final cubit = context.read<PembimbingCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _KelolaBimbinganSheet(initialAdvisorId: preselectedAdvisorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      floatingActionButton: BlocBuilder<PembimbingCubit, PembimbingState>(
        builder: (context, state) {
          if (!state.status.isReady || state.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _openManageSheet(context),
            backgroundColor: AppColors.midnight,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.manage_accounts_rounded, size: 20),
            label: const Text(
              'Kelola Bimbingan',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          );
        },
      ),
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<PembimbingCubit, PembimbingState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.midnight,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<PembimbingCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<PembimbingCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  SectionHeader(
                    title: 'Dosen Pembimbing',
                    subtitle: 'Pengelolaan alokasi dosen dan mahasiswa bimbingan',
                    trailing: state.status.isReady
                        ? WavyBadge(
                            text: '${state.advisors.length} Dosen',
                            color: AppColors.lavenderBg,
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (state.status.isLoading)
                    const LoadingState(label: 'Memuat data bimbingan…')
                  else if (state.status.isFailure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context.read<PembimbingCubit>().load(),
                    )
                  else if (state.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.school_outlined,
                      title: 'Belum ada dosen pembimbing',
                      description:
                          'Belum ada dosen yang terdaftar pada program studi ini.',
                    )
                  else ...[
                    _SummaryHeader(state: state, onManageTap: () => _openManageSheet(context)),
                    const SizedBox(height: AppSpacing.md),
                    for (final advisor in state.advisors)
                      _AdvisorCard(
                        advisor: advisor,
                        onAddAdvisee: () => _openManageSheet(
                          context,
                          preselectedAdvisorId: advisor.advisorId,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    const _AdministrativeNote(),
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

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.state,
    required this.onManageTap,
  });

  final PembimbingState state;
  final VoidCallback onManageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _HeaderStatTile(
                  value: '${state.advisors.length}',
                  label: 'Dosen Pembimbing',
                  color: AppColors.lavenderBg,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderStatTile(
                  value: '${state.totalAdvisees}',
                  label: 'Total Mahasiswa',
                  color: AppColors.creamAlt,
                ),
              ),
              if (state.unassignedCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _HeaderStatTile(
                    value: '${state.unassignedCount}',
                    label: 'Belum Ada Dosen',
                    color: const Color(0xFFFFF3E0),
                    isWarning: true,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onManageTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.midnight,
                side: const BorderSide(color: AppColors.midnight, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              icon: const Icon(Icons.group_add_rounded, size: 18),
              label: const Text(
                'Kelola Mahasiswa Bimbingan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatTile extends StatelessWidget {
  const _HeaderStatTile({
    required this.value,
    required this.label,
    required this.color,
    this.isWarning = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isWarning ? const Color(0xFFFB8C00) : AppColors.cartoonBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: isWarning ? const Color(0xFFE65100) : AppColors.midnight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.warmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  const _AdvisorCard({
    required this.advisor,
    required this.onAddAdvisee,
  });

  final AdvisorLoad advisor;
  final VoidCallback onAddAdvisee;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.lavenderBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.midnight, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    advisor.fullName.trim().isEmpty
                        ? '?'
                        : advisor.fullName.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advisor.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.midnight,
                      ),
                    ),
                    Text(
                      [
                        if (advisor.lecturerNumber.isNotEmpty)
                          'NIP ${advisor.lecturerNumber}',
                        if (advisor.email.isNotEmpty) advisor.email,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              WavyBadge(
                text: '${advisor.adviseeCount} Mahasiswa',
                color: AppColors.lavenderBg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.creamAlt),
          const SizedBox(height: AppSpacing.sm),

          // Daftar Mahasiswa Bimbingan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mahasiswa Bimbingan:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.midnight,
                ),
              ),
              InkWell(
                onTap: onAddAdvisee,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          size: 15, color: AppColors.midnight),
                      SizedBox(width: 4),
                      Text(
                        'Atur Bimbingan',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.midnight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (advisor.advisees.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.creamAlt.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.warmTextMuted),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Belum ada mahasiswa bimbingan yang dialokasikan.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onAddAdvisee,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '+ Tambah',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: advisor.advisees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final advisee = advisor.advisees[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.creamBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.cartoonBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            advisee.fullName.trim().isEmpty
                                ? '?'
                                : advisee.fullName.trim()[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.midnight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              advisee.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.midnight,
                              ),
                            ),
                            if (advisee.studentNumber.isNotEmpty)
                              Text(
                                'NIM ${advisee.studentNumber}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warmTextSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            size: 18, color: Colors.redAccent),
                        tooltip: 'Lepas bimbingan',
                        onPressed: () {
                          context.read<PembimbingCubit>().assignAdvisees(
                            advisorId: null,
                            studentIds: [advisee.id],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _KelolaBimbinganSheet extends StatefulWidget {
  const _KelolaBimbinganSheet({this.initialAdvisorId});

  final String? initialAdvisorId;

  @override
  State<_KelolaBimbinganSheet> createState() => _KelolaBimbinganSheetState();
}

class _KelolaBimbinganSheetState extends State<_KelolaBimbinganSheet> {
  String? _selectedAdvisorId;
  final Set<String> _selectedStudentIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<PembimbingCubit>().state;
    if (widget.initialAdvisorId != null &&
        state.advisors.any((a) => a.advisorId == widget.initialAdvisorId)) {
      _selectedAdvisorId = widget.initialAdvisorId;
    } else if (state.advisors.isNotEmpty) {
      _selectedAdvisorId = state.advisors.first.advisorId;
    }
    _syncSelectedStudentsForAdvisor();
  }

  void _syncSelectedStudentsForAdvisor() {
    _selectedStudentIds.clear();
    if (_selectedAdvisorId != null) {
      final state = context.read<PembimbingCubit>().state;
      final advisor = state.advisors.firstWhere(
        (a) => a.advisorId == _selectedAdvisorId,
        orElse: () => const AdvisorLoad(
          advisorId: '',
          fullName: '',
          email: '',
          adviseeCount: 0,
        ),
      );
      for (final advisee in advisor.advisees) {
        _selectedStudentIds.add(advisee.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubitState = context.watch<PembimbingCubit>().state;
    final filteredStudents = cubitState.students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.studentNumber.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q);
    }).toList();

    final selectedAdvisor = cubitState.advisors.firstWhere(
      (a) => a.advisorId == _selectedAdvisorId,
      orElse: () => const AdvisorLoad(
        advisorId: '',
        fullName: 'Pilih Dosen',
        email: '',
        adviseeCount: 0,
      ),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.creamBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kelola Mahasiswa Bimbingan',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.midnight,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih dosen pembimbing, lalu pilih mahasiswa yang dialokasikan.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Selector Dosen Pembimbing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAdvisorId,
                dropdownColor: Colors.white,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down_rounded,
                    color: AppColors.midnight),
                items: cubitState.advisors.map((advisor) {
                  return DropdownMenuItem<String>(
                    value: advisor.advisorId,
                    child: Text(
                      '${advisor.fullName} (${advisor.adviseeCount} bimbingan)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedAdvisorId = val;
                      _syncSelectedStudentsForAdvisor();
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIM mahasiswa…',
              hintStyle: const TextStyle(fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: const BorderSide(color: AppColors.cartoonBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: const BorderSide(color: AppColors.cartoonBorder),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Student count summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpilih: ${_selectedStudentIds.length} mahasiswa',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.midnight,
                ),
              ),
              Text(
                'Total di prodi: ${cubitState.students.length}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.warmTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Student List Checkboxes
          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada mahasiswa ditemukan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final isSelected = _selectedStudentIds.contains(student.id);
                      final hasOtherAdvisor = student.hasAdvisor &&
                          student.advisorId != _selectedAdvisorId;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        elevation: 0,
                        color: isSelected
                            ? AppColors.lavenderBg.withValues(alpha: 0.6)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.midnight
                                : AppColors.cartoonBorder.withValues(alpha: 0.5),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          activeColor: AppColors.midnight,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedStudentIds.add(student.id);
                              } else {
                                _selectedStudentIds.remove(student.id);
                              }
                            });
                          },
                          title: Text(
                            student.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppColors.midnight,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (student.studentNumber.isNotEmpty)
                                Text(
                                  'NIM ${student.studentNumber}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.warmTextSecondary,
                                  ),
                                ),
                              if (hasOtherAdvisor)
                                Text(
                                  'Saat ini dibimbing: ${student.advisorName}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: cubitState.isSaving || _selectedAdvisorId == null
                  ? null
                  : () async {
                      final cubit = context.read<PembimbingCubit>();
                      final navigator = Navigator.of(context);
                      final success = await cubit.assignAdvisees(
                        advisorId: _selectedAdvisorId,
                        studentIds: _selectedStudentIds.toList(),
                      );
                      if (success && mounted) {
                        navigator.pop();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midnight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: cubitState.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan Mahasiswa Bimbingan (${selectedAdvisor.fullName.split(' ').first})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdministrativeNote extends StatelessWidget {
  const _AdministrativeNote();

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
              'Daftar ini adalah alokasi bimbingan akademik (data administratif). '
              'Data kondisi wellbeing per mahasiswa tetap privat dan tidak ditampilkan.',
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
