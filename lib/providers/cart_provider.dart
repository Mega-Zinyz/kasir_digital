import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String _paymentMethod = 'cash';

  List<CartItem> get items => _items;
  String get paymentMethod => _paymentMethod;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get itemCount => _items.length;

  // Check if product already in cart
  bool isProductInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  // Add item to cart and return true if new item, false if quantity updated
  bool addToCart(Product product, int quantity) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Update quantity if product already in cart
      final updatedItem = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
      _items[existingIndex] = updatedItem;
      notifyListeners();
      return false; // Not a new item, just updated quantity
    } else {
      // Add new item
      _items.add(CartItem(
        id: const Uuid().v4(),
        product: product,
        quantity: quantity,
      ));
      notifyListeners();
      return true; // New item added
    }
  }

  // Update item quantity
  void updateItemQuantity(String itemId, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  // Remove item from cart
  void removeFromCart(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  // Clear cart
  void clearCart() {
    _items.clear();
    _paymentMethod = 'cash';
    notifyListeners();
  }

  // Set payment method
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // Convert to transaction items
  List<TransactionItem> toTransactionItems(String transactionId) {
    return _items
        .map((cartItem) => TransactionItem(
              id: const Uuid().v4(),
              transactionId: transactionId,
              productId: cartItem.product.id,
              productName: cartItem.product.name,
              price: cartItem.product.price,
              quantity: cartItem.quantity,
              subtotal: cartItem.subtotal,
              costPrice: cartItem.product.costPrice,
              profitMargin: cartItem.product.profitMargin,
            ))
        .toList();
  }
}
