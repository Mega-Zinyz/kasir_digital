# Struktur Folder Instalasi Kasir Digital

## 📁 Lokasi Instalasi Default
```
C:\Users\<username>\AppData\Local\Kasir Digital\
```

## 🗂️ Struktur Folder

```
Kasir Digital/
├── kasir_digital.exe
├── *.dll
├── data/
│   └── kasir_digital.db
├── Laporan/
├── Backup/
└── assets/
    └── images/
```

## 🔧 Folder yang Dipakai Aplikasi

Semua path utama dihitung relatif terhadap lokasi `.exe`.

| Jenis File | Path | Environment | Dibuat Saat |
|-----------|------|-------------|-----------|
| **Database** | `{app}/data/` | `database_service.dart` | Pertama kali buka app |
| **Laporan** | `{app}/Laporan/` | `settings_provider.dart` | Pertama kali buka app |
| **Backup** | `{app}/Backup/` | `settings_provider.dart` | Pertama kali buka app |
| **Gambar Produk** | `{app}/assets/images/` | Upload produk | Saat upload foto produk |

## 🚀 Alur Singkat

1. Installer membuat folder aplikasi di `AppData\Local\Kasir Digital`.
2. Installer menyiapkan `data`, `Laporan`, `Backup`, dan `assets/images`.
3. Saat aplikasi pertama dibuka, `SettingsProvider` dan service terkait memastikan folder masih ada.
4. Database dibuat di `data/kasir_digital.db` saat pertama kali dipakai.

## 🗑️ Uninstall

Uninstall tidak lagi menghapus data user secara paksa.

- File aplikasi, shortcut, dan uninstaller dibersihkan.
- Folder aplikasi hanya ikut terhapus jika memang kosong.
- Folder `data`, `Laporan`, `Backup`, dan `assets/images` tetap aman kecuali dihapus manual.

## 📝 Potongan Konfigurasi Installer

```ini
[Dirs]
Name: "{app}\Backup"; Permissions: users-full
Name: "{app}\Laporan"; Permissions: users-full
Name: "{app}\assets\images"; Permissions: users-full
Name: "{app}\data"; Permissions: users-full

[UninstallDelete]
Type: dirifempty; Name: "{app}"
```

## ✅ Catatan Penting

- Install default bersifat per-user, jadi tidak perlu hak admin.
- Folder yang dibuat installer memang dipakai oleh runtime aplikasi.
- User tetap bisa mengubah lokasi laporan dan backup dari menu Pengaturan.

**Status**: ✅ Sudah selaras dengan installer per-user dan proteksi data user.
