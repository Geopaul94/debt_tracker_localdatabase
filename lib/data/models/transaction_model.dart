import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required String id,
    required String name,
    required String description,
    required double amount,
    required TransactionType type,
    required DateTime date,
    required this.createdAt,
    required this.updatedAt,
  }) : super(
         id: id,
         name: name,
         description: description,
         amount: amount,
         type: type,
         date: date,
       );

  // Create from database Map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      amount: map['amount'].toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Legacy JSON methods for migration support
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return TransactionModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      type: TransactionType.values.firstWhere(
        (e) =>
            e.toString() == 'TransactionType.${json['type']}' ||
            e.toString().split('.').last == json['type'],
      ),
      date: DateTime.parse(json['date']),
      createdAt:
          json['created_at'] != null ? DateTime.parse(json['created_at']) : now,
      updatedAt:
          json['updated_at'] != null ? DateTime.parse(json['updated_at']) : now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    final now = DateTime.now();
    return TransactionModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      amount: entity.amount,
      type: entity.type,
      date: entity.date,
      createdAt: now,
      updatedAt: now,
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      name: name,
      description: description,
      amount: amount,
      type: type,
      date: date,
    );
  }

  // Create a copy with updated fields
  TransactionModel copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? date,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
