import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../core/services/trash_service.dart';
import '../repositories/transaction_repository.dart';

class DeleteTransaction implements UseCase<void, DeleteTransactionParams> {
  final TransactionRepository repository;

  DeleteTransaction({required this.repository});

  @override
  Future<Either<Failure, void>> call(DeleteTransactionParams params) async {
    try {
      // Use soft delete by moving to trash instead of permanent deletion
      final success = await TrashService.instance.moveToTrash(
        params.transactionId,
      );
      if (success) {
        return const Right(null);
      } else {
        return Left(ServerFailure());
      }
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}

class DeleteTransactionParams {
  final String transactionId;

  DeleteTransactionParams({required this.transactionId});
}
