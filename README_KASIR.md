# Kasir Digital - Sistem Point of Sales (POS)

Aplikasi Sistem Point of Sales (POS) yang kompleks dan profesional untuk Windows yang dibangun dengan Flutter. Aplikasi ini dirancang untuk memudahkan proses transaksi penjualan, manajemen inventori, dan analisis penjualan.

## 📋 Fitur Utama

### 1. **Dashboard**
- Menampilkan total penjualan bulan berjalan
- Statistik transaksi bulan ini
- Jumlah total produk di inventory
- Rata-rata nilai transaksi
- Riwayat transaksi terbaru dengan detail lengkap

### 2. **Sistem Penjualan (POS)**
- Interface penjualan yang responsif dengan layout split (produk & keranjang)
- Pencarian produk real-time
- Tampilan grid produk dengan informasi harga dan stok
- Keranjang belanja dengan:
  - Penambahan/pengurangan kuantitas
  - Subtotal otomatis per item
  - Total penjualan real-time
- Dialog checkout dengan:
  - Pilihan metode pembayaran (Tunai, Kartu Kredit, Transfer)
  - Perhitungan kembalian otomatis
  - Simpan transaksi ke database

### 3. **Manajemen Daftar Barang**
- Tampilan list produk yang terorganisir
- Pencarian barang berdasarkan nama/kode
- Tombol tambah barang baru dengan form validasi
- Fungsi edit dan hapus produk
- Detail modal untuk setiap produk
- Informasi: Nama, Kode, Harga, Stok, Kategori

### 4. **Riwayat Penjualan**
- Tabel transaksi dengan kolom:
  - Nomor transaksi
  - Tanggal & waktu
  - Jumlah penjualan
  - Metode pembayaran
  - Aksi (lihat detail/hapus)
- Filter tanggal range (dari - sampai)
- Statistik: Total penjualan dan jumlah transaksi
- Modal detail transaksi lengkap dengan:
  - Detail transaksi
  - List item yang dibeli
  - Total, pembayaran, dan kembalian

### 5. **Pengaturan**
- Profil toko (nama, telepon, alamat)
- Informasi aplikasi dan versi
- Fitur backup data
- Bantuan dan kebijakan privasi

## 🏗️ Arsitektur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                   # Data models
│   ├── product.dart         # Model produk
│   ├── transaction.dart      # Model transaksi
│   ├── transaction_item.dart # Model item transaksi
│   └── index.dart           # Export barrel file
├── services/                 # Services & database
│   └── database_service.dart # SQLite database operations
├── providers/                # State management (Provider)
│   ├── product_provider.dart
│   ├── transaction_provider.dart
│   ├── cart_provider.dart
│   └── index.dart
├── screens/                  # UI screens
│   ├── dashboard_screen.dart
│   ├── sales_screen.dart
│   ├── product_list_screen.dart
│   ├── history_screen.dart
│   ├── settings_screen.dart
│   └── index.dart
├── widgets/                  # Reusable widgets
│   ├── buttons.dart
│   ├── stat_card.dart
│   ├── sidebar.dart
│   └── index.dart
└── utils/                    # Utility functions
    └── formatters.dart       # Currency & date formatting
```

## 🛠️ Teknologi yang Digunakan

- **Flutter 3.11+** - Framework UI
- **Provider 6.0** - State Management
- **SQLite (sqflite)** - Local Database
- **intl** - Internationalization untuk formatting
- **uuid** - Unique ID generation
- **fl_chart** - Chart library
- **path_provider** - File system access

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.0.0
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  intl: ^0.19.0
  fl_chart: ^0.65.0
  uuid: ^4.0.0
```

## 🚀 Cara Menjalankan

### Prerequisites
1. Flutter SDK 3.11 atau lebih tinggi
2. Windows 10/11
3. Visual Studio 2022 atau Build Tools
4. **Developer Mode harus diaktifkan di Windows**

### Enable Developer Mode di Windows
Aplikasi memerlukan symlink support yang hanya tersedia di Developer Mode:
```powershell
start ms-settings:developers
```
Kemudian aktifkan "Developer Mode" di system settings.

### Instalasi & Running

1. **Install dependencies:**
   ```bash
   cd d:\Project\Flutter\kasir_digital
   flutter pub get
   ```

2. **Jalankan aplikasi:**
   ```bash
   flutter run -d windows
   ```

3. **Build untuk production:**
   ```bash
   flutter build windows --release
   ```
   Output akan berada di: `build/windows/runner/Release/`

## 💾 Database

Aplikasi menggunakan SQLite local database yang tersimpan di:
```
C:\Users\YourUsername\AppData\Local\kasir_digital.db
```

### Tabel Database:
1. **products** - Menyimpan data barang
2. **transactions** - Menyimpan data transaksi
3. **transaction_items** - Menyimpan detail item setiap transaksi

## 📊 Fitur Format

### Currency Formatting
- Indonesian format (Rp dengan separator)
- Contoh: "Rp 150.000" untuk nilai besar
- Compact format: "Rp 150K" untuk format ringkas

### Date/Time Formatting
- Format Indonesia (dd MMMM yyyy)
- Contoh: "21 Februari 2026"
- Support untuk berbagai format (tanggal, waktu, bulan-tahun)

## 🎯 Alur Penggunaan

### Transaksi Penjualan:
1. Buka tab **Penjualan**
2. Cari produk atau scroll list produk
3. Klik produk untuk pilih kuantitas
4. Produk akan ditambah ke keranjang di sebelah kanan
5. Review keranjang dan klik **Checkout**
6. Pilih metode pembayaran
7. Masukkan jumlah pembayaran
8. Klik **Proses** untuk simpan transaksi

### Manajemen Barang:
1. Buka tab **Daftar Barang**
2. Lihat semua barang atau cari dengan search
3. Klik tombol **+ (FAB)** untuk tambah barang baru
4. Isi form (Nama, Kode, Harga, Stok)
5. Klik barang untuk lihat detail atau hapus

### Review Penjualan:
1. Buka tab **History**
2. Filter tanggal range sesuai kebutuhan (opsional)
3. Klik **Tampilkan** untuk refresh data
4. Lihat statistik dan table transaksi
5. Klik icon **👁️** untuk lihat detail transaksi
6. Klik icon **🗑️** untuk hapus transaksi

## ⚙️ State Management with Provider

Aplikasi menggunakan Provider untuk state management:

### ProductProvider
```dart
// Load semua produk
context.read<ProductProvider>().loadProducts();

// Search produk
context.read<ProductProvider>().searchProducts('keyword');

// Add/Update/Delete produk
await context.read<ProductProvider>().addProduct(...);
```

### TransactionProvider
```dart
// Load transaksi
await context.read<TransactionProvider>().loadTransactions();

// Add transaksi
await context.read<TransactionProvider>().addTransaction(...);
```

### CartProvider
```dart
// Add to cart
context.read<CartProvider>().addToCart(product, quantity);

// Update quantity
context.read<CartProvider>().updateItemQuantity(itemId, newQuantity);

// Clear cart
context.read<CartProvider>().clearCart();
```

## 🎨 UI Responsiveness

Aplikasi otomatis menyesuaikan dengan ukuran screen:
- **Desktop (lebar > 600px)**: Sidebar navigasi vertikal di sebelah kiri
- **Mobile (lebar ≤ 600px)**: Bottom navigation bar

## 📱 Windows-Specific Optimizations

- Full integration dengan Windows UI standards
- Support untuk window maximize/minimize
- Responsive layout untuk berbagai ukuran window

## 🔍 Testing

Jalankan analisis:
```bash
flutter analyze
```

Tidak ada error (hanya info & warning yang safe to ignore).

## 📝 Catatan

1. Semua data disimpan secara lokal di SQLite
2. Tidak ada koneksi internet yang diperlukan
3. Backup data harus dilakukan manual
4. Support dapat diakses melalui menu Pengaturan

## 📄 Lisensi

Proprietary - Untuk penggunaan internal

---

**Status**: ✅ Production Ready
**Versi**: 1.0.0
**Terakhir Update**: Februari 2026
