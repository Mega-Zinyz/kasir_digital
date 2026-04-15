# Stress & Load Test — kasir_digital

Dokumentasi ini menjelaskan dua suite pengujian performa yang disertakan dalam proyek:

| Suite | File | Fokus |
|---|---|---|
| Database Stress Test | `database_stress_test.dart` | Layer SQLite (sqflite_common_ffi) |
| Provider Load Test | `provider_load_test.dart` | Layer state management (Provider / ChangeNotifier) |

---

## Cara Menjalankan

### Semua suite (PowerShell)
```powershell
.\Run-StressTest.ps1
```

### Pilih suite tertentu
```powershell
.\Run-StressTest.ps1 -Test database   # hanya database
.\Run-StressTest.ps1 -Test provider   # hanya provider
.\Run-StressTest.ps1 -Verbose         # tampilkan output lengkap
```

### Langsung via flutter test
```powershell
# Database stress (timeout 120 detik)
flutter test test/stress/database_stress_test.dart --timeout=120s

# Provider load (timeout 60 detik)
flutter test test/stress/provider_load_test.dart --timeout=60s
```

> Laporan otomatis tersimpan di `build/reports/stress/stress_report_YYYYMMDD_HHmmss.txt` setiap kali menggunakan `Run-StressTest.ps1`.

---

## 1. Database Stress Test (`database_stress_test.dart`)

### Arsitektur

- Menggunakan **sqflite_common_ffi** agar dapat dijalankan di luar aplikasi Flutter (pure Dart test runner, tanpa emulator/device).
- Database dibuat di folder **temp sistem** (`Directory.systemTemp`) sehingga tidak mengotori data produksi.
- Schema yang dibuat identik dengan schema produksi (tabel `categories`, `products`, `transactions`, `transaction_items`).
- Semua hasil diukur oleh helper `_measure()` yang mengembalikan objek `_Result` berisi `count`, `elapsed`, dan `opsPerSecond`.
- Ringkasan dicetak otomatis di `tearDownAll`.

### Grup Test & Tujuan

| No. | Grup | Skenario | Target Minimum |
|-----|------|----------|----------------|
| 1 | **Bulk Insert Produk** | Insert 100 / 500 / 1.000 produk menggunakan `batch()` | > 200 ops/s |
| 2 | **Query getAllProducts** | Query seluruh produk diulang 50× berturut-turut | > 10 ops/s |
| 3 | **Pencarian Produk (LIKE)** | Search `name LIKE` dan `code LIKE` 100× dengan 6 keyword berbeda | > 30 ops/s |
| 4a | **Update Stok — satu per satu** | Update 500 baris satu per satu via `rawUpdate` | > 100 ops/s |
| 4b | **Update Stok — batch** | Update 500 baris sekaligus via `batch()` | > 500 ops/s |
| 5 | **Bulk Insert Transaksi** | Insert 500 transaksi + 500 transaction_items sekaligus via batch | > 200 ops/s |
| 6 | **Query Transaksi (Date Range)** | Query transaksi 30 hari terakhir, diulang 30× | > 10 ops/s |
| 7 | **Concurrent Read Simulation** | 20 goroutine/Future paralel, masing-masing query `products` + `transactions` | < 5.000 ms total |
| 8 | **Delete Massal** | Hapus 500 transaksi beserta items via batch | > 100 ops/s |
| 9 | **Mixed Load (CRUD)** | Insert + Query + Update bergantian 200× iterasi | < 30 detik total |

### Cara Membaca Output

```
[Bulk Insert 1000 produk                  ] count=  1000 | ms=    312 | ops/s=    3205.1
```

| Kolom | Arti |
|---|---|
| `count` | Jumlah operasi yang dilakukan |
| `ms` | Total waktu eksekusi dalam milidetik |
| `ops/s` | Operasi per detik (throughput) |

Simbol di ringkasan akhir:

| Simbol | Threshold |
|---|---|
| `✓` | ≥ 100 ops/s |
| `⚠` | 30–99 ops/s |
| `✗` | < 30 ops/s |

### Mengapa `sqflite_common_ffi`?

SQLite pada Flutter desktop menggunakan FFI. Tests berjalan dengan `sqfliteFfiInit()` sehingga **tidak memerlukan device/emulator** dan dapat dijalankan di CI/CD murni di Windows.

---

## 2. Provider Load Test (`provider_load_test.dart`)

### Arsitektur

- Seluruh test **synchronous** (tidak membutuhkan database). Data dibuat in-memory.
- Data produk dihasilkan oleh `_makeProduct(i)` dengan **seed tetap** (`Random(42)`) agar hasil reproducible.
- Helper `_measure()` menggunakan `Stopwatch` dan mengembalikan `_Result` sinkron.
- Ringkasan dicetak di `tearDownAll`.

### Grup Test & Tujuan

| No. | Grup | Skenario | Target Minimum |
|-----|------|----------|----------------|
| 1 | **Inisialisasi Produk** | Buat list 1.000 / 5.000 / 10.000 objek `Product` in-memory | < 2.000 ms |
| 2a | **Filter In-Memory** | Filter 5.000 produk dengan `String.contains` diulang 1.000× | > 50 ops/s |
| 2b | **Sort In-Memory** | Sort 5.000 produk berdasarkan harga diulang 500× | > 10 ops/s |
| 3a | **CartProvider — item unik** | Tambah 500 produk berbeda ke cart (`addToCart`) | > 1.000 ops/s |
| 3b | **CartProvider — accumulation** | Tambah produk yang sama 1.000× (queue quantity bertambah) | > 1.000 ops/s |
| 4 | **CartProvider — Update & Remove** | Update quantity + hapus 200 item | (fungsional) |
| 5 | **Simulasi Sesi Kasir** | 50 sesi: masing-masing 10 item → hitung total → `clearCart()` | < 5.000 ms |
| 6 | **Kalkulasi Total & Profit** | Hitung `totalAmount` cart 1.000 item, diulang 500× | > 5.000 ops/s |
| 7 | **ChangeNotifier Stress** | `notifyListeners` 2.000× dengan 10 listener aktif | < 3.000 ms |

### Cara Membaca Output

```
[CartProvider addToCart x500             ] count=   500 | ms=      1 | ops/s=  500000.0
```

Simbol di ringkasan akhir:

| Simbol | Threshold |
|---|---|
| `✓` | ≥ 500 ops/s |
| `⚠` | 50–499 ops/s |
| `✗` | < 50 ops/s |

---

## Menafsirkan Hasil

### Hasil dianggap baik jika:
- Semua `expect` lulus (tidak ada test yang fail).
- Simbol `✓` mendominasi ringkasan.
- Tidak ada suite yang melebihi timeout.

### Hasil yang perlu diperhatikan:
- Simbol `⚠` pada operasi database → pertimbangkan menambahkan **index** pada kolom yang sering di-query (misal: `name`, `transactionDate`).
- Simbol `✗` → kemungkinan ada bottleneck serius; periksa apakah database corrupt atau disk terlalu lambat.
- Test **Concurrent Read** timeout → bisa jadi SQLite dikonfigurasi dengan `singleInstance: true` yang membatasi konkurensi.

### Tips optimasi berdasarkan hasil:
| Gejala | Kemungkinan Penyebab | Solusi |
|---|---|---|
| Insert lambat | Tidak pakai batch | Gunakan `db.batch()` |
| Search LIKE lambat | Tidak ada index | `CREATE INDEX idx_product_name ON products(name)` |
| Sort lambat | Sort dilakukan di Dart | Tambahkan `ORDER BY` di query SQL |
| notifyListeners lambat | Terlalu banyak widget rebuild | Pisahkan Provider atau gunakan `Selector` |

---

## Struktur File

```
test/
└── stress/
    ├── README.md                  ← dokumen ini
    ├── database_stress_test.dart  ← stress test layer SQLite
    └── provider_load_test.dart    ← load test layer Provider

Run-StressTest.ps1                 ← runner otomatis (PowerShell)
build/reports/stress/              ← laporan hasil (auto-generated)
```

---

## Konfigurasi Beban Test

Semua nilai jumlah iterasi, ukuran dataset, dan jumlah sesi dikumpulkan dalam **satu blok konstanta** di bagian atas masing-masing file. Cukup ubah nilai di sana tanpa perlu menyentuh kode test.

### `database_stress_test.dart`

```dart
const kBulkInsertCounts     = [100, 500, 1000]; // Jumlah produk bulk insert (group 1)
const kQueryIterations      = 50;   // Berapa kali query semua produk (group 2)
const kSearchIterations     = 100;  // Berapa kali search LIKE (group 3)
const kUpdateCount          = 500;  // Produk yang diupdate stok (group 4)
const kTransactionCount     = 500;  // Transaksi yang diinsert (group 5)
const kDateRangeIterations  = 30;   // Berapa kali query date-range (group 6)
const kConcurrentParallel   = 20;   // Jumlah query paralel (group 7)
const kDeleteCount          = 500;  // Transaksi yang dihapus (group 8)
const kMixedLoadCount       = 200;  // Iterasi mixed CRUD (group 9)
```

### `provider_load_test.dart`

```dart
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
```

> Setelah mengubah nilai konstanta, jalankan ulang test. Semua label output (nama test, jumlah count) akan ikut menyesuaikan secara otomatis.

---

## Catatan

- Test ini **tidak mengubah data produksi**. Database dibuat di folder temp dan ditutup setelah test selesai.
- Angka threshold (`greaterThan(...)`) dikalibrasi untuk mesin pengembang biasa (laptop mid-range). Pada hardware yang lebih lambat, threshold dapat disesuaikan.
- Warning `file_picker` yang muncul saat `flutter analyze` adalah warning dari package pihak ketiga, bukan dari kode test ini.
