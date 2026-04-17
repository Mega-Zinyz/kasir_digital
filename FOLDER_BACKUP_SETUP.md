# Folder Backup & Laporan - Dokumentasi

## ✅ Ringkasan

- ✅ Folder **Backup** dibuat otomatis saat instalasi
- ✅ Folder **Laporan** dibuat otomatis saat instalasi
- ✅ Folder tetap di-ensure ulang saat aplikasi berjalan
- ✅ Backup manual dan otomatis memakai format file yang sama
- ✅ File backup sekarang juga dapat menyimpan gambar produk yang dikelola aplikasi

---

## 📁 Struktur Folder

Setelah instalasi, akan ada struktur seperti ini:

```
C:\Users\<username>\AppData\Local\Kasir Digital\
├── kasir_digital.exe
├── Backup/                    ← Folder auto-created untuk backup otomatis
│   ├── kasir_backup_2026-02-24_093045.json
│   ├── kasir_backup_2026-02-24_093046.json
│   └── ...
├── Laporan/                   ← Folder auto-created untuk export laporan
│   ├── laporan_penjualan_2026-02-24.xlsx
│   └── ...
└── [library files]
```

---

## 🔄 Alur Folder

1. **Saat instalasi**
Installer membuat folder `Backup` dan `Laporan` melalui section `[Dirs]` di Inno Setup.

2. **Saat startup aplikasi**
`SettingsProvider` memastikan folder `Laporan` dan `Backup` tetap ada, lalu menetapkan default path export dan backup.

3. **Saat backup berjalan**
`BackupService` dipakai oleh backup manual maupun otomatis, sehingga isi file backup selalu konsisten.

---

## 📦 Isi Backup Saat Ini

- Data produk
- Data transaksi
- Item transaksi
- Salinan gambar produk yang disimpan di `assets/images`

---

## 🧪 Verifikasi Yang Disarankan

1. Install aplikasi lalu pastikan folder `Backup` dan `Laporan` sudah ada.
2. Buat backup manual dari menu `Backup` dan cek file JSON muncul di folder backup.
3. Aktifkan backup otomatis lalu verifikasi file baru terbentuk di folder yang sama.
4. Uji restore untuk memastikan data produk, transaksi, dan gambar produk kembali terbaca.

---

## 🔐 Permissions dan Uninstall

- Installer memberi permission tulis ke folder yang dibuat di `[Dirs]`.
- Uninstall tidak menghapus data user secara paksa.
- Folder aplikasi hanya ikut hilang jika sudah kosong.

---

## 📋 Catatan Operasional

- Folder `Backup` dipakai sebagai default lokasi file backup, tetapi user bisa mengubahnya dari Pengaturan.
- Folder `Laporan` dipakai sebagai default lokasi export laporan dan salinan struk.
- Jika folder belum ada saat runtime, aplikasi akan membuatnya ulang.

## 🛠️ Troubleshooting

### Issue: "Permission Denied" saat backup
Pastikan aplikasi dijalankan dari lokasi install default atau folder yang user-nya punya izin tulis.

### Issue: Folder tidak ada setelah install
Jalankan aplikasi sekali agar `SettingsProvider` dan service terkait membuat ulang folder yang diperlukan.

### Issue: Backup script fails
Periksa lokasi backup aktif, ruang disk, dan kemungkinan antivirus memblokir penulisan file.

---

**Status**: ✅ Sudah sesuai dengan installer per-user, backup terpadu, dan proteksi data user.
