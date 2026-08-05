part of 'auth_cubit.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final String? errorMessage;

  /// Pesan error per field (dipetakan dari `field_errors` backend).
  final Map<String, String> fieldErrors;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  UserRole get role => user?.role ?? UserRole.unknown;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isSubmitting,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: clearError ? const {} : (fieldErrors ?? this.fieldErrors),
    );
  }

  @override
  List<Object?> get props => [status, user, isSubmitting, errorMessage, fieldErrors];
}
