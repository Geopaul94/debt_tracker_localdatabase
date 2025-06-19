enum TransactionType { iOwe, owesMe }

class TransactionEntity {
  final String id;
  final String name;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;

  const TransactionEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionEntity &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.amount == amount &&
        other.type == type &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        amount.hashCode ^
        type.hashCode ^
        date.hashCode;
  }

  @override
  String toString() {
    return 'TransactionEntity(id: $id, name: $name, description: $description, amount: $amount, type: $type, date: $date)';
  }

  TransactionEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? date,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
    );
  }
}
