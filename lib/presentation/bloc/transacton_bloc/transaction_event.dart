import '../../../domain/entities/transaction_entity.dart';

abstract class TransactionEvent {
  const TransactionEvent();
}

class LoadTransactionsEvent extends TransactionEvent {
  const LoadTransactionsEvent();
}

class WatchTransactionsEvent extends TransactionEvent {
  const WatchTransactionsEvent();
}

class AddTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;

  const AddTransactionEvent({required this.transaction});
}

class UpdateTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;

  const UpdateTransactionEvent({required this.transaction});
}

class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;

  const DeleteTransactionEvent({required this.transactionId});
}
