import '../../domain/entities/transaction_entity.dart';
import '../constants/currencies.dart';

class DummyDataService {
  static final DummyDataService _instance = DummyDataService._internal();
  static DummyDataService get instance => _instance;
  DummyDataService._internal();

  /// Creates sample transactions for first-time users to demonstrate the app
  List<TransactionEntity> createDummyTransactions() {
    final now = DateTime.now();
    final defaultCurrency = CurrencyConstants.defaultCurrency;
    final usdCurrency = TransactionCurrency(
      code: defaultCurrency.code,
      symbol: defaultCurrency.symbol,
      name: defaultCurrency.name,
      flag: defaultCurrency.flag,
    );

    return [
      // Recent transactions
      TransactionEntity(
        id: 'dummy_1',
        name: 'Alex Johnson',
        amount: 85.50,
        description: 'Dinner at restaurant',
        type: TransactionType.iOwe,
        date: now.subtract(const Duration(days: 1)),
        currency: usdCurrency,
        attachments: [],
      ),
      TransactionEntity(
        id: 'dummy_2',
        name: 'Sarah Miller',
        amount: 25.00,
        description: 'Movie tickets',
        type: TransactionType.owesMe,
        date: now.subtract(const Duration(days: 2)),
        currency: usdCurrency,
        attachments: [],
      ),
      TransactionEntity(
        id: 'dummy_3',
        name: 'Mike Davis',
        amount: 120.75,
        description: 'Shared grocery shopping',
        type: TransactionType.iOwe,
        date: now.subtract(const Duration(days: 3)),
        currency: usdCurrency,
        attachments: [],
      ),
      TransactionEntity(
        id: 'dummy_4',
        name: 'Emma Wilson',
        amount: 45.25,
        description: 'Gas money for trip',
        type: TransactionType.owesMe,
        date: now.subtract(const Duration(days: 5)),
        currency: usdCurrency,
        attachments: [],
      ),
      TransactionEntity(
        id: 'dummy_5',
        name: 'Alex Johnson',
        amount: 15.50,
        description: 'Coffee and snacks',
        type: TransactionType.owesMe,
        date: now.subtract(const Duration(days: 7)),
        currency: usdCurrency,
        attachments: [],
      ),
      TransactionEntity(
        id: 'dummy_6',
        name: 'Sarah Miller',
        amount: 200.00,
        description: 'Weekend accommodation',
        type: TransactionType.iOwe,
        date: now.subtract(const Duration(days: 10)),
        currency: usdCurrency,
        attachments: [],
      ),
    ];
  }

  /// Check if a transaction is dummy data by its ID
  static bool isDummyTransaction(TransactionEntity transaction) {
    return transaction.id.startsWith('dummy_');
  }

  /// Check if a transaction ID represents dummy data
  static bool isDummyTransactionId(String id) {
    return id.startsWith('dummy_');
  }

  /// Filter out dummy transactions from a list
  static List<TransactionEntity> filterOutDummyData(
    List<TransactionEntity> transactions,
  ) {
    return transactions
        .where((transaction) => !isDummyTransaction(transaction))
        .toList();
  }

  /// Get summary of dummy data for display purposes
  Map<String, dynamic> getDummyDataSummary() {
    final transactions = createDummyTransactions();

    double totalIOwe = 0;
    double totalOwesMe = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.iOwe) {
        totalIOwe += transaction.amount;
      } else {
        totalOwesMe += transaction.amount;
      }
    }

    return {
      'transactions': transactions,
      'totalIOwe': totalIOwe,
      'totalOwesMe': totalOwesMe,
      'netAmount': totalOwesMe - totalIOwe,
      'count': transactions.length,
    };
  }
}
