class TransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;
  final double costPrice;      // Harga asli produk
  final double profitMargin;   // Margin keuntungan per unit

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.costPrice,
    required this.profitMargin,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'costPrice': costPrice,
      'profitMargin': profitMargin,
    };
  }

  // Create from JSON
  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      profitMargin: (json['profitMargin'] as num?)?.toDouble() ?? 0,
    );
  }

  // Create copy with modifications
  TransactionItem copyWith({
    String? id,
    String? transactionId,
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    double? subtotal,
    double? costPrice,
    double? profitMargin,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      costPrice: costPrice ?? this.costPrice,
      profitMargin: profitMargin ?? this.profitMargin,
    );
  }
}
