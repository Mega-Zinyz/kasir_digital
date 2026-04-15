class Product {
  final String id;
  final String name;
  final String code;
  final String? barcode;
  final double costPrice; // Harga asli/cost
  final double profitMargin; // Margin profit dalam Rp (nilai langsung)
  final double price; // Harga jual (calculated dari costPrice + profitMargin)
  final int stock;
  final List<String> categories; // Multiple categories
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiryDate; // Tanggal kadaluarsa
  final String unit; // Satuan: pcs, kg, gram, liter, dll

  Product({
    required this.id,
    required this.name,
    required this.code,
    this.barcode,
    required this.costPrice,
    required this.profitMargin,
    required this.price,
    required this.stock,
    this.categories = const [],
    this.imagePath,
    required this.createdAt,
    this.updatedAt,
    this.expiryDate,
    this.unit = 'pcs',
  });

  // Get profit per unit
  double getProfitPerUnit() => price - costPrice;
  
  // Get total profit for stock
  double getTotalProfit(int quantity) => getProfitPerUnit() * quantity;

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'barcode': barcode,
      'costPrice': costPrice,
      'profitMargin': profitMargin,
      'price': price,
      'stock': stock,
      'categories': categories.join('|'), // Store as pipe-separated string
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'unit': unit,
    };
  }

  // Create from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility - old single category field
    List<String> categories = [];
    if (json['categories'] != null && (json['categories'] as String).isNotEmpty) {
      categories = (json['categories'] as String).split('|');
    } else {
      final oldCategory = json['category'] as String?;
      if (oldCategory != null && oldCategory.isNotEmpty) {
        // Migrate old single category
        categories = [oldCategory];
      }
    }

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      barcode: json['barcode'] as String?,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? (json['price'] as num).toDouble(),
      profitMargin: (json['profitMargin'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      categories: categories,
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      unit: json['unit'] as String? ?? 'pcs',
    );
  }

  // Create copy with modifications
  Product copyWith({
    String? id,
    String? name,
    String? code,
    double? costPrice,
    double? profitMargin,
    double? price,
    int? stock,
    List<String>? categories,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiryDate,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      costPrice: costPrice ?? this.costPrice,
      profitMargin: profitMargin ?? this.profitMargin,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categories: categories ?? this.categories,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      unit: unit ?? this.unit,
    );
  }
}
