import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/grouped_transaction_entity.dart';
import '../../../domain/usecases/add_transaction.dart';
import '../../../domain/usecases/get_all_transactions.dart';
import '../../../domain/usecases/update_transaction.dart';
import '../../../domain/usecases/delete_transaction.dart';
import '../../../domain/usecases/watch_transactions.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetAllTransactions getAllTransactions;
  final AddTransaction addTransaction;
  final UpdateTransaction updateTransaction;
  final DeleteTransaction deleteTransaction;
  final WatchTransactions watchTransactions;

  StreamSubscription? _transactionSubscription;

  TransactionBloc({
    required this.getAllTransactions,
    required this.addTransaction,
    required this.updateTransaction,
    required this.deleteTransaction,
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
        // Sort transactions by date (newest first)
        final sortedTransactions = [...transactions];
        sortedTransactions.sort((a, b) => b.date.compareTo(a.date));

        final groupedTransactions = _groupTransactionsByUser(
          sortedTransactions,
        );
        final totals = _calculateTotals(sortedTransactions);
        emit(
          TransactionLoaded(
            transactions: sortedTransactions,
            groupedTransactions: groupedTransactions,
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
              final groupedTransactions = _groupTransactionsByUser(
                transactions,
              );
              final totals = _calculateTotals(transactions);
              emit(
                TransactionLoaded(
                  transactions: transactions,
                  groupedTransactions: groupedTransactions,
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
    final result = await updateTransaction(
      UpdateTransactionParams(transaction: event.transaction),
    );

    result.fold(
      (failure) =>
          emit(TransactionError(message: _mapFailureToMessage(failure))),
      (_) => emit(
        const TransactionOperationSuccess(
          message: 'Transaction updated successfully',
        ),
      ),
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await deleteTransaction(
      DeleteTransactionParams(transactionId: event.transactionId),
    );

    result.fold(
      (failure) =>
          emit(TransactionError(message: _mapFailureToMessage(failure))),
      (_) => emit(
        const TransactionOperationSuccess(
          message: 'Transaction deleted successfully',
        ),
      ),
    );
  }

  Map<String, double> _calculateTotals(List<TransactionEntity> transactions) {
    double totalIOwe = 0;
    double totalOwesMe = 0;

    // Include all transactions and treat amounts as equivalent in default currency
    // In a real app, you would convert using exchange rates here
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.iOwe) {
        totalIOwe += transaction.amount;
      } else {
        totalOwesMe += transaction.amount;
      }
    }

    return {'iOwe': totalIOwe, 'owesMe': totalOwesMe};
  }

  List<GroupedTransactionEntity> _groupTransactionsByUser(
    List<TransactionEntity> transactions,
  ) {
    final Map<String, List<TransactionEntity>> groupedMap = {};

    // Group transactions by user name
    for (final transaction in transactions) {
      if (groupedMap.containsKey(transaction.name)) {
        groupedMap[transaction.name]!.add(transaction);
      } else {
        groupedMap[transaction.name] = [transaction];
      }
    }

    // Convert to GroupedTransactionEntity and sort by last transaction date
    final groupedList =
        groupedMap.entries.map((entry) {
          return GroupedTransactionEntity.fromTransactions(
            entry.key,
            entry.value,
          );
        }).toList();

    // Sort by last transaction date (newest first)
    groupedList.sort(
      (a, b) => b.lastTransactionDate.compareTo(a.lastTransactionDate),
    );

    return groupedList;
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
