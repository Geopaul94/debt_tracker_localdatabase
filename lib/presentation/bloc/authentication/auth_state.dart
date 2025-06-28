// auth_state.dart
abstract class AuthState {}

/// Initial state when the app starts
class AuthInitial extends AuthState {}

/// State when authentication is successful
class AuthSuccess extends AuthState {}

/// State when authentication fails or errors out
class AuthFailed extends AuthState {
  final String message;
  AuthFailed(this.message);
}

/// State when user toggles biometric auth ON/OFF
class AuthEnabledState extends AuthState {
  final bool isEnabled;
  AuthEnabledState(this.isEnabled);
}
