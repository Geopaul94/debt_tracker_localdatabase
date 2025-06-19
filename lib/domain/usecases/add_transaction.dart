import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class AddTransaction implements UseCase<void, AddTransactionParams> {
  final TransactionRepository repository;

  AddTransaction(this.repository);

  @override
  Future<Either<Failure, void>> call(AddTransactionParams params) async {
    return await repository.addTransaction(params.transaction);
  }
}

class AddTransactionParams {
  final TransactionEntity transaction;

  AddTransactionParams({required this.transaction});
}
