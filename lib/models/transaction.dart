import 'transaction_item.dart';

class SalesTransaction {
  final String id;
  final DateTime transactionDate;
  final double totalAmount;
  final double paymentAmount;
  final double changeAmount;
  final String paymentMethod; // cash, card, etc
  final String status; // completed, canceled
  final String? notes;
  final DateTime createdAt;
  final List<TransactionItem> items; // Transaction items for profit calculation

  SalesTransaction({
    required this.id,
    required this.transactionDate,
    required this.totalAmount,
    required this.paymentAmount,
    required this.changeAmount,
    required this.paymentMethod,
    required this.status,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  // Calculate total profit from transaction items
  double getTotalProfit() {
    double totalProfit = 0;
    for (var item in items) {
      totalProfit += (item.profitMargin * item.quantity);
    }
    return totalProfit;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionDate': transactionDate.toIso8601String(),
      'totalAmount': totalAmount,
      'paymentAmount': paymentAmount,
      'changeAmount': changeAmount,
      'paymentMethod': paymentMethod,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory SalesTransaction.fromJson(Map<String, dynamic> json) {
    return SalesTransaction(
      id: json['id'] as String,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentAmount: (json['paymentAmount'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Create copy with modifications
  SalesTransaction copyWith({
    String? id,
    DateTime? transactionDate,
    double? totalAmount,
    double? paymentAmount,
    double? changeAmount,
    String? paymentMethod,
    String? status,
    String? notes,
    DateTime? createdAt,
    List<TransactionItem>? items,
  }) {
    return SalesTransaction(
      id: id ?? this.id,
      transactionDate: transactionDate ?? this.transactionDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
