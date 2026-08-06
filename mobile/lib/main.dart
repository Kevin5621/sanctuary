import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'core/network/token_storage.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/widgets/environment_banner.dart';
import 'features/admin/data/repositories/user_admin_repository.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/dosen/data/repositories/mentor_repository.dart';
import 'features/kaprodi/data/repositories/program_repository.dart';
import 'features/mahasiswa/data/repositories/ai_chat_repository.dart';
import 'features/mahasiswa/data/repositories/contact_request_repository.dart';
import 'features/mahasiswa/data/repositories/daily_metric_repository.dart';
import 'features/mahasiswa/data/repositories/journal_repository.dart';
import 'features/mahasiswa/data/repositories/dass_repository.dart';
import 'features/mahasiswa/data/repositories/journal_repository.dart';
import 'features/privacy/data/repositories/privacy_repository.dart';
import 'features/support/data/repositories/emergency_contact_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SanctuaryApp());
}

/// Composition root.
///
/// Dependency di-wire manual (tanpa service locator) agar alurnya terbaca:
/// TokenStorage → DioClient → data source → repository → cubit.
class SanctuaryApp extends StatefulWidget {
  const SanctuaryApp({super.key});

  @override
  State<SanctuaryApp> createState() => _SanctuaryAppState();
}

class _SanctuaryAppState extends State<SanctuaryApp> {
  late final TokenStorage _tokenStorage;
  late final DioClient _dioClient;
  late final AuthCubit _authCubit;
  late final AuthRepository _authRepository;
  late final ThemeCubit _themeCubit;
  late final PrivacyRepository _privacyRepository;
  late final DailyMetricRepository _dailyMetricRepository;
  late final JournalRepository _journalRepository;
  late final AiChatRepository _aiChatRepository;
  late final JournalRepository _journalRepository;
  late final DassRepository _dassRepository;
  late final ContactRequestRepository _contactRequestRepository;
  late final MentorRepository _mentorRepository;
  late final ProgramRepository _programRepository;
  late final EmergencyContactRepository _emergencyContactRepository;
  late final UserAdminRepository _userAdminRepository;
  late final _router = createRouter(_authCubit);

  @override
  void initState() {
    super.initState();

    _tokenStorage = TokenStorage();

    // AuthCubit dibuat lebih dulu karena DioClient perlu memberitahunya
    // saat refresh token gagal — router lalu mengalihkan ke layar masuk.
    late final DioClient client;
    _authRepository = AuthRepositoryImpl(
      remote: AuthRemoteDataSource(
        client = DioClient(
          tokenStorage: _tokenStorage,
          onSessionExpired: () async => _authCubit.onSessionExpired(),
        ),
      ),
      tokenStorage: _tokenStorage,
    );
    _authCubit = AuthCubit(_authRepository);
    _dioClient = client;
    _privacyRepository = PrivacyRepository(_dioClient);
    _dailyMetricRepository = DailyMetricRepository(_dioClient);
    _journalRepository = JournalRepository(_dioClient);
    _aiChatRepository = AiChatRepository(_dioClient);
    _journalRepository = JournalRepository(_dioClient);
    _dassRepository = DassRepository(_dioClient);
    _contactRequestRepository = ContactRequestRepository(_dioClient);
    _mentorRepository = MentorRepository(_dioClient);
    _programRepository = ProgramRepository(_dioClient);
    _emergencyContactRepository = EmergencyContactRepository(_dioClient);
    _userAdminRepository = UserAdminRepository(_dioClient);

    // Tema dipulihkan bersamaan dengan sesi supaya aplikasi tidak berkedip
    // dari terang ke gelap setelah frame pertama.
    _themeCubit = ThemeCubit(ThemePreferenceStorage())..restore();

    _authCubit.restoreSession();
  }

  @override
  void dispose() {
    _authCubit.close();
    _themeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DioClient>.value(value: _dioClient),
        // AuthRepository ikut disediakan karena layar pendaftaran
        // membutuhkannya sebelum ada sesi (daftar program studi).
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<PrivacyRepository>.value(value: _privacyRepository),
        RepositoryProvider<DailyMetricRepository>.value(value: _dailyMetricRepository),
        RepositoryProvider<JournalRepository>.value(value: _journalRepository),
        RepositoryProvider<AiChatRepository>.value(value: _aiChatRepository),
        RepositoryProvider<JournalRepository>.value(value: _journalRepository),
        RepositoryProvider<DassRepository>.value(value: _dassRepository),
        RepositoryProvider<ContactRequestRepository>.value(
          value: _contactRequestRepository,
        ),
        RepositoryProvider<MentorRepository>.value(value: _mentorRepository),
        RepositoryProvider<ProgramRepository>.value(value: _programRepository),
        RepositoryProvider<EmergencyContactRepository>.value(
          value: _emergencyContactRepository,
        ),
        RepositoryProvider<UserAdminRepository>.value(
          value: _userAdminRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<ThemeCubit>.value(value: _themeCubit),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) => MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            // Pilihan pengguna, bukan lagi selalu ThemeMode.system (M-PRO-08).
            themeMode: themeMode,
            routerConfig: _router,
            builder: (context, child) =>
                EnvironmentBanner(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
