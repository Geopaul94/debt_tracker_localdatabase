import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

// Core
import '../core/database/database_helper.dart';
import '../core/services/ad_service.dart';
import '../core/services/currency_service.dart';
import '../core/services/authentication_service.dart';
import '../core/services/premium_service.dart';

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
    // External dependencies
    serviceLocator.registerLazySingleton(() => DatabaseHelper());
    serviceLocator.registerLazySingleton(() => AdService.instance);
    serviceLocator.registerLazySingleton(() => CurrencyService.instance);

    // Initialize Premium Service
    try {
      final premiumService = await PremiumService.create();
      serviceLocator.registerLazySingleton<PremiumService>(
        () => premiumService,
      );
      if (kDebugMode) {
        print('Premium service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Premium service initialization error: $e');
        print(
          'Continuing without Premium service - premium features will be disabled',
        );
      }
      // Continue without premium service - the app will handle missing service gracefully
    }

    // Initialize Authentication Service
    try {
      final authService = await AuthenticationService.create();
      serviceLocator.registerLazySingleton<AuthenticationService>(
        () => authService,
      );
      if (kDebugMode) {
        print('Authentication service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Authentication service initialization error: $e');
      }
      // Continue without authentication
    }

    // Initialize AdMob
    try {
      await AdService.instance.initialize();
      if (kDebugMode) {
        print('AdMob initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AdMob initialization error: $e');
      }
      // Continue without ads
    }

    // Initialize Currency Service
    try {
      await CurrencyService.instance.initialize();
      if (kDebugMode) {
        print('Currency service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Currency service initialization error: $e');
      }
      // Continue with default currency
    }

    // Data sources
    serviceLocator.registerLazySingleton<TransactionSQLiteDataSource>(
      () => TransactionSQLiteDataSourceImpl(databaseHelper: serviceLocator()),
    );

    // Repositories
    serviceLocator.registerLazySingleton<TransactionRepository>(
      () => TransactionRepositoryImpl(sqliteDataSource: serviceLocator()),
    );

    // Use cases
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

    // BLoC
    serviceLocator.registerFactory(
      () => TransactionBloc(
        getAllTransactions: serviceLocator(),
        addTransaction: serviceLocator(),
        updateTransaction: serviceLocator(),
        deleteTransaction: serviceLocator(),
        watchTransactions: serviceLocator(),
      ),
    );

    // Currency BLoC
    serviceLocator.registerFactory(
      () => CurrencyBloc(currencyService: serviceLocator()),
    );

    // Authentication BLoC
    serviceLocator.registerFactory(
      () => AuthBloc(authenticationService: serviceLocator()),
    );

    if (kDebugMode) {
      print('Dependencies initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing dependencies: $e');
    }
    rethrow; // Re-throw to let main.dart handle it
  }
}
