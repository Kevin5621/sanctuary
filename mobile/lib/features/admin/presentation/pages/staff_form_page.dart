import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../../auth/domain/entities/study_program.dart';
import '../../domain/entities/managed_user.dart';
import '../cubit/kelola_akun_cubit.dart';
import '../widgets/staff_form_fields.dart';

/// Formulir buat / ubah akun dosen & kaprodi (A-AKN-01, A-AKN-02).
///
/// Dibuka dari [KelolaAkunTab] dengan cubit yang sama (lewat
/// [BlocProvider.value]) sehingga daftar di belakangnya ikut segar setelah
/// simpan, tanpa perlu memuat ulang manual.
class StaffFormPage extends StatefulWidget {
  const StaffFormPage({
    super.key,
    this.existing,
    required this.roles,
    required this.studyPrograms,
  });

  /// Null berarti membuat akun baru.
  final ManagedUser? existing;

  final List<RoleOption> roles;
  final List<StudyProgram> studyPrograms;

  @override
  State<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends State<StaffFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _lecturerNumberController;
  late final TextEditingController _phoneController;

  late String _role;
  String? _studyProgramId;
  late bool _isActive;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _fullNameController = TextEditingController(text: existing?.fullName ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _passwordController = TextEditingController();
    _lecturerNumberController =
        TextEditingController(text: existing?.lecturerNumber ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');

    // Nilai awal harus ada di daftar pilihan, kalau tidak DropdownButtonFormField
    // akan melempar. Jatuh ke opsi pertama bila nilai lama sudah tidak dikenal.
    final roleValues = widget.roles.map((role) => role.value).toSet();
    final initialRole = existing?.role ?? '';
    _role = roleValues.contains(initialRole)
        ? initialRole
        : (widget.roles.isNotEmpty ? widget.roles.first.value : '');

    final programIds = widget.studyPrograms.map((p) => p.id).toSet();
    final initialProgram = existing?.studyProgramId;
    _studyProgramId =
        initialProgram != null && programIds.contains(initialProgram)
            ? initialProgram
            : null;

    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _lecturerNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = StaffAccountDraft(
      fullName: _fullNameController.text.trim(),
      role: _role,
      studyProgramId: _studyProgramId ?? '',
      email: _emailController.text.trim(),
      password: _passwordController.text,
      lecturerNumber: _lecturerNumberController.text.trim(),
      phone: _phoneController.text.trim(),
      isActive: _isActive,
    );

    final saved = await context
        .read<KelolaAkunCubit>()
        .save(draft, id: widget.existing?.id ?? '');
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        backgroundColor: AppColors.creamBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.midnight,
        title: Text(
          _isEditing ? 'Ubah Akun' : 'Buat Akun Baru',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.midnight,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<KelolaAkunCubit, KelolaAkunState>(
          builder: (context, state) {
            final fieldErrors = state.fieldErrors;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const _ScopeNoticeCard(),
                  const SizedBox(height: AppSpacing.md),

                  StaffTextField(
                    label: 'Nama lengkap',
                    controller: _fullNameController,
                    hintText: 'mis. Dr. Sinta Pembimbing',
                    enabled: !state.isSaving,
                    maxLength: 128,
                    errorText: fieldErrors['full_name'],
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.length < 3) return 'Minimal 3 karakter';
                      return null;
                    },
                  ),

                  if (_isEditing)
                    _ReadOnlyEmail(email: widget.existing!.email)
                  else
                    StaffTextField(
                      label: 'Email kampus',
                      controller: _emailController,
                      hintText: 'nama@sanctuary.ac.id',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !state.isSaving,
                      maxLength: 160,
                      helperText:
                          'Dipakai untuk masuk dan tidak dapat diubah lagi '
                          'setelah akun dibuat.',
                      errorText: fieldErrors['email'],
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email wajib diisi';
                        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$')
                            .hasMatch(email)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),

                  StaffDropdownField<String>(
                    label: 'Peran',
                    value: _role.isEmpty ? null : _role,
                    hintText: 'Pilih peran',
                    // Peran dikunci saat mengubah: menukar dosen menjadi
                    // kaprodi mengubah cakupan data yang boleh ia lihat, dan
                    // itu keputusan yang layak dibuat lewat akun baru — bukan
                    // efek samping dari menyimpan formulir.
                    enabled: !_isEditing && !state.isSaving,
                    errorText: fieldErrors['role'],
                    items: [
                      for (final role in widget.roles)
                        StaffDropdownItem(value: role.value, label: role.label),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _role = value);
                    },
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Wajib dipilih' : null,
                  ),

                  StaffDropdownField<String>(
                    label: 'Program studi',
                    value: _studyProgramId,
                    hintText: 'Pilih program studi',
                    enabled: !state.isSaving,
                    errorText: fieldErrors['study_program_id'],
                    items: [
                      for (final program in widget.studyPrograms)
                        StaffDropdownItem(
                          value: program.id,
                          label: program.label,
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _studyProgramId = value),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Wajib dipilih' : null,
                  ),

                  StaffTextField(
                    label: 'NIDN',
                    controller: _lecturerNumberController,
                    hintText: 'Nomor Induk Dosen Nasional',
                    optional: true,
                    enabled: !state.isSaving,
                    maxLength: 32,
                    errorText: fieldErrors['lecturer_number'],
                    validator: (value) {
                      final number = value?.trim() ?? '';
                      if (number.isNotEmpty && number.length < 3) {
                        return 'Minimal 3 karakter';
                      }
                      return null;
                    },
                  ),

                  StaffTextField(
                    label: 'Nomor telepon',
                    controller: _phoneController,
                    hintText: '08xxxxxxxxxx',
                    optional: true,
                    keyboardType: TextInputType.phone,
                    enabled: !state.isSaving,
                    maxLength: 32,
                    errorText: fieldErrors['phone'],
                  ),

                  StaffTextField(
                    label: _isEditing ? 'Kata sandi baru' : 'Kata sandi awal',
                    controller: _passwordController,
                    hintText: 'Minimal 8 karakter',
                    optional: _isEditing,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    enabled: !state.isSaving,
                    maxLength: 128,
                    helperText: _isEditing
                        ? 'Biarkan kosong bila kata sandi tidak diubah. '
                            'Mengisinya akan mengakhiri sesi aktif pemilik akun.'
                        : 'Sampaikan lewat jalur pribadi, dan minta pemiliknya '
                            'segera menggantinya.',
                    errorText: fieldErrors['password'],
                    validator: (value) {
                      final password = value ?? '';
                      if (_isEditing && password.isEmpty) return null;
                      if (password.length < 8) {
                        return 'Kata sandi minimal 8 karakter';
                      }
                      return null;
                    },
                  ),

                  StaffActiveSwitch(
                    value: _isActive,
                    onChanged: state.isSaving
                        ? (_) {}
                        : (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.errorMessage != null) ...[
                    ErrorStateCard(
                      title: 'Gagal menyimpan',
                      message: state.errorMessage!,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  ElevatedButton.icon(
                    onPressed: state.isSaving ? null : _submit,
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isEditing ? 'Simpan Perubahan' : 'Buat Akun'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.midnight,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                  ),
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

/// Email hanya ditampilkan saat mengubah — sekaligus menjelaskan kenapa.
class _ReadOnlyEmail extends StatelessWidget {
  const _ReadOnlyEmail({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StaffFieldLabel('Email kampus'),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.creamAlt,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 16, color: AppColors.warmTextMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.warmTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Email adalah identitas login sekaligus kunci jejak audit yang '
            'sudah tercatat atas nama akun ini, jadi tidak dapat diubah.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: AppColors.warmTextMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// Menegaskan batas halaman ini sebelum Admin mencari yang tidak ada di sini.
class _ScopeNoticeCard extends StatelessWidget {
  const _ScopeNoticeCard();

  @override
  Widget build(BuildContext context) {
    return const StateCard(
      color: AppColors.lavenderBg,
      borderColor: AppColors.lavenderDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: AppColors.lavenderDark),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Halaman ini hanya untuk akun dosen dan kaprodi. Mahasiswa '
              'mendaftar sendiri lewat layar masuk, dan akun admin baru tidak '
              'dapat dibuat dari aplikasi.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.midnight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
