import 'package:flutter_test/flutter_test.dart';
import 'package:debt_tracker/data/models/transaction_model.dart';
import 'package:debt_tracker/domain/entities/transaction_entity.dart';
import 'package:debt_tracker/domain/entities/attachment_entity.dart';

void main() {
  group('TransactionModel', () {
    late TransactionModel transactionModel;
    late TransactionCurrency testCurrency;
    late List<AttachmentEntity> testAttachments;
    
    setUp(() {
      testCurrency = const TransactionCurrency(
        code: 'USD',
        symbol: '\$',
        name: 'US Dollar',
        flag: '🇺🇸',
      );
      
      testAttachments = [
        AttachmentEntity(
          id: 'attach1',
          fileName: 'receipt.jpg',
          filePath: '/path/to/receipt.jpg',
          fileType: 'image/jpeg',
          fileSize: 1024,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];
      
      transactionModel = TransactionModel(
        id: 'test_id',
        name: 'John Doe',
        description: 'Lunch money',
        amount: 25.50,
        type: TransactionType.iOwe,
        date: DateTime(2024, 1, 1),
        currency: testCurrency,
        attachments: testAttachments,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    group('Constructor', () {
      test('should create transaction model with all required fields', () {
        expect(transactionModel.id, 'test_id');
        expect(transactionModel.name, 'John Doe');
        expect(transactionModel.description, 'Lunch money');
        expect(transactionModel.amount, 25.50);
        expect(transactionModel.type, TransactionType.owe);
        expect(transactionModel.currency.code, 'USD');
        expect(transactionModel.attachments.length, 1);
      });

      test('should create transaction model with empty attachments', () {
        final model = TransactionModel(
          id: 'test_id',
          name: 'John Doe',
          description: 'Test',
          amount: 100.0,
          type: TransactionType.owesMe,
          date: DateTime(2024, 1, 1),
          currency: testCurrency,
          attachments: const [],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(model.attachments, isEmpty);
      });
    });

    group('fromMap', () {
      test('should create model from complete map with currency and attachments', () {
        final map = {
          'id': 'test_id',
          'name': 'John Doe',
          'description': 'Lunch money',
          'amount': 25.50,
          'type': 'owe',
          'date': '2024-01-01T00:00:00.000',
          'currency_code': 'EUR',
          'currency_symbol': '€',
          'currency_name': 'Euro',
          'currency_flag': '🇪🇺',
          'attachments': '[{"id":"attach1","fileName":"receipt.jpg","filePath":"/path/to/receipt.jpg","fileType":"image/jpeg","fileSize":1024,"createdAt":"2024-01-01T00:00:00.000"}]',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        };

        final model = TransactionModel.fromMap(map);

        expect(model.id, 'test_id');
        expect(model.name, 'John Doe');
        expect(model.currency.code, 'EUR');
        expect(model.currency.symbol, '€');
        expect(model.attachments.length, 1);
        expect(model.attachments.first.fileName, 'receipt.jpg');
      });

      test('should create model with default currency when currency fields missing', () {
        final map = {
          'id': 'test_id',
          'name': 'John Doe',
          'description': 'Test',
          'amount': 100.0,
          'type': 'owe',
          'date': '2024-01-01T00:00:00.000',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        };

        final model = TransactionModel.fromMap(map);

        expect(model.currency.code, 'USD');
        expect(model.currency.symbol, '\$');
        expect(model.currency.name, 'US Dollar');
        expect(model.currency.flag, '🇺🇸');
      });

      test('should handle empty attachments string', () {
        final map = {
          'id': 'test_id',
          'name': 'John Doe',
          'description': 'Test',
          'amount': 100.0,
          'type': 'owe',
          'date': '2024-01-01T00:00:00.000',
          'currency_code': 'USD',
          'currency_symbol': '\$',
          'currency_name': 'US Dollar',
          'currency_flag': '🇺🇸',
          'attachments': '[]',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        };

        final model = TransactionModel.fromMap(map);

        expect(model.attachments, isEmpty);
      });

      test('should handle malformed attachments JSON', () {
        final map = {
          'id': 'test_id',
          'name': 'John Doe',
          'description': 'Test',
          'amount': 100.0,
          'type': 'owe',
          'date': '2024-01-01T00:00:00.000',
          'currency_code': 'USD',
          'currency_symbol': '\$',
          'currency_name': 'US Dollar',
          'currency_flag': '🇺🇸',
          'attachments': 'invalid json',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        };

        final model = TransactionModel.fromMap(map);

        expect(model.attachments, isEmpty);
      });
    });

    group('fromEntity', () {
      test('should create model from transaction entity', () {
        final entity = TransactionEntity(
          id: 'entity_id',
          name: 'Jane Smith',
          description: 'Coffee',
          amount: 5.0,
          type: TransactionType.owesMe,
          date: DateTime(2024, 2, 1),
          currency: testCurrency,
          attachments: testAttachments,
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
        );

        final model = TransactionModel.fromEntity(entity);

        expect(model.id, 'entity_id');
        expect(model.name, 'Jane Smith');
        expect(model.description, 'Coffee');
        expect(model.amount, 5.0);
        expect(model.type, TransactionType.owed);
        expect(model.currency.code, 'USD');
        expect(model.attachments.length, 1);
      });
    });

    group('toMap', () {
      test('should convert model to map with all fields', () {
        final map = transactionModel.toMap();

        expect(map['id'], 'test_id');
        expect(map['name'], 'John Doe');
        expect(map['description'], 'Lunch money');
        expect(map['amount'], 25.50);
        expect(map['type'], 'owe');
        expect(map['currency_code'], 'USD');
        expect(map['currency_symbol'], '\$');
        expect(map['currency_name'], 'US Dollar');
        expect(map['currency_flag'], '🇺🇸');
        expect(map['attachments'], isA<String>());
        expect(map['attachments'], contains('receipt.jpg'));
      });

      test('should handle empty attachments in toMap', () {
        final modelWithoutAttachments = TransactionModel(
          id: 'test_id',
          name: 'John Doe',
          description: 'Test',
          amount: 100.0,
          type: TransactionType.iOwe,
          date: DateTime(2024, 1, 1),
          currency: testCurrency,
          attachments: const [],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final map = modelWithoutAttachments.toMap();

        expect(map['attachments'], '[]');
      });
    });

    group('copyWith', () {
      test('should create copy with updated currency', () {
        final newCurrency = const TransactionCurrency(
          code: 'EUR',
          symbol: '€',
          name: 'Euro',
          flag: '🇪🇺',
        );

        final updatedModel = transactionModel.copyWith(currency: newCurrency);

        expect(updatedModel.currency.code, 'EUR');
        expect(updatedModel.name, 'John Doe'); // Other fields unchanged
        expect(updatedModel.id, 'test_id');
      });

      test('should create copy with updated attachments', () {
        final newAttachments = [
          AttachmentEntity(
            id: 'attach2',
            fileName: 'invoice.pdf',
            filePath: '/path/to/invoice.pdf',
            fileType: 'application/pdf',
            fileSize: 2048,
            createdAt: DateTime(2024, 1, 2),
          ),
        ];

        final updatedModel = transactionModel.copyWith(attachments: newAttachments);

        expect(updatedModel.attachments.length, 1);
        expect(updatedModel.attachments.first.fileName, 'invoice.pdf');
        expect(updatedModel.name, 'John Doe'); // Other fields unchanged
      });

      test('should create copy with no changes when no parameters provided', () {
        final copiedModel = transactionModel.copyWith();

        expect(copiedModel.id, transactionModel.id);
        expect(copiedModel.name, transactionModel.name);
        expect(copiedModel.currency.code, transactionModel.currency.code);
        expect(copiedModel.attachments.length, transactionModel.attachments.length);
      });
    });

    group('Equality and Hash', () {
      test('should be equal when all fields match', () {
        final model1 = TransactionModel(
          id: 'test_id',
          name: 'John Doe',
          description: 'Test',
          amount: 100.0,
          type: TransactionType.iOwe,
          date: DateTime(2024, 1, 1),
          currency: testCurrency,
          attachments: testAttachments,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final model2 = TransactionModel(
          id: 'test_id',
          name: 'John Doe',
          description: 'Test',
          amount: 100.0,
          type: TransactionType.iOwe,
          date: DateTime(2024, 1, 1),
          currency: testCurrency,
          attachments: testAttachments,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(model1, equals(model2));
        expect(model1.hashCode, equals(model2.hashCode));
      });

      test('should not be equal when currency differs', () {
        final model1 = transactionModel;
        final model2 = transactionModel.copyWith(
          currency: const TransactionCurrency(
            code: 'EUR',
            symbol: '€',
            name: 'Euro',
            flag: '🇪🇺',
          ),
        );

        expect(model1, isNot(equals(model2)));
      });

      test('should not be equal when attachments differ', () {
        final model1 = transactionModel;
        final model2 = transactionModel.copyWith(attachments: []);

        expect(model1, isNot(equals(model2)));
      });
    });

    group('toString', () {
      test('should include currency and attachments in string representation', () {
        final stringRepresentation = transactionModel.toString();

        expect(stringRepresentation, contains('currency'));
        expect(stringRepresentation, contains('attachments'));
        expect(stringRepresentation, contains('USD'));
        expect(stringRepresentation, contains('John Doe'));
      });
    });

    group('Edge Cases', () {
      test('should handle transaction with multiple attachments', () {
        final multipleAttachments = [
          AttachmentEntity(
            id: 'attach1',
            fileName: 'receipt1.jpg',
            filePath: '/path/to/receipt1.jpg',
            fileType: 'image/jpeg',
            fileSize: 1024,
            createdAt: DateTime(2024, 1, 1),
          ),
          AttachmentEntity(
            id: 'attach2',
            fileName: 'receipt2.pdf',
            filePath: '/path/to/receipt2.pdf',
            fileType: 'application/pdf',
            fileSize: 2048,
            createdAt: DateTime(2024, 1, 2),
          ),
        ];

        final model = transactionModel.copyWith(attachments: multipleAttachments);

        expect(model.attachments.length, 2);
        expect(model.attachments[0].fileName, 'receipt1.jpg');
        expect(model.attachments[1].fileName, 'receipt2.pdf');
      });

      test('should handle special characters in currency symbols', () {
        final specialCurrency = const TransactionCurrency(
          code: 'TEST',
          symbol: '₹€¥',
          name: 'Test Currency',
          flag: '🏳️',
        );

        final model = transactionModel.copyWith(currency: specialCurrency);
        final map = model.toMap();
        final reconstructed = TransactionModel.fromMap(map);

        expect(reconstructed.currency.symbol, '₹€¥');
        expect(reconstructed.currency.flag, '🏳️');
      });
    });
  });
}