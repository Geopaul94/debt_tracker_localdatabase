import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class WatchTransactions
    implements StreamUseCase<List<TransactionEntity>, NoParams> {
  final TransactionRepository repository;

  WatchTransactions(this.repository);

  @override
  Stream<Either<Failure, List<TransactionEntity>>> call(NoParams params) {
    return repository.watchTransactions();
  }
}
