import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/grouped_transaction_entity.dart';

abstract class TransactionState {
  const TransactionState();
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final List<GroupedTransactionEntity> groupedTransactions;
  final double totalIOwe;
  final double totalOwesMe;

  const TransactionLoaded({
    required this.transactions,
    required this.groupedTransactions,
    required this.totalIOwe,
    required this.totalOwesMe,
  });

  double get netAmount => totalOwesMe - totalIOwe;
}

class TransactionOperationSuccess extends TransactionState {
  final String message;

  const TransactionOperationSuccess({required this.message});
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError({required this.message});
}
