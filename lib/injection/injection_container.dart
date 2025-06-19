import 'package:get_it/get_it.dart';

// Core
import '../core/database/database_helper.dart';
import '../core/services/ad_service.dart';

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
import '../presentation/bloc/transaction_bloc.dart';

final serviceLocator = GetIt.instance;

Future<void> initializeDependencies() async {
  try {
    // External dependencies
    serviceLocator.registerLazySingleton(() => DatabaseHelper());
    serviceLocator.registerLazySingleton(() => AdService.instance);

    // Initialize AdMob
    try {
      await AdService.instance.initialize();
      await AdService.instance.loadInterstitialAd();
      await AdService.instance.loadRewardedAd(); // Preload rewarded ads
      print('AdMob initialized successfully');
    } catch (e) {
      print('AdMob initialization error: $e');
      // Continue without ads
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

    print('Dependencies initialized successfully');
  } catch (e) {
    print('Error initializing dependencies: $e');
    throw e; // Re-throw to let main.dart handle it
  }
}
