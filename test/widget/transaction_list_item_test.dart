import 'package:debt_tracker/core/services/currency_service.dart';
import 'package:debt_tracker/domain/entities/transaction_entity.dart';
import 'package:debt_tracker/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TransactionListItem Widget Tests', () {
    late TransactionEntity testTransaction;

    setUp(() async {
      // Set up mock shared preferences for CurrencyService
      SharedPreferences.setMockInitialValues({
        'selected_currency_code': 'USD',
        'selected_currency_symbol': '\$',
        'selected_currency_name': 'US Dollar',
        'selected_currency_flag': '🇺🇸',
      });

      // Initialize currency service
      await CurrencyService.instance.initialize();

      testTransaction = TransactionEntity(
        id: '1',
        name: 'John Doe',
        description: 'Test transaction',
        amount: 50.0,
        type: TransactionType.iOwe,
        date: DateTime.now(),
      );
    });

    Widget createTestWidget(TransactionEntity transaction) {
      return ScreenUtilInit(
        designSize: const Size(375, 812), // Standard iPhone 11 size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              body: TransactionListItem(transaction: transaction, onTap: () {}),
            ),
          );
        },
      );
    }

    testWidgets('should display transaction details correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testTransaction));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Test transaction'), findsOneWidget);
      // Test for the actual formatted amount with currency symbol and sign
      expect(find.text('-\$50.00'), findsOneWidget);
    });

    testWidgets('should display transaction with proper styling', (
      WidgetTester tester,
    ) async {
      final sampleTransaction = TransactionEntity(
        id: '1',
        name: 'Alex Johnson',
        description: 'Lunch at downtown cafe',
        amount: 25.50,
        type: TransactionType.iOwe,
        date: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(sampleTransaction));
      await tester.pumpAndSettle();

      expect(find.text('Alex Johnson'), findsOneWidget);
      expect(find.text('Lunch at downtown cafe'), findsOneWidget);
      expect(find.text('-\$25.50'), findsOneWidget);
    });

    testWidgets('should handle long text with ellipsis', (
      WidgetTester tester,
    ) async {
      final longTextTransaction = TransactionEntity(
        id: '2',
        name: 'Very Long Name That Should Be Truncated With Ellipsis',
        description:
            'This is a very long description that should also be truncated with ellipsis when displayed',
        amount: 100.0,
        type: TransactionType.owesMe,
        date: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(longTextTransaction));
      await tester.pumpAndSettle();

      // The text should be truncated but still findable
      expect(find.byType(Text), findsAtLeastNWidgets(3));
      // Check the amount is properly formatted for "owes me" type
      expect(find.text('+\$100.00'), findsOneWidget);
    });

    testWidgets('should respond to tap events', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              home: Scaffold(
                body: TransactionListItem(
                  transaction: testTransaction,
                  onTap: () {
                    tapped = true;
                  },
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TransactionListItem));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should display correct amount formatting', (
      WidgetTester tester,
    ) async {
      final decimalTransaction = TransactionEntity(
        id: '3',
        name: 'Decimal Test',
        description: 'Testing decimal formatting',
        amount: 123.45,
        type: TransactionType.iOwe,
        date: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(decimalTransaction));
      await tester.pumpAndSettle();

      expect(find.text('-\$123.45'), findsOneWidget);
    });

    testWidgets('should handle zero amount', (WidgetTester tester) async {
      final zeroTransaction = TransactionEntity(
        id: '4',
        name: 'Zero Amount',
        description: 'Zero amount test',
        amount: 0.0,
        type: TransactionType.owesMe,
        date: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(zeroTransaction));
      await tester.pumpAndSettle();

      expect(find.text('+\$0.00'), findsOneWidget);
    });

    testWidgets('should display different transaction types', (
      WidgetTester tester,
    ) async {
      final owesTransaction = TransactionEntity(
        id: '5',
        name: 'Test User',
        description: 'Someone owes me',
        amount: 75.0,
        type: TransactionType.owesMe,
        date: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(owesTransaction));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Someone owes me'), findsOneWidget);
      expect(find.text('+\$75.00'), findsOneWidget);
    });
  });
}
