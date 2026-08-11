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
///
/// Satu mahasiswa boleh dibimbing beberapa dosen. Karena itu ada DUA arah
/// pengelolaan untuk relasi yang sama:
///   - per dosen     → "siapa saja bimbingan dosen ini"
///   - per mahasiswa → "siapa saja pembimbing mahasiswa ini"
///
/// Yang kedua bukan pelengkap: tanpa layar per-mahasiswa, menambah pembimbing
/// kedua berarti membuka layar dosen satu per satu sambil mengingat siapa saja
/// yang sudah tercentang di layar sebelumnya.
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

  void _openAdvisorSheet(BuildContext context, {String? preselectedAdvisorId}) {
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

  void _openStudentPickerSheet(BuildContext context) {
    final cubit = context.read<PembimbingCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _StudentPickerSheet(),
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
            onPressed: () => _openStudentPickerSheet(context),
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
                    _SummaryHeader(
                      state: state,
                      onManagePerStudent: () => _openStudentPickerSheet(context),
                      onManagePerAdvisor: () => _openAdvisorSheet(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final advisor in state.advisors)
                      _AdvisorCard(
                        advisor: advisor,
                        students: state.students,
                        onEditAdvisees: () => _openAdvisorSheet(
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

/// Membuka lembar "pembimbing satu mahasiswa" dari mana pun di tab ini.
void _openStudentAdvisorsSheet(BuildContext context, ProgramStudent student) {
  final cubit = context.read<PembimbingCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _StudentAdvisorsSheet(studentId: student.id),
    ),
  );
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.state,
    required this.onManagePerStudent,
    required this.onManagePerAdvisor,
  });

  final PembimbingState state;
  final VoidCallback onManagePerStudent;
  final VoidCallback onManagePerAdvisor;

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
          // Wrap, bukan Row: jumlah kartu berubah (mahasiswa tanpa dosen dan
          // bimbingan bersama hanya muncul saat ada), dan Row akan meluber.
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _HeaderStatTile(
                      value: '${state.advisors.length}',
                      label: 'Dosen Pembimbing',
                      color: AppColors.lavenderBg,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _HeaderStatTile(
                      value: '${state.assignedCount}',
                      label: 'Mahasiswa Dibimbing',
                      color: AppColors.creamAlt,
                      hint: '${state.totalAssignments} alokasi',
                    ),
                  ),
                  if (state.coAdvisedCount > 0)
                    SizedBox(
                      width: tileWidth,
                      child: _HeaderStatTile(
                        value: '${state.coAdvisedCount}',
                        label: 'Dibimbing >1 Dosen',
                        color: AppColors.moodHappinessBg,
                      ),
                    ),
                  if (state.unassignedCount > 0)
                    SizedBox(
                      width: tileWidth,
                      child: _HeaderStatTile(
                        value: '${state.unassignedCount}',
                        label: 'Belum Ada Dosen',
                        color: const Color(0xFFFFF3E0),
                        isWarning: true,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Dua arah pengelolaan disandingkan supaya keduanya terlihat setara.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManagePerStudent,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.midnight,
                    side: const BorderSide(color: AppColors.midnight, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.person_search_rounded, size: 17),
                  label: const Text(
                    'Per Mahasiswa',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManagePerAdvisor,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.midnight,
                    side: const BorderSide(
                      color: AppColors.cartoonBorder,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.group_add_rounded, size: 17),
                  label: const Text(
                    'Per Dosen',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ),
            ],
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
    this.hint,
    this.isWarning = false,
  });

  final String value;
  final String label;
  final Color color;
  final String? hint;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: isWarning ? const Color(0xFFE65100) : AppColors.midnight,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warmTextMuted,
                    ),
                  ),
                ),
              ],
            ],
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
    required this.students,
    required this.onEditAdvisees,
  });

  final AdvisorLoad advisor;
  final List<ProgramStudent> students;
  final VoidCallback onEditAdvisees;

  /// Mencari baris mahasiswa lengkap (beserta seluruh pembimbingnya) untuk satu
  /// bimbingan; dipakai menandai bimbingan bersama tanpa request tambahan.
  ProgramStudent? _studentOf(String id) {
    for (final student in students) {
      if (student.id == id) return student;
    }
    return null;
  }

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
                onTap: onEditAdvisees,
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
                    onPressed: onEditAdvisees,
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
                final student = _studentOf(advisee.id);
                final coAdvisors =
                    student?.otherAdvisorNames(advisor.advisorId) ?? const [];

                return _AdviseeRow(
                  name: advisee.fullName,
                  studentNumber: advisee.studentNumber,
                  coAdvisors: coAdvisors,
                  onTap: student == null
                      ? null
                      : () => _openStudentAdvisorsSheet(context, student),
                  onRemove: student == null
                      ? null
                      : () => context.read<PembimbingCubit>().removeAdvisor(
                            student: student,
                            advisorId: advisor.advisorId,
                          ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AdviseeRow extends StatelessWidget {
  const _AdviseeRow({
    required this.name,
    required this.studentNumber,
    required this.coAdvisors,
    this.onTap,
    this.onRemove,
  });

  final String name;
  final String studentNumber;
  final List<String> coAdvisors;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
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
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.midnight,
                    ),
                  ),
                  if (studentNumber.isNotEmpty)
                    Text(
                      'NIM $studentNumber',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),

                  // Bimbingan bersama ditandai netral (bukan peringatan): sejak
                  // revisi alur, dua pembimbing adalah keadaan yang sah.
                  if (coAdvisors.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _CoAdvisorTag(names: coAdvisors),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded,
                  size: 18, color: Colors.redAccent),
              tooltip: 'Lepas dari dosen ini',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoAdvisorTag extends StatelessWidget {
  const _CoAdvisorTag({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.moodHappinessBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_alt_rounded, size: 11, color: AppColors.midnight),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Juga dibimbing ${names.join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
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
// Lembar: kelola bimbingan PER DOSEN
// ------------------------------------------------------------------

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

  /// Centang awal = alokasi yang berlaku sekarang untuk dosen terpilih.
  void _syncSelectedStudentsForAdvisor() {
    _selectedStudentIds.clear();
    if (_selectedAdvisorId == null) return;

    final state = context.read<PembimbingCubit>().state;
    for (final student in state.students) {
      if (student.isAdvisedBy(_selectedAdvisorId)) {
        _selectedStudentIds.add(student.id);
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

    return _SheetShell(
      title: 'Bimbingan per Dosen',
      subtitle: 'Pilih dosen, lalu centang mahasiswa yang ia bimbing. '
          'Melepas centang hanya melepas dosen ini — pembimbing lain tetap.',
      children: [
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

        _SearchField(
          hint: 'Cari nama atau NIM mahasiswa…',
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: AppSpacing.sm),

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
                    final others = student.otherAdvisorNames(_selectedAdvisorId);

                    return _SelectableTile(
                      isSelected: isSelected,
                      title: student.fullName,
                      subtitle: student.studentNumber.isEmpty
                          ? null
                          : 'NIM ${student.studentNumber}',
                      // Keterangan, bukan peringatan: pembimbing lain adalah
                      // keadaan normal sekarang, bukan konflik yang harus
                      // diselesaikan sebelum menyimpan.
                      footnote: others.isEmpty
                          ? null
                          : 'Juga dibimbing ${others.join(', ')}',
                      onChanged: (checked) {
                        setState(() {
                          if (checked) {
                            _selectedStudentIds.add(student.id);
                          } else {
                            _selectedStudentIds.remove(student.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.md),

        _SaveButton(
          isSaving: cubitState.isSaving,
          label: _selectedAdvisorId == null
              ? 'Pilih dosen terlebih dahulu'
              : 'Simpan Bimbingan (${selectedAdvisor.fullName.split(' ').first})',
          onPressed: _selectedAdvisorId == null
              ? null
              : () async {
                  final cubit = context.read<PembimbingCubit>();
                  final navigator = Navigator.of(context);
                  final success = await cubit.setAdvisees(
                    advisorId: _selectedAdvisorId!,
                    studentIds: _selectedStudentIds.toList(),
                  );
                  if (success && mounted) navigator.pop();
                },
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Lembar: pilih mahasiswa → atur pembimbingnya
// ------------------------------------------------------------------

class _StudentPickerSheet extends StatefulWidget {
  const _StudentPickerSheet();

  @override
  State<_StudentPickerSheet> createState() => _StudentPickerSheetState();
}

class _StudentPickerSheetState extends State<_StudentPickerSheet> {
  String _searchQuery = '';
  bool _onlyUnassigned = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PembimbingCubit>().state;

    final students = state.students.where((s) {
      if (_onlyUnassigned && s.hasAdvisor) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.studentNumber.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q);
    }).toList();

    return _SheetShell(
      title: 'Bimbingan per Mahasiswa',
      subtitle: 'Pilih mahasiswa untuk melihat dan mengatur seluruh '
          'dosen pembimbingnya.',
      children: [
        _SearchField(
          hint: 'Cari nama atau NIM mahasiswa…',
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            FilterChip(
              selected: _onlyUnassigned,
              onSelected: (val) => setState(() => _onlyUnassigned = val),
              label: Text('Belum ada dosen (${state.unassignedCount})'),
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _onlyUnassigned ? Colors.white : AppColors.midnight,
              ),
              backgroundColor: Colors.white,
              selectedColor: AppColors.midnight,
              checkmarkColor: Colors.white,
              side: const BorderSide(color: AppColors.cartoonBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            const Spacer(),
            Text(
              '${students.length} mahasiswa',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        Expanded(
          child: students.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada mahasiswa ditemukan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warmTextSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _StudentAdvisorSummaryTile(
                      student: student,
                      onTap: () => _openStudentAdvisorsSheet(context, student),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StudentAdvisorSummaryTile extends StatelessWidget {
  const _StudentAdvisorSummaryTile({required this.student, required this.onTap});

  final ProgramStudent student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.cartoonBorder.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.midnight,
                    ),
                  ),
                  if (student.studentNumber.isNotEmpty)
                    Text(
                      'NIM ${student.studentNumber}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  const SizedBox(height: 5),
                  if (!student.hasAdvisor)
                    const Text(
                      'Belum ada dosen pembimbing',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final advisor in student.advisors)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.lavenderBg,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusPill),
                            ),
                            child: Text(
                              advisor.fullName,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.midnight,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.warmTextMuted),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Lembar: pembimbing SATU mahasiswa
// ------------------------------------------------------------------

class _StudentAdvisorsSheet extends StatefulWidget {
  const _StudentAdvisorsSheet({required this.studentId});

  final String studentId;

  @override
  State<_StudentAdvisorsSheet> createState() => _StudentAdvisorsSheetState();
}

class _StudentAdvisorsSheetState extends State<_StudentAdvisorsSheet> {
  final Set<String> _selectedAdvisorIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<PembimbingCubit>().state;
    for (final student in state.students) {
      if (student.id == widget.studentId) {
        _selectedAdvisorIds.addAll(student.advisorIds);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PembimbingCubit>().state;
    final student = state.students.firstWhere(
      (s) => s.id == widget.studentId,
      orElse: () => const ProgramStudent(
        id: '',
        fullName: 'Mahasiswa',
        studentNumber: '',
        email: '',
      ),
    );

    final advisors = state.advisors.where((a) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return a.fullName.toLowerCase().contains(q) ||
          a.lecturerNumber.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q);
    }).toList();

    return _SheetShell(
      title: 'Pembimbing ${student.fullName}',
      subtitle: student.studentNumber.isEmpty
          ? 'Centang setiap dosen yang membimbing mahasiswa ini.'
          : 'NIM ${student.studentNumber} · Centang setiap dosen yang '
              'membimbing mahasiswa ini.',
      children: [
        _SearchField(
          hint: 'Cari nama dosen atau NIP…',
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Jumlah pembimbing terpilih ditampilkan terus-menerus: keputusan
        // "berapa orang yang akan melihat data mahasiswa ini" tidak boleh
        // hanya tersirat dari deretan centang.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _selectedAdvisorIds.isEmpty
                ? const Color(0xFFFFF3E0)
                : AppColors.lavenderBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            _selectedAdvisorIds.isEmpty
                ? 'Belum ada pembimbing terpilih — mahasiswa ini tidak dapat '
                    'memakai tombol "minta dihubungi".'
                : '${_selectedAdvisorIds.length} pembimbing terpilih. '
                    'Semuanya memiliki akses yang sama, sesuai izin privasi mahasiswa.',
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.midnight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        Expanded(
          child: advisors.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada dosen ditemukan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warmTextSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: advisors.length,
                  itemBuilder: (context, index) {
                    final advisor = advisors[index];
                    final isSelected =
                        _selectedAdvisorIds.contains(advisor.advisorId);

                    return _SelectableTile(
                      isSelected: isSelected,
                      title: advisor.fullName,
                      subtitle: [
                        if (advisor.lecturerNumber.isNotEmpty)
                          'NIP ${advisor.lecturerNumber}',
                        '${advisor.adviseeCount} bimbingan',
                      ].join(' · '),
                      onChanged: (checked) {
                        setState(() {
                          if (checked) {
                            _selectedAdvisorIds.add(advisor.advisorId);
                          } else {
                            _selectedAdvisorIds.remove(advisor.advisorId);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.md),

        _SaveButton(
          isSaving: state.isSaving,
          label: 'Simpan Pembimbing (${_selectedAdvisorIds.length})',
          onPressed: student.id.isEmpty
              ? null
              : () async {
                  final cubit = context.read<PembimbingCubit>();
                  final navigator = Navigator.of(context);
                  final success = await cubit.setStudentAdvisors(
                    studentId: student.id,
                    advisorIds: _selectedAdvisorIds.toList(),
                  );
                  if (success && mounted) navigator.pop();
                },
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Potongan UI bersama
// ------------------------------------------------------------------

/// Kerangka bottom sheet: handle, judul, penjelasan, lalu isi.
///
/// Dipakai ketiga lembar supaya alur "per dosen" dan "per mahasiswa" terasa
/// sebagai satu layar yang sama dilihat dari dua sisi.
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.isSelected,
    required this.title,
    required this.onChanged,
    this.subtitle,
    this.footnote,
  });

  final bool isSelected;
  final String title;
  final String? subtitle;
  final String? footnote;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: isSelected
          ? AppColors.lavenderBg.withValues(alpha: 0.6)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: isSelected
              ? AppColors.midnight
              : AppColors.cartoonBorder.withValues(alpha: 0.5),
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        activeColor: AppColors.midnight,
        onChanged: (checked) => onChanged(checked ?? false),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: AppColors.midnight,
          ),
        ),
        subtitle: subtitle == null && footnote == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  if (footnote != null)
                    Text(
                      footnote!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmTextMuted,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.label,
    required this.onPressed,
  });

  final bool isSaving;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.midnight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
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
              'Satu mahasiswa boleh dibimbing beberapa dosen, dan semuanya memiliki '
              'akses yang sama — tetap sebatas izin privasi yang dipilih mahasiswa. '
              'Data kondisi wellbeing per mahasiswa tidak ditampilkan di sini.',
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
