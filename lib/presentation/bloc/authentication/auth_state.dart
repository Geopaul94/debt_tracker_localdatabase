abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthRequired extends AuthState {}

class AuthNotRequired extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthEnabled extends AuthState {}

class AuthDisabled extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  AuthError(this.message);
}

class AuthSettingsLoaded extends AuthState {
  final bool isEnabled;
  final bool isBiometricAvailable;
  
  AuthSettingsLoaded({
    required this.isEnabled,
    required this.isBiometricAvailable,
  });
}
