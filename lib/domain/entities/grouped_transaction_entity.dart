import 'transaction_entity.dart';

class GroupedTransactionEntity {
  final String userName;
  final List<TransactionEntity> transactions;
  final double totalIOwe;
  final double totalOwesMe;
  final DateTime lastTransactionDate;

  const GroupedTransactionEntity({
    required this.userName,
    required this.transactions,
    required this.totalIOwe,
    required this.totalOwesMe,
    required this.lastTransactionDate,
  });

  /// Net amount: positive means they owe me, negative means I owe them
  double get netAmount => totalOwesMe - totalIOwe;

  /// Returns true if the net amount means they owe me money
  bool get isInMyFavor => netAmount > 0;

  /// Returns true if the net amount means I owe them money
  bool get isInTheirFavor => netAmount < 0;

  /// Returns true if we're settled (no debt either way)
  bool get isSettled => netAmount == 0;

  /// Returns the absolute net amount for display
  double get absoluteNetAmount => netAmount.abs();

  /// Creates grouped transaction from a list of transactions for the same user
  factory GroupedTransactionEntity.fromTransactions(
    String userName,
    List<TransactionEntity> userTransactions,
  ) {
    double totalIOwe = 0;
    double totalOwesMe = 0;
    DateTime latestDate = userTransactions.first.date;

    for (final transaction in userTransactions) {
      if (transaction.type == TransactionType.iOwe) {
        totalIOwe += transaction.amount;
      } else {
        totalOwesMe += transaction.amount;
      }

      if (transaction.date.isAfter(latestDate)) {
        latestDate = transaction.date;
      }
    }

    return GroupedTransactionEntity(
      userName: userName,
      transactions: userTransactions,
      totalIOwe: totalIOwe,
      totalOwesMe: totalOwesMe,
      lastTransactionDate: latestDate,
    );
  }
}
