# Struktur Folder Instalasi Kasir Digital

## 📁 Lokasi Instalasi Default
```
C:\Program Files\Kasir Digital\
```

## 🗂️ Struktur Folder Lengkap

```
Kasir Digital/
├── kasir_digital.exe              (Aplikasi utama)
├── *.dll files                    (Library dependencies)
├── data/                          (📊 Database)
│   └── kasir_digital.db          (SQLite Database - semua data transaksi & produk)
├── Laporan/                       (📋 Export Files)
│   ├── Laporan_Penjualan_*.pdf    (Export PDF transaksi)
│   ├── Laporan_Penjualan_*.xlsx   (Export Excel basic)
│   └── Laporan_Detail_Penjualan_*.xlsx  (Export Excel detail dari Yoga)
├── Backup/                        (💾 Backup Database)
│   ├── backup_*.zip              (Backup otomatis/manual)
│   └── [tanggal_backup]/         (Folder backup terorganisir)
└── assets/                        (🖼️ User Assets)
    └── images/                   (Foto produk)
        ├── product_*.jpg
        ├── product_*.png
        └── ...
```

## 🔧 Konfigurasi Path di Settings

Semua path sudah dikonfigurasi **relative terhadap lokasi instalasi aplikasi**:

| Jenis File | Path | Environment | Dibuat Saat |
|-----------|------|-------------|-----------|
| **Database** | `{app}/data/` | `database_service.dart` | Pertama kali buka app |
| **Laporan** | `{app}/Laporan/` | `settings_provider.dart` | Pertama kali buka app |
| **Backup** | `{app}/Backup/` | `settings_provider.dart` | Pertama kali buka app |
| **Gambar Produk** | `{app}/assets/images/` | Upload produk | Saat upload foto produk |

### Code References:

**Database Path** (`lib/services/database_service.dart`):
```dart
final executablePath = Platform.resolvedExecutable;
final appDir = Directory(executablePath).parent;
final dataDir = Directory('${appDir.path}/data');
final path = '${dataDir.path}/kasir_digital.db';
```

**Laporan & Backup Path** (`lib/providers/settings_provider.dart`):
```dart
final exePath = Platform.resolvedExecutable;
final appDirectory = File(exePath).parent.path;

// Laporan folder
final reportFolder = Directory('$appDirectory/Laporan');

// Backup folder
final backupFolder = Directory('$appDirectory/Backup');
```

## ✅ Keuntungan Struktur Ini

1. ✅ **Portable** - Semua data/laporan/backup ada dalam satu folder
2. ✅ **Auto-cleanup saat uninstall** - Installer Inno Setup sudah configure `[UninstallDelete]`
3. ✅ **User-friendly** - Mudah backup dengan copy satu folder `Kasir Digital/`
4. ✅ **Multi-user safe** - Setiap instalasi punya data tersendiri
5. ✅ **No Registry leftover** - Hanya folder yang perlu dihapus

## 🚀 Proses Instalasi

1. User download installer: `KasirDigital_Installer.exe`
2. Inno Setup membuat folder: `C:\Program Files\Kasir Digital\`
3. Installer copy executable + dependencies ke folder
4. Installer membuat subfolder: `data/`, `Laporan/`, `Backup/`, `assets/images/`
5. Aplikasi pertama kali buka → auto-create database `kasir_digital.db`

## 🗑️ Proses Uninstall

1. User klik "Uninstall Kasir Digital"
2. Inno Setup hapus:
   - ✅ `kasir_digital.exe` dan DLL files
   - ✅ `data/` folder beserta `kasir_digital.db`
   - ✅ `Laporan/` folder beserta semua file export
   - ✅ `Backup/` folder beserta semua file backup
   - ✅ `assets/images/` folder beserta semua foto produk
   - ✅ Folder `Kasir Digital/` jika kosong

**Hasil**: Aplikasi + semua file user terhapus 100% ✨

## 📝 Installer Configuration (Inno Setup)

File: `kasir_digital_installer.iss`

```ini
[Dirs]
Name: "{app}\Backup"; Permissions: users-full
Name: "{app}\Laporan"; Permissions: users-full
Name: "{app}\assets\images"; Permissions: users-full
Name: "{app}\data"; Permissions: users-full

[UninstallDelete]
Type: filesandordirs; Name: "{app}\Backup"
Type: filesandordirs; Name: "{app}\Laporan"
Type: filesandordirs; Name: "{app}\*"
Type: dirifempty; Name: "{app}"
```

## 🔐 Tips Keamanan

1. **Backup regular** - User bisa copy `Backup/` folder secara manual
2. **External backup** - Settings screen menyediakan opsi backup otomatis
3. **Cloud sync optional** - Bisa ditambahkan di masa depan

---

**Status**: ✅ Semua sudah dikonfigurasi dengan benar!
