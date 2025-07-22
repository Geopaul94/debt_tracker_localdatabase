import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

// Core
import '../core/database/database_helper.dart';
import '../core/services/ad_service.dart';
import '../core/services/currency_service.dart';
import '../core/services/authentication_service.dart';
import '../core/services/premium_service.dart';
import '../core/services/google_drive_service.dart';
import '../core/services/trash_service.dart';
import '../core/services/iap_service.dart';
import '../core/services/auto_backup_service.dart';
import '../core/services/connectivity_service.dart';
import '../core/utils/logger.dart';

// Data
import '../data/datasources/transaction_sqlite_data_source.dart';
import '../data/repositories/transaction_repository_impl.dart';

// Domain
import '../domain/repositories/transaction_repository.dart';
import '../domain/usecases/add_transaction.dart';
import '../domain/usecases/get_all_transactions.dart';
import '../domain/usecases/update_transaction.dart';
import '../domain/usecases/delete_transaction.dart';
import '../domain/usecases/watch_transactions.dart';

// Presentation
import '../presentation/bloc/transacton_bloc/transaction_bloc.dart';
import '../presentation/bloc/currency_bloc/currency_bloc.dart';
import '../presentation/bloc/authentication/auth_bloc.dart';

final serviceLocator = GetIt.instance;

Future<void> initializeDependencies() async {
  try {
    // Register core services as lazy singletons (they'll be initialized when first accessed)
    serviceLocator.registerLazySingleton(() => DatabaseHelper());
    serviceLocator.registerLazySingleton(() => AdService.instance);
    serviceLocator.registerLazySingleton(() => CurrencyService.instance);
    serviceLocator.registerLazySingleton(() => ConnectivityService.instance);

    // Register BLoCs immediately (these are lightweight and needed for UI)
    _registerBlocs();

    // Register data sources and repositories (lightweight)
    _registerDataSources();
    _registerRepositories();
    _registerUseCases();

    // Initialize critical services in parallel for faster startup
    final futures = <Future<void>>[];

    // Initialize Premium Service (non-blocking)
    futures.add(_initializePremiumService());

    // Initialize Authentication Service (non-blocking)
    futures.add(_initializeAuthenticationService());

    // Initialize other services in parallel
    futures.add(_initializeAdService());
    futures.add(_initializeCurrencyService());
    futures.add(_initializeConnectivityService());
    futures.add(_initializeGoogleDriveService());
    futures.add(_initializeTrashService());
    futures.add(_initializeIAPService());
    futures.add(_initializeAutoBackupService());

    // Wait for all services to initialize (or fail gracefully)
    await Future.wait(futures, eagerError: false);

    AppLogger.info('Dependencies initialized successfully');
  } catch (e) {
    AppLogger.error('Error initializing dependencies', e);
    rethrow; // Re-throw to let main.dart handle it
  }
}

// Check if all critical services are ready
bool areServicesReady() {
  try {
    // Check if essential services are registered
    serviceLocator<CurrencyBloc>();
    serviceLocator<TransactionBloc>();
    serviceLocator<AuthBloc>();
    return true;
  } catch (e) {
    return false;
  }
}

void _registerBlocs() {
  serviceLocator.registerFactory(
    () => TransactionBloc(
      getAllTransactions: serviceLocator(),
      addTransaction: serviceLocator(),
      updateTransaction: serviceLocator(),
      deleteTransaction: serviceLocator(),
      watchTransactions: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => CurrencyBloc(currencyService: serviceLocator()),
  );

  serviceLocator.registerFactory(
    () => AuthBloc(authenticationService: serviceLocator()),
  );
}

void _registerDataSources() {
  serviceLocator.registerLazySingleton<TransactionSQLiteDataSource>(
    () => TransactionSQLiteDataSourceImpl(databaseHelper: serviceLocator()),
  );
}

void _registerRepositories() {
  serviceLocator.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sqliteDataSource: serviceLocator()),
  );
}

void _registerUseCases() {
  serviceLocator.registerLazySingleton(
    () => GetAllTransactions(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => AddTransaction(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => UpdateTransaction(repository: serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => DeleteTransaction(repository: serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => WatchTransactions(serviceLocator()),
  );
}

Future<void> _initializePremiumService() async {
  try {
    final premiumService = await PremiumService.create();
    serviceLocator.registerLazySingleton<PremiumService>(
      () => premiumService,
    );
    AppLogger.info('Premium service initialized successfully');
  } catch (e) {
    AppLogger.error('Premium service initialization error', e);
    AppLogger.info(
      'Continuing without Premium service - premium features will be disabled',
    );
  }
}

Future<void> _initializeAuthenticationService() async {
  try {
    final authService = await AuthenticationService.create();
    serviceLocator.registerLazySingleton<AuthenticationService>(
      () => authService,
    );
    AppLogger.info('Authentication service initialized successfully');
  } catch (e) {
    AppLogger.error('Authentication service initialization error', e);
  }
}

Future<void> _initializeAdService() async {
  try {
    await AdService.instance.initialize();
    AppLogger.info('AdMob initialized successfully');
  } catch (e) {
    AppLogger.error('AdMob initialization error', e);
  }
}

Future<void> _initializeCurrencyService() async {
  try {
    await CurrencyService.instance.initialize();
    AppLogger.info('Currency service initialized successfully');
  } catch (e) {
    AppLogger.error('Currency service initialization error', e);
  }
}

Future<void> _initializeConnectivityService() async {
  try {
    await ConnectivityService.instance.initialize();
    AppLogger.info('Connectivity service initialized successfully');
  } catch (e) {
    AppLogger.error('Connectivity service initialization error', e);
  }
}

Future<void> _initializeGoogleDriveService() async {
  try {
    await GoogleDriveService.instance.initialize();
    AppLogger.info('Google Drive service initialized successfully');
  } catch (e) {
    AppLogger.error('Google Drive service initialization error', e);
  }
}

Future<void> _initializeTrashService() async {
  try {
    await TrashService.instance.initialize();
    AppLogger.info('Trash service initialized successfully');
  } catch (e) {
    AppLogger.error('Trash service initialization error', e);
  }
}

Future<void> _initializeIAPService() async {
  try {
    await IAPService.instance.initialize();
    AppLogger.info('IAP service initialized successfully');
  } catch (e) {
    AppLogger.error('IAP service initialization error', e);
  }
}

Future<void> _initializeAutoBackupService() async {
  try {
    await AutoBackupService.instance.initialize();
    AppLogger.info('Auto backup service initialized successfully');
  } catch (e) {
    AppLogger.error('Auto backup service initialization error', e);
  }
}
