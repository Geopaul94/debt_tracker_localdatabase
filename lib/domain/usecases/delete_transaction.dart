import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/transaction_repository.dart';

class DeleteTransaction implements UseCase<void, DeleteTransactionParams> {
  final TransactionRepository repository;

  DeleteTransaction({required this.repository});

  @override
  Future<Either<Failure, void>> call(DeleteTransactionParams params) async {
    return await repository.deleteTransaction(params.transactionId);
  }
}

class DeleteTransactionParams {
  final String transactionId;

  DeleteTransactionParams({required this.transactionId});
}
