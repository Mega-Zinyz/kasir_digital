import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'database_service.dart';
import 'image_service.dart';
import '../models/index.dart';
import '../utils/app_constants.dart';

class BackupService {
  final DatabaseService _dbService = DatabaseService();
  final ImageService _imageService = ImageService();

  /// Export database to JSON backup file (includes transaction_items)
  Future<String?> exportDatabase({String? defaultPath}) async {
    try {
      final products = await _dbService.getAllProducts();
      final transactions = await _dbService.getAllTransactions();
      final transactionItems = await _dbService.getAllTransactionItems();
      final productImages = await _collectProductImages(products);

      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': AppConstants.appVersion,
        'products': products.map((p) => p.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'transaction_items': transactionItems.map((i) => i.toJson()).toList(),
        'product_images': productImages,
      };

      final jsonContent = const JsonEncoder.withIndent('  ').convert(backupData);

      String? savePath = defaultPath;
      if (savePath == null || savePath.isEmpty) {
        savePath = await FilePicker.getDirectoryPath();
      }

      if (savePath != null && savePath.isNotEmpty) {
        final fileName = 'kasir_backup_$timestamp.json';
        final filePath = '$savePath/$fileName';
        await File(filePath).writeAsString(jsonContent);
        return filePath;
      }

      return null;
    } catch (e) {
      throw Exception('Gagal membuat backup: ${e.toString()}');
    }
  }

  /// Validate backup file and return parsed data, or throw on error.
  Future<Map<String, dynamic>> validateBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('__cancelled__');
    }

    final filePath = result.files.first.path;
    if (filePath == null) {
      throw Exception('Tidak dapat membaca path file');
    }

    final jsonContent = await File(filePath).readAsString();

    late Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonContent) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('File bukan JSON yang valid');
    }

    if (!data.containsKey('products') || !data.containsKey('transactions')) {
      throw Exception('Format file backup tidak valid');
    }

    return data;
  }

  /// Restore database from parsed backup data (replaces all existing data).
  Future<void> restoreDatabase(Map<String, dynamic> data) async {
    await _dbService.clearAllData();

    final rawImageEntries = data['product_images'] as List<dynamic>? ?? [];
    final hasImageManifest = data.containsKey('product_images');
    final imageEntriesByProductId = <String, Map<String, dynamic>>{};

    for (final raw in rawImageEntries) {
      final imageEntry = Map<String, dynamic>.from(raw as Map);
      final productId = imageEntry['productId'] as String?;
      if (productId != null && productId.isNotEmpty) {
        imageEntriesByProductId[productId] = imageEntry;
      }
    }

    if (hasImageManifest) {
      await _clearManagedProductImages();
    }

    // Restore categories
    final rawCategories = data['categories'] as List<dynamic>? ?? [];
    for (final raw in rawCategories) {
      await _dbService.insertCategory(
          Category.fromJson(raw as Map<String, dynamic>));
    }

    // Restore products
    final rawProducts = data['products'] as List<dynamic>;
    for (final raw in rawProducts) {
      final productJson = Map<String, dynamic>.from(raw as Map);
      final productId = productJson['id'] as String?;
      final managedImageEntry =
          productId != null ? imageEntriesByProductId[productId] : null;

      if (managedImageEntry != null) {
        productJson['imagePath'] = await _restoreProductImage(managedImageEntry);
      } else if (hasImageManifest &&
          _isManagedImagePath(productJson['imagePath'] as String?)) {
        productJson['imagePath'] = null;
      }

      await _dbService.insertProduct(
          Product.fromJson(productJson));
    }

    // Restore transactions
    final rawTransactions = data['transactions'] as List<dynamic>;
    for (final raw in rawTransactions) {
      await _dbService.insertTransaction(
          SalesTransaction.fromJson(raw as Map<String, dynamic>));
    }

    // Restore transaction items (new field — optional for old backups)
    final rawItems = data['transaction_items'] as List<dynamic>? ?? [];
    for (final raw in rawItems) {
      await _dbService.insertTransactionItem(
          TransactionItem.fromJson(raw as Map<String, dynamic>));
    }
  }

  Future<List<Map<String, dynamic>>> _collectProductImages(
      List<Product> products) async {
    final imageBackups = <Map<String, dynamic>>[];

    for (final product in products) {
      final imagePath = product.imagePath;
      if (!_isManagedImagePath(imagePath)) {
        continue;
      }

      final imageFile = File(imagePath!);
      if (!await imageFile.exists()) {
        continue;
      }

      final imageBytes = await imageFile.readAsBytes();
      imageBackups.add({
        'productId': product.id,
        'fileName': path.basename(imagePath),
        'contentBase64': base64Encode(imageBytes),
      });
    }

    return imageBackups;
  }

  Future<void> _clearManagedProductImages() async {
    final imagesDir = await _imageService.getImagesDirectory();
    if (!await imagesDir.exists()) {
      return;
    }

    for (final entity in imagesDir.listSync()) {
      if (entity is File) {
        entity.deleteSync();
      }
    }
  }

  Future<String> _restoreProductImage(Map<String, dynamic> imageEntry) async {
    final imagesDir = await _imageService.getImagesDirectory();
    final productId = imageEntry['productId'] as String? ?? 'unknown';
    final fileName = imageEntry['fileName'] as String?;
    final encodedContent = imageEntry['contentBase64'] as String? ?? '';
    final extension = fileName != null && fileName.isNotEmpty
        ? path.extension(fileName)
        : '.img';
    final resolvedFileName =
        fileName != null && fileName.isNotEmpty ? fileName : 'product_$productId$extension';
    final restoredFile = File('${imagesDir.path}/$resolvedFileName');

    await restoredFile.writeAsBytes(base64Decode(encodedContent));
    return restoredFile.path;
  }

  bool _isManagedImagePath(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    final normalizedPath = imagePath.replaceAll('\\', '/').toLowerCase();
    return normalizedPath.contains('/assets/images/');
  }
}

