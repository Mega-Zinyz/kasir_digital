import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final ImageService _imageService = ImageService();
  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Product> get products {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products
        .where((product) =>
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.code.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Load all products
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _dbService.getAllProducts();
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Add new product
  Future<void> addProduct({
    required String name,
    required String code,
    required double costPrice,
    required double profitMargin,
    required int stock,
    String? barcode,
    List<String>? categories,
    String? imagePath,
    DateTime? expiryDate,
    String unit = 'pcs',
  }) async {
    try {
      // Copy image to app directory if provided
      String? localImagePath;
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          localImagePath = await _imageService.saveProductImage(imagePath);
        } catch (e) {
          debugPrint('Warning: Could not save image, continuing without image: $e');
        }
      }

      // Calculate selling price from cost + margin (margin adalah nilai langsung Rp)
      final sellingPrice = costPrice + profitMargin;

      final product = Product(
        id: const Uuid().v4(),
        name: name,
        code: code,
        barcode: barcode,
        costPrice: costPrice,
        profitMargin: profitMargin,
        price: sellingPrice,
        stock: stock,
        categories: categories ?? [],
        imagePath: localImagePath,
        createdAt: DateTime.now(),
        expiryDate: expiryDate,
        unit: unit,
      );
      await _dbService.insertProduct(product);
      _products.add(product);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  // Update product with image handling
  Future<void> updateProduct({
    required String id,
    required String name,
    required String code,
    required double costPrice,
    required double profitMargin,
    required int stock,
    String? barcode,
    List<String>? categories,
    String? imagePath,
    String? oldImagePath,
    DateTime? expiryDate,
    String unit = 'pcs',
  }) async {
    try {
      final existingProduct = _products.firstWhere((p) => p.id == id);

      // Handle image replacement
      String? finalImagePath = imagePath;
      if (imagePath != null && imagePath.isNotEmpty) {
        // Copy new image to app directory
        try {
          finalImagePath = await _imageService.saveProductImage(imagePath);

          // Delete old image if it's different from new one
          if (oldImagePath != null &&
              oldImagePath.isNotEmpty &&
              oldImagePath != finalImagePath &&
              oldImagePath.contains('kasir_digital/assets/images')) {
            await _imageService.deleteProductImage(oldImagePath);
          }
        } catch (e) {
          debugPrint('Warning: Could not save new image, keeping old image: $e');
          finalImagePath = oldImagePath;
        }
      } else if (oldImagePath != null && oldImagePath.isNotEmpty) {
        // Keep old image if no new image provided
        finalImagePath = oldImagePath;
      }

      // Calculate selling price from cost + margin (margin adalah nilai langsung Rp)
      final sellingPrice = costPrice + profitMargin;

      final product = Product(
        id: id,
        name: name,
        code: code,
        barcode: barcode,
        costPrice: costPrice,
        profitMargin: profitMargin,
        price: sellingPrice,
        stock: stock,
        categories: categories ?? existingProduct.categories,
        imagePath: finalImagePath,
        createdAt: existingProduct.createdAt,
        updatedAt: DateTime.now(),
        expiryDate: expiryDate ?? existingProduct.expiryDate,
        unit: unit,
      );
      await _dbService.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    try {
      // Find product to get associated image
      Product? productToDelete;
      try {
        productToDelete = _products.firstWhere((p) => p.id == id);
      } catch (e) {
        // Product not found in memory, continue anyway
      }
      
      // Delete image from app directory if exists
      if (productToDelete?.imagePath != null && productToDelete!.imagePath!.isNotEmpty) {
        await _imageService.deleteProductImage(productToDelete.imagePath!);
      }
      
      await _dbService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Decrease stock for a product
  Future<void> decreaseStock(String productId, int quantity) async {
    try {
      final product = getProductById(productId);
      if (product != null) {
        final newStock = (product.stock - quantity).clamp(0, product.stock);
        await updateProduct(
          id: productId,
          name: product.name,
          code: product.code,
          costPrice: product.costPrice,
          profitMargin: product.profitMargin,
          stock: newStock,
          categories: product.categories,
          oldImagePath: product.imagePath,
        );
      }
    } catch (e) {
      debugPrint('Error decreasing stock: $e');
      rethrow;
    }
  }

  // Get low stock products (stock below threshold)
  List<Product> getLowStockProducts(int threshold) {
    return _products.where((p) => p.stock < threshold).toList();
  }
}
