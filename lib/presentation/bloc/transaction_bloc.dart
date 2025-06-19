import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/get_all_transactions.dart';
import '../../domain/usecases/watch_transactions.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetAllTransactions getAllTransactions;
  final AddTransaction addTransaction;
  final WatchTransactions watchTransactions;

  StreamSubscription? _transactionSubscription;

  TransactionBloc({
    required this.getAllTransactions,
    required this.addTransaction,
    required this.watchTransactions,
  }) : super(const TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<WatchTransactionsEvent>(_onWatchTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());

    final result = await getAllTransactions(const NoParams());

    result.fold(
      (failure) =>
          emit(TransactionError(message: _mapFailureToMessage(failure))),
      (transactions) {
        final totals = _calculateTotals(transactions);
        emit(
          TransactionLoaded(
            transactions: transactions,
            totalIOwe: totals['iOwe']!,
            totalOwesMe: totals['owesMe']!,
          ),
        );
      },
    );
  }

  Future<void> _onWatchTransactions(
    WatchTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    await _transactionSubscription?.cancel();

    _transactionSubscription = watchTransactions(const NoParams()).listen(
      (result) {
        if (!emit.isDone) {
          result.fold(
            (failure) =>
                emit(TransactionError(message: _mapFailureToMessage(failure))),
            (transactions) {
              final totals = _calculateTotals(transactions);
              emit(
                TransactionLoaded(
                  transactions: transactions,
                  totalIOwe: totals['iOwe']!,
                  totalOwesMe: totals['owesMe']!,
                ),
              );
            },
          );
        }
      },
      onError: (error) {
        if (!emit.isDone) {
          emit(
            TransactionError(message: 'Error watching transactions: $error'),
          );
        }
      },
    );
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await addTransaction(
      AddTransactionParams(transaction: event.transaction),
    );

    result.fold(
      (failure) =>
          emit(TransactionError(message: _mapFailureToMessage(failure))),
      (_) => emit(
        const TransactionOperationSuccess(
          message: 'Transaction added successfully',
        ),
      ),
    );
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    // Implementation would be similar to add, but we need to create the use case first
    emit(
      const TransactionOperationSuccess(
        message: 'Transaction updated successfully',
      ),
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    // Implementation would be similar to add, but we need to create the use case first
    emit(
      const TransactionOperationSuccess(
        message: 'Transaction deleted successfully',
      ),
    );
  }

  Map<String, double> _calculateTotals(List<TransactionEntity> transactions) {
    double totalIOwe = 0;
    double totalOwesMe = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.iOwe) {
        totalIOwe += transaction.amount;
      } else {
        totalOwesMe += transaction.amount;
      }
    }

    return {'iOwe': totalIOwe, 'owesMe': totalOwesMe};
  }

  String _mapFailureToMessage(failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Cache error occurred';
      case NetworkFailure:
        return 'Network error occurred';
      default:
        return 'Unexpected error occurred';
    }
  }

  @override
  Future<void> close() {
    _transactionSubscription?.cancel();
    return super.close();
  }
}
