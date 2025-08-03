import 'dart:convert';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/attachment_entity.dart';

class TransactionModel extends TransactionEntity {
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required super.id,
    required super.name,
    required super.description,
    required super.amount,
    required super.type,
    required super.date,
    required super.currency,
    super.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from database Map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${map['type']}',
        orElse: () => TransactionType.iOwe,
      ),
      date: DateTime.parse(map['date'] as String),
      currency: TransactionCurrency(
        code: map['currency_code'] as String? ?? 'USD',
        symbol: map['currency_symbol'] as String? ?? '\$',
        name: map['currency_name'] as String? ?? 'US Dollar',
        flag: map['currency_flag'] as String? ?? '🇺🇸',
      ),
      attachments: _parseAttachments(map['attachments'] as String? ?? '[]'),
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          map['updated_at'] != null
              ? DateTime.parse(map['updated_at'] as String)
              : DateTime.now(),
    );
  }

  // Create from TransactionEntity
  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      amount: entity.amount,
      type: entity.type,
      date: entity.date,
      currency: entity.currency,
      attachments: entity.attachments,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Convert to database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'currency_code': currency.code,
      'currency_symbol': currency.symbol,
      'currency_name': currency.name,
      'currency_flag': currency.flag,
      'attachments': _attachmentsToJson(attachments),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert to TransactionEntity
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      name: name,
      description: description,
      amount: amount,
      type: type,
      date: date,
      currency: currency,
      attachments: attachments,
    );
  }

  @override
  TransactionModel copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? date,
    TransactionCurrency? currency,
    List<AttachmentEntity>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, name: $name, description: $description, amount: $amount, type: $type, date: $date, currency: $currency, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TransactionModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.amount == amount &&
        other.type == type &&
        other.date == date &&
        other.currency == currency &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        amount.hashCode ^
        type.hashCode ^
        date.hashCode ^
        currency.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  // Helper methods for attachment JSON conversion
  static List<AttachmentEntity> _parseAttachments(String attachmentsJson) {
    try {
      final List<dynamic> jsonList = jsonDecode(attachmentsJson);
      return jsonList
          .map(
            (json) => AttachmentEntity.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  static String _attachmentsToJson(List<AttachmentEntity> attachments) {
    try {
      final List<Map<String, dynamic>> jsonList =
          attachments.map((attachment) => attachment.toJson()).toList();
      return jsonEncode(jsonList);
    } catch (e) {
      return '[]';
    }
  }
}
