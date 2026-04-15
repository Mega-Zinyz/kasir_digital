import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../services/database_service.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  // Load all categories
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _dbService.getAllCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new category
  Future<void> addCategory({
    required String name,
    String? description,
  }) async {
    try {
      final category = Category(
        id: const Uuid().v4(),
        name: name,
        description: description,
        createdAt: DateTime.now(),
      );
      await _dbService.insertCategory(category);
      _categories.add(category);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _dbService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  // Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get category by name
  Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }
}
