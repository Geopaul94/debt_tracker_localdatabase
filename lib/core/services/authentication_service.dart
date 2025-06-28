import 'package:dartz/dartz.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../error/failures.dart';

class AuthenticationService {
  static const String _authEnabledKey = 'auth_enabled';

  final LocalAuthentication _localAuth;
  final SharedPreferences _prefs;

  AuthenticationService._internal(this._localAuth, this._prefs);

  static AuthenticationService? _instance;

  static Future<AuthenticationService> create() async {
    if (_instance == null) {
      final localAuth = LocalAuthentication();
      final prefs = await SharedPreferences.getInstance();
      _instance = AuthenticationService._internal(localAuth, prefs);
    }
    return _instance!;
  }

  static AuthenticationService get instance {
    if (_instance == null) {
      throw Exception(
        'AuthenticationService not initialized. Call create() first.',
      );
    }
    return _instance!;
  }

  Future<Either<Failure, bool>> enableAuthentication() async {
    try {
      await _prefs.setBool(_authEnabledKey, true);
      return const Right(true);
    } catch (e) {
      print('Error enabling authentication: $e');
      return Left(CacheFailure());
    }
  }

  Future<Either<Failure, bool>> disableAuthentication() async {
    try {
      await _prefs.setBool(_authEnabledKey, false);
      return const Right(true);
    } catch (e) {
      print('Error disabling authentication: $e');
      return Left(CacheFailure());
    }
  }

  Future<bool> isAuthenticationEnabled() async {
    return _prefs.getBool(_authEnabledKey) ?? true; // Default enabled
  }

  Future<bool> isAuthenticationRequired() async {
    final isEnabled = await isAuthenticationEnabled();
    final isAvailable = await isBiometricAvailable();
    print('Auth enabled: $isEnabled, Available: $isAvailable');
    return isEnabled && isAvailable;
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      print('Can check biometrics: $isAvailable');
      print('Device supported: $isDeviceSupported');
      print('Available biometrics: $availableBiometrics');

      return isAvailable && isDeviceSupported && availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<Either<Failure, bool>> authenticate(String reason) async {
    try {
      print('Starting authentication process...');

      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('Biometric authentication not available');
        return Left(BiometricNotAvailableFailure());
      }

      print('Attempting biometric authentication...');
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN/password fallback
          stickyAuth: true,
        ),
      );

      print('Authentication result: $didAuthenticate');

      if (didAuthenticate) {
        return const Right(true);
      } else {
        return Left(AuthenticationFailedFailure());
      }
    } catch (e) {
      print('Authentication error: $e');
      return Left(AuthenticationErrorFailure(e.toString()));
    }
  }
}
