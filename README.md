# Kasir Digital

Aplikasi Point of Sales (POS) berbasis Flutter untuk Windows dengan fokus pada transaksi penjualan, manajemen barang, analitik penjualan, backup data, dan penyimpanan aset lokal.

## Fitur Utama

- Dashboard ringkas untuk statistik penjualan dan aktivitas terbaru
- Penjualan kasir dengan keranjang, checkout, dan perhitungan kembalian
- Daftar Barang untuk tambah, edit, hapus, dan kelola stok produk
- History transaksi dengan filter tanggal dan export laporan
- Analitik untuk melihat tren penjualan dan performa produk
- Backup manual dan otomatis, termasuk pemulihan gambar produk yang dikelola aplikasi

## Struktur Data Lokal

- Database SQLite disimpan di folder aplikasi: `data/kasir_digital.db`
- Folder laporan default: `Laporan/`
- Folder backup default: `Backup/`
- Gambar produk tersimpan di `assets/images/`

Default instalasi Windows saat ini menggunakan mode per-user:

`C:\Users\<username>\AppData\Local\Kasir Digital\`

## Menjalankan Proyek

```bash
flutter pub get
flutter run -d windows
```

Untuk build release:

```bash
flutter build windows --release
```

## Dokumen Terkait

- `README_KASIR.md` untuk ringkasan fitur aplikasi
- `SETUP_GUIDE.md` untuk panduan setup dan build
- `STRUKTUR_FOLDER_INSTALASI.md` untuk struktur folder hasil instalasi
- `FOLDER_BACKUP_SETUP.md` untuk perilaku backup dan laporan
