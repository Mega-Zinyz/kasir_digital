// Provider & State Management Load Test - kasir_digital
//
// Menguji performa state management (Provider / ChangeNotifier) di bawah beban:
// - CartProvider: add/remove barang dalam jumlah besar
// - Filter & search in-memory pada daftar produk besar
// - Simulasi sesi kasir (checkout berulang-ulang)
// - Penggunaan memori (snapshot heap sederhana)
//
// Jalankan: flutter test test/stress/provider_load_test.dart --timeout=60s
// ignore_for_file: avoid_print

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_digital/models/index.dart';
import 'package:kasir_digital/providers/cart_provider.dart';

// ── Config ──────────────────────────────────────────────────────────────────
// Ubah nilai di sini untuk menyesuaikan beban test

const kProductCounts        = [1000, 5000, 10000]; // Generate produk (group 1)
const kFilterProductCount   = 5000;  // Jumlah produk untuk filter/sort
const kFilterIterations     = 1000;  // Berapa kali filter dijalankan (group 2)
const kSortIterations       = 500;   // Berapa kali sort dijalankan (group 2)
const kCartUniqueItems      = 500;   // Item unik yang ditambah ke cart (group 3)
const kCartSameItemAdds     = 1000;  // Tambah produk sama berulang (group 3)
const kCartUpdateRemove     = 200;   // Item untuk update & remove (group 4)
const kKasirSessions        = 50;    // Jumlah sesi kasir (group 5)
const kItemsPerSession      = 10;    // Item per sesi kasir (group 5)
const kCalcProductCount     = 1000;  // Produk di cart untuk kalkulasi (group 6)
const kCalcIterations       = 500;   // Berapa kali hitung total (group 6)
const kNotifyIterations     = 2000;  // Berapa kali notifyListeners (group 7)
const kListenerCount        = 10;    // Jumlah listener aktif (group 7)

// ── Helpers ───────────────────────────────────────────────────────────────────

final _random = Random(42);

Product _makeProduct(int i) => Product(
      id: 'prod-$i',
      name: 'Produk Load Test ${i.toString().padLeft(5, '0')}',
      code: 'LT-${i.toString().padLeft(6, '0')}',
      barcode: null,
      costPrice: 5000.0 + (i % 100) * 200,
      profitMargin: 500.0 + (i % 50) * 50,
      price: 5500.0 + (i % 100) * 200 + (i % 50) * 50,
      stock: 10 + _random.nextInt(200),
      categories: ['cat-${i % 5}'],
      imagePath: null,
      createdAt: DateTime.now(),
    );

List<Product> _generateProductList(int count) =>
    List.generate(count, (i) => _makeProduct(i));

class _Result {
  final String name;
  final int count;
  final Duration elapsed;

  _Result(this.name, this.count, this.elapsed);

  double get opsPerSecond =>
      elapsed.inMilliseconds == 0 ? double.infinity : count / elapsed.inMilliseconds * 1000;

  @override
  String toString() =>
      '[${name.padRight(45)}] '
      'count=${count.toString().padLeft(6)} | '
      'ms=${elapsed.inMilliseconds.toString().padLeft(6)} | '
      'ops/s=${opsPerSecond.toStringAsFixed(1).padLeft(10)}';
}

final _results = <_Result>[];

_Result _measure(String name, int count, void Function() fn) {
  final sw = Stopwatch()..start();
  fn();
  sw.stop();
  final r = _Result(name, count, sw.elapsed);
  _results.add(r);
  return r;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  tearDownAll(() => _printSummary());

  // ── 1. Inisialisasi Daftar Produk Besar ───────────────────────────────────
  group('1. Inisialisasi Produk (in-memory)', () {
    for (final n in kProductCounts) {
      test('Generate $n produk', () {
        final r = _measure('Generate $n produk', n, () {
          _generateProductList(n);
        });
        print(r);
        expect(r.elapsed.inMilliseconds, lessThan(2000),
            reason: 'Inisialisasi $n produk terlalu lambat');
      });
    }
  });

  // ── 2. Filter In-Memory ───────────────────────────────────────────────────
  group('2. Filter / Search In-Memory', () {
    late List<Product> products;

    setUp(() => products = _generateProductList(kFilterProductCount));

    test('Filter $kFilterProductCount produk dengan query string (${kFilterIterations}x)', () {
      const iterations = kFilterIterations;
      final keywords = ['000', '001', 'Produk', 'LT-', '999'];

      final r = _measure('Filter $kFilterProductCount produk x$iterations', iterations, () {
        for (int i = 0; i < iterations; i++) {
          final kw = keywords[i % keywords.length].toLowerCase();
          products
              .where((p) =>
                  p.name.toLowerCase().contains(kw) ||
                  p.code.toLowerCase().contains(kw))
              .toList();
        }
      });

      print(r);
      expect(r.opsPerSecond, greaterThan(50),
          reason: 'Filter in-memory terlalu lambat');
    });

    test('Sort produk berdasarkan harga (${kSortIterations}x)', () {
      const iterations = kSortIterations;

      final r = _measure('Sort $kFilterProductCount produk x$iterations', iterations, () {
        for (int i = 0; i < iterations; i++) {
          final sorted = List<Product>.from(products)
            ..sort((a, b) => a.price.compareTo(b.price));
          // ignore: unused_local_variable
          final _ = sorted.first.id;
        }
      });

      print(r);
      expect(r.opsPerSecond, greaterThan(10),
          reason: 'Sort in-memory terlalu lambat');
    });
  });

  // ── 3. CartProvider: Tambah Barang ───────────────────────────────────────
  group('3. CartProvider - Tambah Barang', () {
    test('Tambah $kCartUniqueItems item unik ke cart', () {
      final cart = CartProvider();
      final products = _generateProductList(kCartUniqueItems);

      final r = _measure('CartProvider addToCart x$kCartUniqueItems', kCartUniqueItems, () {
        for (final p in products) {
          cart.addToCart(p, 1);
        }
      });

      print(r);
      expect(cart.itemCount, equals(kCartUniqueItems));
      expect(r.opsPerSecond, greaterThan(1000),
          reason: 'addToCart terlalu lambat');
    });

    test('Tambah produk sama ${kCartSameItemAdds}x (quantity accumulation)', () {
      final cart = CartProvider();
      final product = _makeProduct(0);

      final r = _measure('CartProvider addToCart sama x$kCartSameItemAdds', kCartSameItemAdds, () {
        for (int i = 0; i < kCartSameItemAdds; i++) {
          cart.addToCart(product, 1);
        }
      });

      print(r);
      expect(cart.items.first.quantity, equals(kCartSameItemAdds));
      expect(r.opsPerSecond, greaterThan(1000));
    });
  });

  // ── 4. CartProvider: Update & Remove ────────────────────────────────────
  group('4. CartProvider - Update & Remove', () {
    test('Update quantity $kCartUpdateRemove item, lalu hapus semua', () {
      final cart = CartProvider();
      final products = _generateProductList(kCartUpdateRemove);
      for (final p in products) {
        cart.addToCart(p, 1);
      }

      // Update all quantities
      final rUpdate = _measure('CartProvider updateQuantity x$kCartUpdateRemove', kCartUpdateRemove, () {
        for (final item in List.from(cart.items)) {
          cart.updateItemQuantity(item.id, item.quantity + 5);
        }
      });
      print(rUpdate);

      // Remove all items
      final rRemove = _measure('CartProvider removeFromCart x$kCartUpdateRemove', kCartUpdateRemove, () {
        for (final item in List.from(cart.items)) {
          cart.removeFromCart(item.id);
        }
      });
      print(rRemove);

      expect(cart.itemCount, equals(0));
    });
  });

  // ── 5. Simulasi Sesi Kasir ───────────────────────────────────────────────
  group('5. Simulasi Sesi Kasir (checkout berulang)', () {
    test('$kKasirSessions sesi kasir: masing-masing $kItemsPerSession item → checkout → clear', () {
      final products = _generateProductList(kKasirSessions * kItemsPerSession);
      const sessions = kKasirSessions;
      const itemsPerSession = kItemsPerSession;
      int totalItemsProcessed = 0;

      final r = _measure(
          'Sesi Kasir ${sessions}x$itemsPerSession item', sessions * itemsPerSession, () {
        for (int s = 0; s < sessions; s++) {
          final cart = CartProvider();

          // Tambah item ke cart
          for (int i = 0; i < itemsPerSession; i++) {
            cart.addToCart(products[(s * itemsPerSession + i) % products.length], 1 + i % 3);
          }

          // Hitung total (simulasi checkout)
          final total = cart.totalAmount;
          final bayar = total + 5000;
          final kembalian = bayar - total;

          // Verifikasi
          assert(total > 0, 'Total harus > 0');
          assert(kembalian >= 0, 'Kembalian tidak boleh negatif');
          assert(cart.itemCount == itemsPerSession);

          totalItemsProcessed += cart.itemCount;

          // Clear cart
          cart.clearCart();
          assert(cart.itemCount == 0, 'Cart harus kosong setelah clear');
        }
      });

      print(r);
      print('  Total item diproses: $totalItemsProcessed');
      expect(r.elapsed.inMilliseconds, lessThan(5000),
          reason: 'Simulasi kasir melebihi batas waktu');
    });
  });

  // ── 6. Kalkulasi Total & Profit ──────────────────────────────────────────
  group('6. Kalkulasi Total & Profit', () {
    test('Hitung total cart $kCalcProductCount item, ${kCalcIterations}x iterasi', () {
      final products = _generateProductList(kCalcProductCount);
      final cart = CartProvider();
      for (final p in products) {
        cart.addToCart(p, _random.nextInt(5) + 1);
      }

      const iterations = kCalcIterations;
      double lastTotal = 0;

      final r = _measure('Kalkulasi totalAmount x$kCalcIterations', iterations, () {
        for (int i = 0; i < iterations; i++) {
          lastTotal = cart.totalAmount;
        }
      });

      print(r);
      print('  Total terakhir: Rp ${lastTotal.toStringAsFixed(0)}');
      expect(r.opsPerSecond, greaterThan(5000),
          reason: 'Kalkulasi total terlalu lambat');
    });
  });

  // ── 7. ChangeNotifier Listener Stress ────────────────────────────────────
  group('7. ChangeNotifier (notifyListeners) Stress', () {
    test('notifyListeners ${kNotifyIterations}x dengan $kListenerCount listener aktif', () {
      final cart = CartProvider();
      int notifyCount = 0;
      const listenerCount = kListenerCount;
      const notifyIterations = kNotifyIterations;

      // Pasang beberapa listener
      for (int i = 0; i < listenerCount; i++) {
        cart.addListener(() => notifyCount++);
      }

      final product = _makeProduct(0);
      final r = _measure(
          'notifyListeners x$notifyIterations (${listenerCount}L)', notifyIterations, () {
        for (int i = 0; i < notifyIterations; i++) {
          cart.addToCart(product, 1); // setiap add memanggil notifyListeners
        }
      });

      print(r);
      // 10 listener × 2000 notify = 20000 panggilan listener
      expect(notifyCount, greaterThanOrEqualTo(notifyIterations * listenerCount),
          reason: 'Listener tidak terpanggil cukup banyak');
      expect(r.elapsed.inMilliseconds, lessThan(3000));
    });
  });
}

// ── Summary ───────────────────────────────────────────────────────────────────

void _printSummary() {
  final line = '-' * 80;
  print('\n$line');
  print('LOAD TEST SUMMARY - kasir_digital Provider & State Management');
  print(line);
  for (final r in _results) {
    final status = r.opsPerSecond >= 500 ? '✓' : (r.opsPerSecond >= 50 ? '⚠' : '✗');
    print('$status $r');
  }
  print(line);
  print('Total tests: ${_results.length}');
  print(line);
}


