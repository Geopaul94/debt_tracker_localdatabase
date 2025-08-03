import 'attachment_entity.dart';

enum TransactionType { iOwe, owesMe }

class TransactionCurrency {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const TransactionCurrency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionCurrency &&
        other.code == code &&
        other.symbol == symbol &&
        other.name == name &&
        other.flag == flag;
  }

  @override
  int get hashCode {
    return code.hashCode ^ symbol.hashCode ^ name.hashCode ^ flag.hashCode;
  }

  @override
  String toString() => '$symbol $code';
}

class TransactionEntity {
  final String id;
  final String name;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final TransactionCurrency currency;
  final List<AttachmentEntity> attachments;

  const TransactionEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.currency,
    this.attachments = const [],
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
        other.date == date &&
        other.currency == currency &&
        other.attachments.length == attachments.length &&
        other.attachments.every(
          (attachment) => attachments.contains(attachment),
        );
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
        attachments.hashCode;
  }

  @override
  String toString() {
    return 'TransactionEntity(id: $id, name: $name, description: $description, amount: $amount, type: $type, date: $date, currency: $currency, attachments: ${attachments.length} files)';
  }

  TransactionEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? date,
    TransactionCurrency? currency,
    List<AttachmentEntity>? attachments,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      attachments: attachments ?? this.attachments,
    );
  }
}
