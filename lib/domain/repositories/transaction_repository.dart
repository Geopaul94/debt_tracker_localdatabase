import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions();
  Future<Either<Failure, TransactionEntity>> getTransactionById(String id);
  Future<Either<Failure, void>> addTransaction(TransactionEntity transaction);
  Future<Either<Failure, void>> updateTransaction(
    TransactionEntity transaction,
  );
  Future<Either<Failure, void>> deleteTransaction(String id);
  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions();
}
