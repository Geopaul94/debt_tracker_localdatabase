import '../../domain/entities/transaction_entity.dart';

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
}
