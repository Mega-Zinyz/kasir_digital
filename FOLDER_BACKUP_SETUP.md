# Folder Backup & Laporan - Dokumentasi

## ✅ Masalah yang Sudah Diselesaikan

Sebelumnya:
- ❌ Folder Backup hanya dibuat saat app berjalan (runtime)
- ❌ Jika install tapi belum buka app, folder tidak ada
- ❌ Bisa cause error jika backup dijadwalkan sebelum folder ada

Sekarang:
- ✅ Folder **Backup** dibuat otomatis saat instalasi
- ✅ Folder **Laporan** dibuat otomatis saat instalasi
- ✅ Folder juga di-ensure ulang saat app startup
- ✅ Backup harian/mingguan dijamin berjalan tanpa error

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

## 🔄 Alur Folder Creation

### 1. **Saat Instalasi** (Installer)
```
Installer berjalan
    ↓
[Dirs] section di installer.iss
    ├─ Create: {app}\Backup ✓
    └─ Create: {app}\Laporan ✓
    ↓
User selesai install
Folder sudah siap! ✓
```

### 2. **Saat App Startup** (Double-Check)
```
App dibuka
    ↓
SettingsProvider() constructor
    ↓
_initializePaths() method
    ├─ Get app directory
    ├─ Ensure Laporan folder exists ✓
    ├─ Ensure Backup folder exists ✓
    └─ Set _backupPath
    ↓
Debug logs:
- "SettingsProvider: Initialized paths"
- "Backup path: C:\Users\<username>\AppData\Local\Kasir Digital\Backup"
- "Export path: C:\Users\<username>\AppData\Local\Kasir Digital\Laporan"
```

### 3. **Saat Backup Dijadwalkan** (Safe Operation)
```
MainScreen._initializeBackupScheduler()
    ↓
ScheduledBackupService.startScheduledBackups()
    ↓
_initializeBackupDirectory()
    ├─ Check if folder exists
    ├─ If NOT: Create folder ✓
    └─ _backupDirectory ready
    ↓
First backup runs: File saved to _backupDirectory ✓
```

---

## 📝 File-File yang Diubah

### 1. **kasir_digital_installer.iss** (Installer Script)
✅ **Tambah [Dirs] section:**
```inno
[Dirs]
Name: "{app}\Backup"; Permissions: users-modify,users-change,users-delete
Name: "{app}\Laporan"; Permissions: users-modify,users-change,users-delete
```

✅ **Update [UninstallDelete]:**
```inno
[UninstallDelete]
Type: filesandordirs; Name: "{app}\Backup"
Type: filesandordirs; Name: "{app}\Laporan"
...
```

### 2. **providers/settings_provider.dart**
✅ **Tambah getter:**
```dart
String get backupPath => _backupPath;
```

✅ **Rename & enhance initialization:**
```dart
// Sebelum
_initializeDefaultExportPath()

// Sesudah
_initializePaths()  // Buat BOTH Laporan & Backup folder
```

### 3. **services/scheduled_backup_service.dart**
✅ **Improve _initializeBackupDirectory():**
```dart
// Lebih verbose logging untuk debugging
if (!backupFolder.existsSync()) {
  backupFolder.createSync(recursive: true);
  debugPrint('Created backup directory: ${backupFolder.path}');
}
```

---

## 🧪 Test Senario

### Test 1: Fresh Install (Simulate User)
```
1. Uninstall aplikasi (jika ada)
2. Jalankan installer baru
3. Install di: C:\Users\<username>\AppData\Local\Kasir Digital
4. Cek folder:
    ✓ C:\Users\<username>\AppData\Local\Kasir Digital\Backup EXIST
    ✓ C:\Users\<username>\AppData\Local\Kasir Digital\Laporan EXIST
5. Double-click kasir_digital.exe
6. Check console/debug output:
   ✓ "SettingsProvider: Initialized paths"
   ✓ "Backup path: ..."
```

### Test 2: Scheduled Daily Backup (Without Errors)
```
1. Open app
2. Go to: Sidebar → Backup → Pengaturan Backup Otomatis
3. Select: "Setiap Hari"
4. Wait or restart app
5. Check: C:\Users\<username>\AppData\Local\Kasir Digital\Backup
   ✓ File kasir_backup_YYYY-MM-DD_HHMMSS.json EXIST
   ✓ No error logged
6. Success notification shown
```

### Test 3: Manual Export
```
1. Open app
2. Go to: Sidebar → Backup → Export Backup
3. Save dialog opens (default path: Laporan folder)
4. Browse to C:\Users\<username>\AppData\Local\Kasir Digital\Laporan
   ✓ Folder accessible and writable
5. Export successful
```

### Test 4: Folder Permissions (Windows)
```
1. Run app as Regular User (non-admin)
2. Perform backup
3. ✓ No permission denied errors
4. Note: [Dirs] in installer sets proper permissions
```

---

## 🔐 Security & Permissions

**Installer [Dirs] Permissions:**
```inno
Name: "{app}\Backup"; 
  Permissions: users-modify,users-change,users-delete
```

Ini memastikan:
- ✅ Regular user (non-admin) bisa write/modify file
- ✅ User bisa delete old backups jika perlu
- ✅ Tidak ada "Access Denied" error

---

## 📊 Folder Structure Summary

| Folder | Purpose | Created | Fallback |
|--------|---------|---------|----------|
| `/Backup` | Auto-backup files | Installer + Settings | ScheduledBackupService |
| `/Laporan` | Manual export files | Installer + Settings | Settings init |
| `/assets/images` | Product images | ImageService | On-demand |

---

## 💡 Enhanced Robustness

Sekarang sistem punya **3 layer** folder creation:

1. **Installer Layer** (Primary)
   - Membuat folder saat install
   - Efficient, one-time setup

2. **Settings Layer** (Init)
   - Double-check saat app startup
   - Fallback jika installer failed
   - Create folder jika tidak ada

3. **Service Layer** (Runtime)
   - Final check saat backup dijadwalkan
   - Safe operation guaranteed

---

## 🚀 Catatan Uninstall

Installer sekarang tidak lagi menghapus folder data user secara paksa.

```inno
[UninstallDelete]
Type: dirifempty; Name: "{app}"
```

Implikasi:
- ✅ File aplikasi terhapus saat uninstall
- ✅ Data `Backup`, `Laporan`, `data`, dan `assets/images` tetap aman
- ✅ Folder aplikasi baru ikut hilang jika memang sudah kosong

---

## 📋 Troubleshooting

### Issue: "Permission Denied" saat backup
**Solution:** Run app dengan right folder permissions (solved by installer)

### Issue: Folder tidak ada setelah install
**Solution:** Jalankan app sekali → Settings akan create folder

### Issue: Backup script fails
**Solution:** Jika semua 3 layer fail, check:
1. Disk space available
2. App run as regular user (not problematic case scenario)
3. Anti-virus blocking file writes

---

## ✨ Summary

✅ **Installer:** Membuat folder `Backup` dan `Laporan` otomatis  
✅ **App Init:** Double-check dan ensure folder exists  
✅ **Backup Service:** Safe fallback jika folder belum ada  
✅ **Uninstall:** Tidak menghapus data user secara agresif  
✅ **Permissions:** User (non-admin) bisa access & modify  

**Result:** Zero error saat backup harian/mingguan dijadwalkan! 🎉
