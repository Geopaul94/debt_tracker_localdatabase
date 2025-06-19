import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransaction implements UseCase<void, UpdateTransactionParams> {
  final TransactionRepository repository;

  UpdateTransaction({required this.repository});

  @override
  Future<Either<Failure, void>> call(UpdateTransactionParams params) async {
    return await repository.updateTransaction(params.transaction);
  }
}

class UpdateTransactionParams {
  final TransactionEntity transaction;

  UpdateTransactionParams({required this.transaction});
}
