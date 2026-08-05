import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clay_container.dart';
import '../../../../core/widgets/responsive.dart';
import '../cubit/auth_cubit.dart';

/// Layar masuk.
///
/// Tata letak adaptif:
///  - Mobile portrait  : kolom tunggal, kartu clay memenuhi lebar.
///  - Tablet/desktop   : dua panel — panel kiri berisi pesan penenang,
///                       panel kanan berisi formulir dengan lebar terbatas.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
    final isWide = !Responsive.isMobile(context);

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          },
          builder: (context, state) {
            final form = _LoginForm(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onSubmit: _submit,
              state: state,
            );

            if (!isWide) {
              return SingleChildScrollView(
                child: ContentContainer(
                  maxWidth: 480,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      const _BrandHeader(),
                      const SizedBox(height: AppSpacing.xl),
                      form,
                    ],
                  ),
                ),
              );
            }

            return Row(
              children: [
                const Expanded(child: _WelcomePanel()),
                Expanded(
                  child: SingleChildScrollView(
                    child: ContentContainer(
                      maxWidth: 460,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: form,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClayContainer(
          width: 64,
          height: 64,
          borderRadius: AppSpacing.radiusMd,
          color: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.spa_rounded,
            size: 32,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Sanctuary', style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ruang aman untuk merawat kesehatan mentalmu selama kuliah.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Panel kiri pada layar lebar — menegaskan janji privasi sejak layar pertama.
class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface, AppColors.darkSurfaceAlt]
              : [AppColors.sageLight, AppColors.lavenderLight],
        ),
      ),
      child: const Center(
        child: ContentContainer(
          maxWidth: 420,
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrandHeader(),
              SizedBox(height: AppSpacing.xl),
              _PrivacyPoint(
                icon: Icons.lock_outline_rounded,
                text: 'Jurnal dan percakapan AI hanya bisa dibaca olehmu.',
              ),
              SizedBox(height: AppSpacing.md),
              _PrivacyPoint(
                icon: Icons.tune_rounded,
                text: 'Kamu yang menentukan seberapa banyak pembimbing melihat.',
              ),
              SizedBox(height: AppSpacing.md),
              _PrivacyPoint(
                icon: Icons.groups_2_outlined,
                text: 'Statistik prodi selalu berupa angka kelompok, bukan individu.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurface),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.state,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.radiusLg,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Masuk', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Gunakan email kampus yang terdaftar.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              enabled: !state.isSubmitting,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'nama@sanctuary.ac.id',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                errorText: state.fieldErrors['email'],
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Email wajib diisi';
                if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              enabled: !state.isSubmitting,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                errorText: state.fieldErrors['password'],
                suffixIcon: IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: obscurePassword
                      ? 'Tampilkan kata sandi'
                      : 'Sembunyikan kata sandi',
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) return 'Kata sandi wajib diisi';
                if ((value ?? '').length < 8) {
                  return 'Kata sandi minimal 8 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            ClayButton(
              label: 'Masuk',
              icon: Icons.arrow_forward_rounded,
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : onSubmit,
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Butuh bantuan segera? Layanan darurat tersedia tanpa harus masuk.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
