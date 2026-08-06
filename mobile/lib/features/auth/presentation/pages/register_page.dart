import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive.dart';
import '../../domain/entities/study_program.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/study_program_cubit.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_dropdown_field.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_form_section.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';

/// Pendaftaran mandiri mahasiswa.
///
/// Hanya mahasiswa yang dapat mendaftar sendiri dari layar ini; akun dosen dan
/// kaprodi dibuatkan Admin. Karena itu tidak ada pilihan peran di mana pun pada
/// formulir — bukan disembunyikan, memang tidak dikirim, dan server pun selalu
/// membuat akun mahasiswa apa pun isi permintaannya.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StudyProgramCubit(context.read<AuthRepository>())..load(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _studyProgramId;
  int? _cohortYear;

  /// Angkatan yang wajar untuk mahasiswa aktif. Dibatasi supaya salah ketik
  /// tahun (mis. 2202) tidak berakhir sebagai angkatan yang mustahil.
  static const _cohortRange = 8;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _studentNumberController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await context.read<AuthCubit>().register(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
          studentNumber: _studentNumberController.text,
          cohortYear: _cohortYear!,
          studyProgramId: _studyProgramId!,
          phone: _phoneController.text,
        );
    // Tidak ada navigasi manual di sini: sesi yang terbit setelah pendaftaran
    // membuat gerbang router memindahkan pengguna ke beranda mahasiswa.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;
    final cohortYears = [
      for (var year = currentYear; year > currentYear - _cohortRange; year--) year,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali ke layar masuk',
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Daftar Akun'),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          },
          builder: (context, authState) {
            final isSubmitting = authState.isSubmitting;

            return SingleChildScrollView(
              child: ContentContainer(
                maxWidth: 480,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthBrandHeader(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Buat Akun Mahasiswa',
                        subtitle:
                            'Ruang aman untuk merawat kesehatan mentalmu, '
                            'dimulai dari satu akun',
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      AuthFormSection(
                        title: 'Identitas Diri',
                        children: [
                          AuthTextField(
                            label: 'Nama Lengkap',
                            controller: _fullNameController,
                            hintText: 'Nama sesuai data kampus',
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.name,
                            autofillHints: const [AutofillHints.name],
                            enabled: !isSubmitting,
                            maxLength: 128,
                            errorText: authState.fieldErrors['full_name'],
                            validator: (value) {
                              final name = value?.trim() ?? '';
                              if (name.isEmpty) return 'Nama wajib diisi';
                              if (name.length < 3) {
                                return 'Nama minimal 3 karakter';
                              }
                              return null;
                            },
                          ),
                          AuthTextField(
                            label: 'Email Kampus',
                            controller: _emailController,
                            hintText: 'nama@sanctuary.ac.id',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            enabled: !isSubmitting,
                            maxLength: 160,
                            errorText: authState.fieldErrors['email'],
                            validator: _validateEmail,
                          ),
                          AuthTextField(
                            label: 'Nomor Telepon',
                            controller: _phoneController,
                            hintText: '08xxxxxxxxxx',
                            prefixIcon: Icons.call_outlined,
                            keyboardType: TextInputType.phone,
                            enabled: !isSubmitting,
                            optional: true,
                            maxLength: 32,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                            ],
                            errorText: authState.fieldErrors['phone'],
                          ),
                        ],
                      ),

                      AuthFormSection(
                        title: 'Data Akademik',
                        description:
                            'Dipakai untuk menempatkanmu di program studi yang '
                            'benar. Dosen pembimbing ditetapkan prodi setelah '
                            'akunmu aktif.',
                        children: [
                          AuthTextField(
                            label: 'NIM',
                            controller: _studentNumberController,
                            hintText: 'Nomor Induk Mahasiswa',
                            prefixIcon: Icons.numbers_rounded,
                            keyboardType: TextInputType.text,
                            enabled: !isSubmitting,
                            maxLength: 32,
                            errorText: authState.fieldErrors['student_number'],
                            validator: (value) {
                              final nim = value?.trim() ?? '';
                              if (nim.isEmpty) return 'NIM wajib diisi';
                              if (nim.length < 3) return 'NIM minimal 3 karakter';
                              return null;
                            },
                          ),
                          AuthDropdownField<int>(
                            label: 'Angkatan',
                            value: _cohortYear,
                            hintText: 'Pilih tahun masuk',
                            prefixIcon: Icons.calendar_today_outlined,
                            enabled: !isSubmitting,
                            errorText: authState.fieldErrors['cohort_year'],
                            items: [
                              for (final year in cohortYears)
                                AuthDropdownItem(value: year, label: '$year'),
                            ],
                            onChanged: (value) =>
                                setState(() => _cohortYear = value),
                            validator: (value) =>
                                value == null ? 'Angkatan wajib dipilih' : null,
                          ),
                          _StudyProgramField(
                            selectedId: _studyProgramId,
                            enabled: !isSubmitting,
                            errorText: authState.fieldErrors['study_program_id'],
                            onChanged: (value) =>
                                setState(() => _studyProgramId = value),
                          ),
                        ],
                      ),

                      AuthFormSection(
                        title: 'Keamanan Akun',
                        children: [
                          AuthPasswordField(
                            label: 'Kata Sandi',
                            controller: _passwordController,
                            hintText: 'Minimal 8 karakter',
                            autofillHints: const [AutofillHints.newPassword],
                            enabled: !isSubmitting,
                            errorText: authState.fieldErrors['password'],
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }
                              if (password.length < 8) {
                                return 'Kata sandi minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          AuthPasswordField(
                            label: 'Ulangi Kata Sandi',
                            controller: _confirmPasswordController,
                            hintText: 'Ketik ulang kata sandi',
                            textInputAction: TextInputAction.done,
                            enabled: !isSubmitting,
                            errorText:
                                authState.fieldErrors['password_confirmation'],
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi';
                              }
                              if (value != _passwordController.text) {
                                return 'Konfirmasi tidak sama dengan kata sandi';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.sm),
                      AuthSubmitButton(
                        label: 'Daftar',
                        isLoading: isSubmitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'Dengan mendaftar, kamu memulai dengan pengaturan '
                        'privasi paling tertutup. Tidak ada satu pun data '
                        'kondisimu yang dibagikan sebelum kamu sendiri '
                        'menyalakannya di Pengaturan Privasi.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      AuthFooterLink(
                        question: 'Sudah punya akun?',
                        actionLabel: 'Masuk',
                        onTap: () => context.go('/login'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return 'Format email tidak valid';
    }
    return null;
  }
}

/// Dropdown program studi beserta tiga keadaan pemuatannya.
///
/// Daftar kosong sengaja dibedakan dari gagal memuat: yang pertama berarti
/// kampus belum mendaftarkan prodi mana pun (menyuruh "coba lagi" tidak akan
/// menolong), yang kedua memang layak dicoba ulang.
class _StudyProgramField extends StatelessWidget {
  const _StudyProgramField({
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
    this.errorText,
  });

  final String? selectedId;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<StudyProgramCubit, StudyProgramState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        if (state.status == StudyProgramStatus.failure || state.isEmpty) {
          final message = state.isEmpty
              ? 'Belum ada program studi terdaftar. Hubungi admin kampus '
                  'sebelum membuat akun.'
              : state.errorMessage ??
                  'Daftar program studi gagal dimuat. Periksa koneksimu.';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                if (!state.isEmpty)
                  TextButton.icon(
                    onPressed: () => context.read<StudyProgramCubit>().load(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Muat ulang'),
                  ),
              ],
            ),
          );
        }

        return AuthDropdownField<String>(
          label: 'Program Studi',
          value: _valueIn(state.programs, selectedId),
          hintText: 'Pilih program studi',
          prefixIcon: Icons.school_outlined,
          enabled: enabled,
          errorText: errorText,
          items: [
            for (final program in state.programs)
              AuthDropdownItem(value: program.id, label: program.label),
          ],
          onChanged: onChanged,
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Program studi wajib dipilih' : null,
        );
      },
    );
  }

  /// DropdownButtonFormField melempar bila nilai terpilih tidak ada di daftar,
  /// mis. saat daftar dimuat ulang dan prodi lama sudah tidak ada.
  static String? _valueIn(List<StudyProgram> programs, String? id) {
    if (id == null) return null;
    return programs.any((program) => program.id == id) ? id : null;
  }
}
