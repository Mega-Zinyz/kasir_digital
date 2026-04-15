import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImageService _instance = ImageService._internal();

  factory ImageService() {
    return _instance;
  }

  ImageService._internal();

  // Directory untuk menyimpan gambar produk di folder instalasi
  Future<Directory> getImagesDirectory() async {
    // Mendapatkan path folder aplikasi dari lokasi .exe
    final executablePath = Platform.resolvedExecutable;
    final appDir = Directory(executablePath).parent;
    final imagesDir = Directory('${appDir.path}/assets/images');
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    return imagesDir;
  }

  // Copy gambar dari source ke folder aplikasi
  Future<String> saveProductImage(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      
      if (!await sourceFile.exists()) {
        throw Exception('File tidak ditemukan: $sourcePath');
      }

      final imagesDir = await getImagesDirectory();
      
      // Generate nama file unik berdasarkan timestamp
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}${path.extension(sourcePath)}';
      final destinationPath = '${imagesDir.path}/$fileName';
      
      // Copy file ke destination
      await sourceFile.copy(destinationPath);
      
      return destinationPath;
    } catch (e) {
      throw Exception('Error menyimpan gambar: $e');
    }
  }

  // Hapus gambar produk dari folder aplikasi
  Future<void> deleteProductImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      // Hanya hapus jika file ada dan berada di folder aplikasi
      final normalizedPath = imagePath.replaceAll('\\', '/');
      if (await file.exists() && normalizedPath.contains('assets/images')) {
        await file.delete();
      }
    } catch (e) {
      // Silent fail, tidak perlu throw error saat menghapus
      debugPrint('Warning: Could not delete image: $e');
    }
  }

  // Check apakah gambar masih ada
  Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }
    
    try {
      return await File(imagePath).exists();
    } catch (e) {
      return false;
    }
  }

  // Get image file size (bytes)
  Future<int?> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('Error getting image size: $e');
    }
    return null;
  }
}
