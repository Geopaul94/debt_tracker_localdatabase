import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = false;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    try {
      // Check initial connectivity status
      await _checkConnectivity();

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
      );

      AppLogger.info('Connectivity service initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize connectivity service', e);
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResults);
    } catch (e) {
      AppLogger.error('Error checking connectivity', e);
      _isConnected = false;
    }
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(List<ConnectivityResult> connectivityResults) {
    _isConnected = connectivityResults.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    AppLogger.info(
      'Connectivity status updated: ${_isConnected ? 'Connected' : 'Disconnected'}',
    );
  }

  /// Check if device has internet connection
  bool get isConnected => _isConnected;

  /// Get current connectivity status asynchronously
  Future<bool> checkInternetConnection() async {
    try {
      await _checkConnectivity();
      return _isConnected;
    } catch (e) {
      AppLogger.error('Error checking internet connection', e);
      return false;
    }
  }

  /// Dispose of the service
  void dispose() {
    _connectivitySubscription?.cancel();
    AppLogger.info('Connectivity service disposed');
  }
}
