import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/services/dummy_data_service.dart';
import '../../../core/services/preference_service.dart';
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

    try {
      final result = await getAllTransactions(const NoParams());

      // Handle failure case
      if (result.isLeft()) {
        final failure = result.fold(
          (failure) => failure,
          (transactions) => null,
        );
        emit(TransactionError(message: _mapFailureToMessage(failure)));
        return;
      }

      // Extract transactions from result
      final transactions = result.fold<List<TransactionEntity>>(
        (failure) => [],
        (transactions) => transactions,
      );

      List<TransactionEntity> finalTransactions = [...transactions];

      // Check if we should show dummy data for first-time users
      try {
        final shouldShowDummy =
            await PreferenceService.instance.shouldShowDummyData();
        if (shouldShowDummy && transactions.isEmpty) {
          // Add dummy data for first-time users when no real transactions exist
          final dummyTransactions =
              DummyDataService.instance.createDummyTransactions();
          finalTransactions = [...dummyTransactions];
          print('📝 Showing dummy data for first-time user');
        }
      } catch (e) {
        print('Error checking dummy data preferences: $e');
        // Continue with normal flow if preference check fails
      }

      // Sort transactions by date (newest first)
      finalTransactions.sort((a, b) => b.date.compareTo(a.date));

      final groupedTransactions = _groupTransactionsByUser(finalTransactions);
      final totals = _calculateTotals(finalTransactions);

      emit(
        TransactionLoaded(
          transactions: finalTransactions,
          groupedTransactions: groupedTransactions,
          totalIOwe: totals['iOwe']!,
          totalOwesMe: totals['owesMe']!,
          isDummyData:
              finalTransactions.isNotEmpty &&
              finalTransactions.every((t) => t.id.startsWith('dummy_')),
        ),
      );
    } catch (e) {
      print('Error in _onLoadTransactions: $e');
      emit(const TransactionError(message: 'Failed to load transactions'));
    }
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
                  isDummyData: false, // Real-time data is never dummy
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
    try {
      final result = await addTransaction(
        AddTransactionParams(transaction: event.transaction),
      );

      // Handle failure case
      if (result.isLeft()) {
        final failure = result.fold((failure) => failure, (_) => null);
        emit(TransactionError(message: _mapFailureToMessage(failure)));
        return;
      }

      // Mark dummy data as viewed when user adds their first real transaction
      try {
        await PreferenceService.instance.markDummyDataViewed();
        print('✅ Dummy data cleared after first real transaction');
      } catch (e) {
        print('Error clearing dummy data: $e');
        // Continue even if clearing dummy data fails
      }

      emit(
        const TransactionOperationSuccess(
          message: 'Transaction added successfully',
        ),
      );
    } catch (e) {
      print('Error in _onAddTransaction: $e');
      emit(const TransactionError(message: 'Failed to add transaction'));
    }
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
