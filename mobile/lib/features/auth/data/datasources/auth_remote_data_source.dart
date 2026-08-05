import '../../../../core/network/dio_client.dart';
import '../../domain/entities/app_user.dart';
import '../models/user_model.dart';

/// Sumber data jarak jauh untuk domain auth.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final DioClient _client;

  Future<SessionModel> login({
    required String email,
    required String password,
  }) async {
    final result = await _client.post<SessionModel>(
      '/auth/login',
      body: {'email': email, 'password': password},
      parser: (data) => SessionModel.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<AppUser> me() async {
    final result = await _client.get<AppUser>(
      '/auth/me',
      parser: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    return result.data;
  }

  Future<void> logout({String? refreshToken}) async {
    await _client.post<void>(
      '/auth/logout',
      body: refreshToken != null && refreshToken.isNotEmpty
          ? {'refresh_token': refreshToken}
          : null,
      parser: (_) {},
    );
  }
}
