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
    final isAvailable = await isAuthenticationAvailable();
    print('Auth enabled: $isEnabled, Available: $isAvailable');
    return isEnabled && isAvailable;
  }

  /// Checks if ANY form of authentication is available on the device
  /// This includes biometric authentication (Face ID, Touch ID, fingerprint)
  /// AND device credentials (PIN, pattern, password)
  Future<bool> isAuthenticationAvailable() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      print('Device supported: $isDeviceSupported');

      if (!isDeviceSupported) {
        return false;
      }

      // Check if biometrics are available
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      print('Can check biometrics: $canCheckBiometrics');
      print('Available biometrics: $availableBiometrics');

      // If biometrics are available, device can authenticate
      if (canCheckBiometrics && availableBiometrics.isNotEmpty) {
        print('Biometric authentication available');
        return true;
      }

      // If device is supported but no biometrics, check if device credentials are available
      // For Android/iOS, if device is supported and biometrics can't be checked,
      // it usually means device credentials (PIN, pattern, password) are available
      if (isDeviceSupported) {
        // On supported devices, authentication is generally available even without biometrics
        // The local_auth plugin will fall back to device credentials (PIN, pattern, password)
        print('Device credentials authentication available');
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking authentication availability: $e');
      return false;
    }
  }

  /// Legacy method name for backward compatibility
  Future<bool> isBiometricAvailable() async {
    return await isAuthenticationAvailable();
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

      final isAvailable = await isAuthenticationAvailable();
      if (!isAvailable) {
        print('Authentication not available');
        return Left(AuthenticationNotAvailableFailure());
      }

      print('Attempting authentication...');
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
