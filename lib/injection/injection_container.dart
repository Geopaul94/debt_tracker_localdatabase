import 'package:get_it/get_it.dart';

// Core
import '../core/database/database_helper.dart';
import '../core/services/ad_service.dart';
import '../core/services/currency_service.dart';

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

final serviceLocator = GetIt.instance;

Future<void> initializeDependencies() async {
  try {
    // External dependencies
    serviceLocator.registerLazySingleton(() => DatabaseHelper());
    serviceLocator.registerLazySingleton(() => AdService.instance);
    serviceLocator.registerLazySingleton(() => CurrencyService.instance);

    // Initialize AdMob
    try {
      await AdService.instance.initialize();
      print('AdMob initialized successfully');
    } catch (e) {
      print('AdMob initialization error: $e');
      // Continue without ads
    }

    // Initialize Currency Service
    try {
      await CurrencyService.instance.initialize();
      print('Currency service initialized successfully');
    } catch (e) {
      print('Currency service initialization error: $e');
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

    print('Dependencies initialized successfully');
  } catch (e) {
    print('Error initializing dependencies: $e');
    rethrow; // Re-throw to let main.dart handle it
  }
}
