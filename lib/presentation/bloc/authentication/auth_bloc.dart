import 'package:debt_tracker/presentation/bloc/authentication/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_event.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LocalAuthentication _auth = LocalAuthentication();

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<SetAuthEnabledEvent>(_onSetAuthEnabled);
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('auth_enabled') ?? true;
    if (!isEnabled) {
      emit( AuthEnabledState(true)); // Skip auth
      return;
    }

    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        emit(AuthFailed("Biometric authentication not supported"));
        return;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailed("Authentication failed"));
      }
    } catch (e) {
      emit(AuthFailed("Error: ${e.toString()}"));
    }
  }

  Future<void> _onSetAuthEnabled(SetAuthEnabledEvent event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_enabled', event.enabled);
  }
}
