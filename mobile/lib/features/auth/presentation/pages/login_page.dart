import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';

/// Layar masuk (Login Page) — minimalis, tanpa kartu, menempel pada canvas.
///
/// Elemen formulirnya dibagi dengan layar daftar lewat `widgets/`, sehingga
/// kedua pintu masuk aplikasi tidak dapat menyimpang satu sama lain.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthCubit>().login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                child: ContentContainer(
                  maxWidth: 400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthBrandHeader(
                        title: 'Sanctuary',
                        subtitle: 'Ruang aman untuk merawat kesehatan mentalmu',
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthTextField(
                              label: 'Email Kampus',
                              controller: _emailController,
                              hintText: 'nama@sanctuary.ac.id',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              enabled: !state.isSubmitting,
                              errorText: state.fieldErrors['email'],
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
                            AuthPasswordField(
                              label: 'Kata Sandi',
                              controller: _passwordController,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              enabled: !state.isSubmitting,
                              errorText: state.fieldErrors['password'],
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Kata sandi wajib diisi';
                                }
                                if ((value ?? '').length < 8) {
                                  return 'Kata sandi minimal 8 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AuthSubmitButton(
                              label: 'Masuk',
                              isLoading: state.isSubmitting,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Hanya mahasiswa yang mendaftar sendiri; dosen & kaprodi
                      // menerima akun dari Admin, jadi kalimatnya menyebut itu
                      // agar mereka tidak menunggu tautan yang bukan untuknya.
                      AuthFooterLink(
                        question: 'Mahasiswa baru?',
                        actionLabel: 'Daftar di sini',
                        onTap: () => context.go('/register'),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      const _EmergencyHelpLink(),
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
}

/// Link halus ke bantuan darurat tanpa mengalihkan perhatian dari form utama.
class _EmergencyHelpLink extends StatelessWidget {
  const _EmergencyHelpLink();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Butuh bantuan segera tanpa masuk?',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () {
            // Pengguna dapat diarahkan ke kontak bantuan darurat bila diperlukan
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'Akses Layanan Darurat',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
