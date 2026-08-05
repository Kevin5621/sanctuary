import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'core/network/token_storage.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/environment_banner.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/privacy/data/repositories/privacy_repository.dart';

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
  late final PrivacyRepository _privacyRepository;
  late final _router = createRouter(_authCubit);

  @override
  void initState() {
    super.initState();

    _tokenStorage = TokenStorage();

    // AuthCubit dibuat lebih dulu karena DioClient perlu memberitahunya
    // saat refresh token gagal — router lalu mengalihkan ke layar masuk.
    late final DioClient client;
    _authCubit = AuthCubit(
      AuthRepositoryImpl(
        remote: AuthRemoteDataSource(
          client = DioClient(
            tokenStorage: _tokenStorage,
            onSessionExpired: () async => _authCubit.onSessionExpired(),
          ),
        ),
        tokenStorage: _tokenStorage,
      ),
    );
    _dioClient = client;
    _privacyRepository = PrivacyRepository(_dioClient);

    _authCubit.restoreSession();
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DioClient>.value(value: _dioClient),
        RepositoryProvider<PrivacyRepository>.value(value: _privacyRepository),
      ],
      child: BlocProvider<AuthCubit>.value(
        value: _authCubit,
        child: MaterialApp.router(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: _router,
          builder: (context, child) =>
              EnvironmentBanner(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
