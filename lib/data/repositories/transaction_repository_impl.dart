import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_sqlite_data_source.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionSQLiteDataSource sqliteDataSource;

  TransactionRepositoryImpl({required this.sqliteDataSource});

  @override
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions() async {
    try {
      final sqliteTransactions = await sqliteDataSource.getAllTransactions();
      return Right(
        sqliteTransactions.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(
    String id,
  ) async {
    try {
      final sqliteTransaction = await sqliteDataSource.getTransactionById(id);
      if (sqliteTransaction != null) {
        return Right(sqliteTransaction.toEntity());
      } else {
        return Left(TransactionNotFoundFailure());
      }
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final transactionModel = TransactionModel.fromEntity(transaction);
      await sqliteDataSource.saveTransaction(transactionModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final transactionModel = TransactionModel.fromEntity(transaction);
      await sqliteDataSource.updateTransaction(transactionModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await sqliteDataSource.deleteTransaction(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions() {
    try {
      return sqliteDataSource.watchTransactions().map(
        (transactions) => Right<Failure, List<TransactionEntity>>(
          transactions.map((model) => model.toEntity()).toList(),
        ),
      );
    } catch (e) {
      return Stream.value(Left(CacheFailure()));
    }
  }

  // Additional methods for advanced features
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByType(
    TransactionType type,
  ) async {
    try {
      final transactions = await sqliteDataSource.getTransactionsByType(type);
      return Right(transactions.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final transactions = await sqliteDataSource.getTransactionsByDateRange(
        start,
        end,
      );
      return Right(transactions.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  Future<Either<Failure, List<TransactionEntity>>> searchTransactions(
    String query,
  ) async {
    try {
      final transactions = await sqliteDataSource.searchTransactions(query);
      return Right(transactions.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  Future<Either<Failure, Map<String, double>>> getTransactionSummary() async {
    try {
      final summary = await sqliteDataSource.getTransactionSummary();
      return Right(summary);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
