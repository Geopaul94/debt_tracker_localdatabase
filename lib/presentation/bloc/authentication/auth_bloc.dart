import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../core/services/authentication_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthenticationService _authenticationService;

  AuthBloc({required AuthenticationService authenticationService})
    : _authenticationService = authenticationService,
      super(AuthInitial()) {
    on<CheckAuthRequiredEvent>(_onCheckAuthRequired);
    on<EnableAuthEvent>(_onEnableAuth);
    on<DisableAuthEvent>(_onDisableAuth);
    on<AuthenticateEvent>(_onAuthenticate);
    on<LoadAuthSettingsEvent>(_onLoadAuthSettings);
  }

  Future<void> _onCheckAuthRequired(
    CheckAuthRequiredEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('Checking if authentication is required...');
      final isRequired =
          await _authenticationService.isAuthenticationRequired();
      print('Authentication required: $isRequired');

      if (isRequired) {
        emit(AuthRequired());
      } else {
        emit(AuthNotRequired());
      }
    } catch (e) {
      print('Error checking authentication requirement: $e');
      emit(
        AuthError(
          'Failed to check authentication requirement: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onEnableAuth(
    EnableAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authenticationService.enableAuthentication();
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (success) => emit(AuthEnabled()),
    );
  }

  Future<void> _onDisableAuth(
    DisableAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authenticationService.disableAuthentication();
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (success) => emit(AuthDisabled()),
    );
  }

  Future<void> _onAuthenticate(
    AuthenticateEvent event,
    Emitter<AuthState> emit,
  ) async {
    print('Authentication event triggered');
    emit(AuthLoading());

    final result = await _authenticationService.authenticate(event.reason);
    result.fold(
      (failure) {
        print('Authentication failed: ${_mapFailureToMessage(failure)}');
        emit(AuthError(_mapFailureToMessage(failure)));
      },
      (success) {
        print('Authentication successful');
        emit(AuthSuccess());
      },
    );
  }

  Future<void> _onLoadAuthSettings(
    LoadAuthSettingsEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isEnabled = await _authenticationService.isAuthenticationEnabled();
      final isAvailable =
          await _authenticationService.isAuthenticationAvailable();

      print(
        'Auth settings loaded - Enabled: $isEnabled, Available: $isAvailable',
      );

      emit(
        AuthSettingsLoaded(
          isEnabled: isEnabled,
          isBiometricAvailable: isAvailable,
        ),
      );
    } catch (e) {
      print('Error loading authentication settings: $e');
      emit(
        AuthError('Failed to load authentication settings: ${e.toString()}'),
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is BiometricNotAvailableFailure ||
        failure is AuthenticationNotAvailableFailure) {
      return 'Device authentication is not available. Please set up Face ID, Touch ID, fingerprint, or a device PIN/password.';
    } else if (failure is AuthenticationFailedFailure) {
      return 'Authentication was cancelled or failed. Please try again.';
    } else if (failure is AuthenticationErrorFailure) {
      return 'Authentication error: ${failure.message}';
    } else if (failure is CacheFailure) {
      return 'Failed to save authentication settings.';
    } else if (failure is ServerFailure) {
      return 'Authentication service error occurred.';
    } else {
      return 'An unexpected error occurred during authentication.';
    }
  }
}
