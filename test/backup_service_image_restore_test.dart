import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_digital/models/product.dart';
import 'package:kasir_digital/models/transaction.dart';
import 'package:kasir_digital/models/transaction_item.dart';
import 'package:kasir_digital/services/backup_service.dart';
import 'package:kasir_digital/services/database_service.dart';
import 'package:kasir_digital/services/image_service.dart';
import 'package:kasir_digital/services/scheduled_backup_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService databaseService;
  late BackupService backupService;
  late ImageService imageService;
  late ScheduledBackupService scheduledBackupService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseService = DatabaseService();
    backupService = BackupService();
    imageService = ImageService();
    scheduledBackupService = ScheduledBackupService();

    await databaseService.clearAllData();
    await _deleteManagedImages(imageService);
  });

  tearDown(() async {
    scheduledBackupService.stopScheduledBackups();
    await databaseService.clearAllData();
    await _deleteManagedImages(imageService);
  });

  test('backup dan restore mengembalikan gambar produk yang dikelola aplikasi',
      () async {
    final sourceDir = await Directory.systemTemp.createTemp('kasir_source_');
    final backupDir = await Directory.systemTemp.createTemp('kasir_backup_');

    try {
      final sourceImage = File('${sourceDir.path}/sample-image.txt');
      final originalBytes = utf8.encode('sample-image-content');
      await sourceImage.writeAsBytes(originalBytes);

      final managedImagePath = await imageService.saveProductImage(sourceImage.path);

      final product = Product(
        id: 'product-image-1',
        name: 'Produk Bergambar',
        code: 'IMG-001',
        costPrice: 10000,
        profitMargin: 2500,
        price: 12500,
        stock: 4,
        categories: const ['backup'],
        imagePath: managedImagePath,
        createdAt: DateTime.now(),
      );

      await databaseService.insertProduct(product);

      final backupPath = await backupService.exportDatabase(
        defaultPath: backupDir.path,
      );

      expect(backupPath, isNotNull);

      final backupFile = File(backupPath!);
      expect(await backupFile.exists(), isTrue);

      final backupJson = jsonDecode(await backupFile.readAsString())
          as Map<String, dynamic>;
      final productImages = backupJson['product_images'] as List<dynamic>?;

      expect(productImages, isNotNull);
      expect(productImages, hasLength(1));
      expect((productImages!.first as Map<String, dynamic>)['productId'], product.id);

      await databaseService.clearAllData();
      final managedImageFile = File(managedImagePath);
      if (await managedImageFile.exists()) {
        await managedImageFile.delete();
      }

      await backupService.restoreDatabase(backupJson);

      final restoredProducts = await databaseService.getAllProducts();
      expect(restoredProducts, hasLength(1));

      final restoredProduct = restoredProducts.single;
      expect(restoredProduct.imagePath, isNotNull);
      expect(restoredProduct.imagePath, isNotEmpty);

      final restoredImageFile = File(restoredProduct.imagePath!);
      expect(await restoredImageFile.exists(), isTrue);
      expect(await restoredImageFile.readAsBytes(), originalBytes);
    } finally {
      if (await sourceDir.exists()) {
        await sourceDir.delete(recursive: true);
      }
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
    }
  });

  test('backup otomatis memakai format yang sama dan menyertakan gambar serta item transaksi',
      () async {
    final sourceDir = await Directory.systemTemp.createTemp('kasir_source_auto_');
    final backupDir = await Directory.systemTemp.createTemp('kasir_auto_backup_');

    try {
      final sourceImage = File('${sourceDir.path}/sample-image-auto.txt');
      final originalBytes = utf8.encode('sample-auto-image-content');
      await sourceImage.writeAsBytes(originalBytes);

      final managedImagePath = await imageService.saveProductImage(sourceImage.path);

      final product = Product(
        id: 'product-auto-1',
        name: 'Produk Auto Backup',
        code: 'AUTO-001',
        costPrice: 12000,
        profitMargin: 3000,
        price: 15000,
        stock: 8,
        categories: const ['scheduled'],
        imagePath: managedImagePath,
        createdAt: DateTime.now(),
      );

      final transaction = SalesTransaction(
        id: 'txn-auto-1',
        transactionDate: DateTime.now(),
        totalAmount: 15000,
        paymentAmount: 20000,
        changeAmount: 5000,
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: DateTime.now(),
      );

      final transactionItem = TransactionItem(
        id: 'txn-auto-1-item-1',
        transactionId: transaction.id,
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: 1,
        subtotal: product.price,
        costPrice: product.costPrice,
        profitMargin: product.profitMargin,
      );

      await databaseService.insertProduct(product);
      await databaseService.insertTransaction(transaction);
      await databaseService.insertTransactionItem(transactionItem);

      scheduledBackupService.startScheduledBackups(
        frequency: 'daily',
        backupDirectory: backupDir.path,
      );

      final backupFile = await _waitForSingleBackupFile(backupDir);
      expect(backupFile, isNotNull);

      scheduledBackupService.stopScheduledBackups();

      final backupJson = jsonDecode(await backupFile!.readAsString())
          as Map<String, dynamic>;

      expect((backupJson['products'] as List<dynamic>), hasLength(1));
      expect((backupJson['transactions'] as List<dynamic>), hasLength(1));
      expect((backupJson['transaction_items'] as List<dynamic>), hasLength(1));
      expect((backupJson['product_images'] as List<dynamic>), hasLength(1));
      expect((backupJson['product_images'] as List<dynamic>).first['productId'], product.id);
    } finally {
      scheduledBackupService.stopScheduledBackups();
      if (await sourceDir.exists()) {
        await sourceDir.delete(recursive: true);
      }
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
    }
  });
}

Future<void> _deleteManagedImages(ImageService imageService) async {
  final imagesDir = await imageService.getImagesDirectory();
  if (!await imagesDir.exists()) {
    return;
  }

  for (final entity in imagesDir.listSync()) {
    if (entity is File) {
      await entity.delete();
    }
  }
}

Future<File?> _waitForSingleBackupFile(Directory directory) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();

    if (files.isNotEmpty) {
      return files.single;
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  return null;
}