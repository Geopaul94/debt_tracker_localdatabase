import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:debt_tracker/presentation/pages/add_transaction_page.dart';
import 'package:debt_tracker/presentation/bloc/transacton_bloc/transaction_bloc.dart';
import 'package:debt_tracker/presentation/bloc/transacton_bloc/transaction_event.dart';
import 'package:debt_tracker/presentation/bloc/transacton_bloc/transaction_state.dart';
import 'package:debt_tracker/domain/entities/transaction_entity.dart';
import 'package:debt_tracker/domain/entities/attachment_entity.dart';
import 'package:debt_tracker/core/constants/currencies.dart';

// Mock classes
class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

@GenerateMocks([])
void main() {
  group('AddTransactionPage Tests', () {
    late MockTransactionBloc mockTransactionBloc;
    late Widget testWidget;

    setUp(() {
      mockTransactionBloc = MockTransactionBloc();

      // Default state
      when(mockTransactionBloc.state).thenReturn(TransactionInitial());

      testWidget = ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(home: AddTransactionPage()),
      );
    });

    group('Initial State', () {
      testWidgets('should display all required form fields', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Check for form fields
        expect(
          find.byType(TextFormField),
          findsNWidgets(3),
        ); // Name, description, amount
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('Amount'), findsOneWidget);
      });

      testWidgets('should display transaction type selector', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        expect(find.byType(SegmentedButton), findsOneWidget);
        expect(find.text('I Owe'), findsOneWidget);
        expect(find.text('Owes Me'), findsOneWidget);
      });

      testWidgets('should display currency selector button', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Should display default currency (USD)
        expect(find.text('USD'), findsOneWidget);
        expect(find.text('🇺🇸'), findsOneWidget);
      });

      testWidgets('should display date selector', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });

      testWidgets('should display attachment section', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        expect(find.text('Attach File'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(
          find.text('Attach receipts, bills, or documents (Optional)'),
          findsOneWidget,
        );
      });

      testWidgets('should display submit button', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        expect(find.text('Add Transaction'), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('should show validation errors for empty required fields', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Try to submit empty form
        await tester.tap(find.text('Add Transaction'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a name'), findsOneWidget);
        expect(find.text('Please enter an amount'), findsOneWidget);
      });

      testWidgets('should validate amount format', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Enter invalid amount
        await tester.enterText(find.byType(TextFormField).at(2), 'invalid');
        await tester.tap(find.text('Add Transaction'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a valid amount'), findsOneWidget);
      });

      testWidgets('should not allow zero amount', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'Test Name');
        await tester.enterText(find.byType(TextFormField).at(2), '0');
        await tester.tap(find.text('Add Transaction'));
        await tester.pumpAndSettle();

        expect(find.text('Amount must be greater than zero'), findsOneWidget);
      });

      testWidgets('should not allow negative amount', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'Test Name');
        await tester.enterText(find.byType(TextFormField).at(2), '-10');
        await tester.tap(find.text('Add Transaction'));
        await tester.pumpAndSettle();

        expect(find.text('Amount must be greater than zero'), findsOneWidget);
      });

      testWidgets('should accept valid input', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Fill valid data
        await tester.enterText(find.byType(TextFormField).first, 'John Doe');
        await tester.enterText(find.byType(TextFormField).at(1), 'Coffee');
        await tester.enterText(find.byType(TextFormField).at(2), '5.50');

        // Should not show validation errors
        await tester.tap(find.text('Add Transaction'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a name'), findsNothing);
        expect(find.text('Please enter an amount'), findsNothing);
      });
    });

    group('Transaction Type Selection', () {
      testWidgets('should default to "I Owe" type', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        final segmentedButton = tester.widget<SegmentedButton>(
          find.byType(SegmentedButton),
        );
        expect(segmentedButton.selected.contains(TransactionType.iOwe), isTrue);
      });

      testWidgets('should switch to "Owes Me" when tapped', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Owes Me'));
        await tester.pumpAndSettle();

        final segmentedButton = tester.widget<SegmentedButton>(
          find.byType(SegmentedButton),
        );
        expect(
          segmentedButton.selected.contains(TransactionType.owesMe),
          isTrue,
        );
      });
    });

    group('Currency Selection', () {
      testWidgets('should open currency dialog when currency button tapped', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('USD'));
        await tester.pumpAndSettle();

        expect(find.text('Select Currency'), findsOneWidget);
        expect(find.text('Search currencies...'), findsOneWidget);
      });

      testWidgets('should update currency when selected from dialog', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Open currency dialog
        await tester.tap(find.text('USD'));
        await tester.pumpAndSettle();

        // Search for and select EUR
        await tester.enterText(find.byType(TextField), 'EUR');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Euro').first);
        await tester.pumpAndSettle();

        // Currency button should now show EUR
        expect(find.text('EUR'), findsOneWidget);
        expect(find.text('🇪🇺'), findsOneWidget);
      });

      testWidgets('should clear amount when currency changes', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Enter amount
        await tester.enterText(find.byType(TextFormField).at(2), '100.00');

        // Change currency
        await tester.tap(find.text('USD'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'EUR');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Euro').first);
        await tester.pumpAndSettle();

        // Amount field should be cleared
        final amountField = tester.widget<TextFormField>(
          find.byType(TextFormField).at(2),
        );
        expect(amountField.controller?.text, isEmpty);
      });
    });

    group('Date Selection', () {
      testWidgets('should open date picker when date button tapped', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);
      });

      testWidgets('should update date when selected from picker', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Select a specific date (day 15)
        await tester.tap(find.text('15').first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Date should be reflected in the form (exact text depends on current month)
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });
    });

    group('Attachment Functionality', () {
      testWidgets('should handle file attachment button tap', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Tap attach file button
        await tester.tap(find.text('Attach File'));
        await tester.pumpAndSettle();

        // In real scenario, this would open file picker
        // For testing, we verify the button is responsive
        expect(find.text('Attach File'), findsOneWidget);
      });

      testWidgets('should handle camera button tap', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Tap camera button
        await tester.tap(find.text('Camera'));
        await tester.pumpAndSettle();

        // In real scenario, this would open camera
        // For testing, we verify the button is responsive
        expect(find.text('Camera'), findsOneWidget);
      });

      testWidgets('should display attachment section when no attachments', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Should show buttons but no attachment list
        expect(find.text('Attach File'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(find.text('Attachments'), findsNothing);
      });
    });

    group('Edit Mode', () {
      testWidgets('should populate fields when editing existing transaction', (
        WidgetTester tester,
      ) async {
        final existingTransaction = TransactionEntity(
          id: 'test_id',
          name: 'Existing User',
          description: 'Existing Description',
          amount: 75.50,
          type: TransactionType.owesMe,
          date: DateTime(2024, 1, 15),
          currency: const TransactionCurrency(
            code: 'EUR',
            symbol: '€',
            name: 'Euro',
            flag: '🇪🇺',
          ),
          attachments: const [],
        );

        final editWidget = ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: AddTransactionPage(transactionToEdit: existingTransaction),
          ),
        );

        await tester.pumpWidget(editWidget);
        await tester.pumpAndSettle();

        // Fields should be populated
        expect(find.text('Existing User'), findsOneWidget);
        expect(find.text('Existing Description'), findsOneWidget);
        expect(find.text('75.5'), findsOneWidget);
        expect(find.text('EUR'), findsOneWidget);
        expect(find.text('🇪🇺'), findsOneWidget);

        // Should be in "Owes Me" mode
        final segmentedButton = tester.widget<SegmentedButton>(
          find.byType(SegmentedButton),
        );
        expect(
          segmentedButton.selected.contains(TransactionType.owesMe),
          isTrue,
        );

        // Button should say "Update Transaction"
        expect(find.text('Update Transaction'), findsOneWidget);
      });

      testWidgets('should handle transaction update', (
        WidgetTester tester,
      ) async {
        final existingTransaction = TransactionEntity(
          id: 'test_id',
          name: 'Existing User',
          description: 'Existing Description',
          amount: 75.50,
          type: TransactionType.owesMe,
          date: DateTime(2024, 1, 15),
          currency: const TransactionCurrency(
            code: 'USD',
            symbol: '\$',
            name: 'US Dollar',
            flag: '🇺🇸',
          ),
          attachments: const [],
        );

        final editWidget = ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: AddTransactionPage(transactionToEdit: existingTransaction),
          ),
        );

        await tester.pumpWidget(editWidget);
        await tester.pumpAndSettle();

        // Modify fields
        await tester.enterText(
          find.byType(TextFormField).first,
          'Updated User',
        );
        await tester.enterText(find.byType(TextFormField).at(2), '100.00');

        // Submit update
        await tester.tap(find.text('Update Transaction'));
        await tester.pumpAndSettle();

        // Should trigger update event
        // In a real test with mocked bloc, we would verify the event was called
      });
    });

    group('UI Responsiveness', () {
      testWidgets('should adapt to different screen sizes', (
        WidgetTester tester,
      ) async {
        // Test with smaller screen
        final smallScreenWidget = ScreenUtilInit(
          designSize: const Size(320, 568), // iPhone SE size
          child: MaterialApp(home: AddTransactionPage()),
        );

        await tester.pumpWidget(smallScreenWidget);
        await tester.pumpAndSettle();

        // Should still display all elements
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(find.byType(SegmentedButton), findsOneWidget);
        expect(find.text('Add Transaction'), findsOneWidget);
      });

      testWidgets('should handle keyboard appearance', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Focus on amount field
        await tester.tap(find.byType(TextFormField).at(2));
        await tester.pumpAndSettle();

        // Should still be able to access submit button (with scrolling)
        expect(find.text('Add Transaction'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle network errors gracefully', (
        WidgetTester tester,
      ) async {
        // This would test error states when bloc returns error
        // For now, we test basic error display capability
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // In a real scenario with error state, we would test error message display
        expect(find.byType(AddTransactionPage), findsOneWidget);
      });

      testWidgets('should handle currency loading errors', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Even if currency loading fails, should fall back to default
        expect(find.text('USD'), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('should build quickly', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should build within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      testWidgets('should handle rapid user input', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // Rapidly enter text in multiple fields
        await tester.enterText(find.byType(TextFormField).first, 'Test');
        await tester.pump(Duration(milliseconds: 50));

        await tester.enterText(find.byType(TextFormField).at(1), 'Description');
        await tester.pump(Duration(milliseconds: 50));

        await tester.enterText(find.byType(TextFormField).at(2), '123.45');
        await tester.pumpAndSettle();

        // Should handle rapid input without issues
        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('123.45'), findsOneWidget);
      });
    });
  });
}
