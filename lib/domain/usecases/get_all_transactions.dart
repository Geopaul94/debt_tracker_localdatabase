import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class GetAllTransactions implements UseCase<List<TransactionEntity>, NoParams> {
  final TransactionRepository repository;

  GetAllTransactions(this.repository);

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(NoParams params) async {
    return await repository.getAllTransactions();
  }
}
