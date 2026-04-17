import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/index.dart';
import '../utils/app_constants.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _lowStockController;

  @override
  void initState() {
    super.initState();
    final settingsProvider = context.read<SettingsProvider>();
    _lowStockController = TextEditingController(
      text: settingsProvider.lowStockThreshold.toString(),
    );
  }

  @override
  void dispose() {
    _lowStockController.dispose();
    super.dispose();
  }

  void _saveLowStockThreshold() {
    final value = int.tryParse(_lowStockController.text);
    if (value != null && value > 0) {
      context.read<SettingsProvider>().setLowStockThreshold(value);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batas stok minimal diset ke $value unit'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nilai yang valid'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _selectExportFolder() async {
    return await FilePicker.getDirectoryPath();
  }

  void _handleExportPathSelection() async {
    final path = await _selectExportFolder();
    if (!mounted) return;

    if (path != null) {
      // ignore: use_build_context_synchronously
      context.read<SettingsProvider>().setExportPath(path);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder laporan diatur ke: $path'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleBackupPathSelection() async {
    final path = await _selectExportFolder();
    if (!mounted) return;

    if (path != null) {
      // ignore: use_build_context_synchronously
      context.read<SettingsProvider>().setBackupPath(path);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder backup diatur ke: $path'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showHistoryDeletePinDialog() async {
    final settingsProvider = context.read<SettingsProvider>();
    final currentPinController = TextEditingController();
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            settingsProvider.hasHistoryDeletePin
                ? 'Ubah PIN Hapus History'
                : 'Atur PIN Hapus History',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (settingsProvider.hasHistoryDeletePin) ...[
                TextField(
                  controller: currentPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'PIN Lama',
                    hintText: 'Masukkan PIN saat ini',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PIN Baru',
                  hintText: 'Minimal 4 digit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi PIN',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            if (settingsProvider.hasHistoryDeletePin)
              TextButton(
                onPressed: () async {
                  final currentPin = currentPinController.text.trim();

                  if (!settingsProvider.verifyHistoryDeletePin(currentPin)) {
                    setDialogState(() {
                      errorText = 'PIN lama tidak valid';
                    });
                    return;
                  }

                  await settingsProvider.clearHistoryDeletePin();
                  if (!mounted || !dialogContext.mounted) return;

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN hapus history berhasil direset'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: Text(
                  'Reset PIN',
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPin = currentPinController.text.trim();
                final pin = pinController.text.trim();
                final confirmPin = confirmController.text.trim();

                if (settingsProvider.hasHistoryDeletePin &&
                    !settingsProvider.verifyHistoryDeletePin(currentPin)) {
                  setDialogState(() {
                    errorText = 'PIN lama tidak valid';
                  });
                  return;
                }

                if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
                  setDialogState(() {
                    errorText = 'PIN harus 4-8 digit angka';
                  });
                  return;
                }

                if (pin != confirmPin) {
                  setDialogState(() {
                    errorText = 'PIN konfirmasi tidak cocok';
                  });
                  return;
                }

                await settingsProvider.setHistoryDeletePin(pin);
                if (!mounted || !dialogContext.mounted) return;

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN hapus history berhasil disimpan'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Profil Toko'),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              final profile = settingsProvider.storeProfile;

              return Column(
                children: [
                  SettingsTile(
                    icon: Icons.store,
                    title: 'Nama Toko',
                    subtitle: profile.name,
                    onTap: () {
                      final controller = TextEditingController(
                        text: profile.name,
                      );
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Edit Nama Toko'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'Nama Toko',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (controller.text.isNotEmpty) {
                                  context.read<SettingsProvider>().setStoreName(
                                    controller.text,
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Nama toko berhasil diperbarui',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Simpan'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.phone,
                    title: 'Nomor Telepon',
                    subtitle: profile.phone,
                    onTap: () {
                      final controller = TextEditingController(
                        text: profile.phone,
                      );
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Edit Nomor Telepon'),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Nomor Telepon',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (controller.text.isNotEmpty) {
                                  context
                                      .read<SettingsProvider>()
                                      .setStorePhone(controller.text);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Nomor telepon berhasil diperbarui',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Simpan'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.location_on,
                    title: 'Alamat',
                    subtitle: profile.address,
                    onTap: () {
                      final controller = TextEditingController(
                        text: profile.address,
                      );
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Edit Alamat'),
                          content: TextField(
                            controller: controller,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Alamat',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (controller.text.isNotEmpty) {
                                  context
                                      .read<SettingsProvider>()
                                      .setStoreAddress(controller.text);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Alamat berhasil diperbarui',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Simpan'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Inventori'),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) => SettingsTile(
              icon: Icons.warning_amber_rounded,
              title: 'Batas Stok Minimal',
              subtitle: '${settingsProvider.lowStockThreshold} unit',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Atur Batas Stok Minimal'),
                    content: TextField(
                      controller: _lowStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah unit',
                        hintText: 'Contoh: 5',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: _saveLowStockThreshold,
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Export & Backup'),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              final exportPath = settingsProvider.getExportPath();
              final displayPath = exportPath.isNotEmpty
                  ? exportPath.split('\\').last == 'Laporan'
                        ? 'Laporan folder (default)'
                        : exportPath
                  : 'Tidak ada folder yang dipilih';

              return SettingsTile(
                icon: Icons.folder,
                title: 'Folder Laporan (Export)',
                subtitle: displayPath,
                onTap: () {
                  _handleExportPathSelection();
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              final backupPath = settingsProvider.getBackupPath();
              final displayPath = backupPath.isNotEmpty
                  ? backupPath.split('\\').last == 'Backup'
                        ? 'Backup folder (default)'
                        : backupPath
                  : 'Tidak ada folder yang dipilih';

              return SettingsTile(
                icon: Icons.folder_special,
                title: 'Folder Backup',
                subtitle: displayPath,
                onTap: () {
                  _handleBackupPathSelection();
                },
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Keamanan Transaksi'),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) => SettingsTile(
              icon: Icons.lock_outline,
              title: 'PIN Hapus History',
              subtitle: settingsProvider.historyDeletePinStatus,
              onTap: _showHistoryDeletePinDialog,
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Perangkat Terhubung'),
          Consumer<HardwareProvider>(
            builder: (context, hardwareProvider, _) {
              final cs = Theme.of(context).colorScheme;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final connected = hardwareProvider.allDevicesConnected;
              return Column(
                children: [
                  // Overall Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: connected
                          ? (isDark
                                ? cs.secondaryContainer
                                : cs.secondary.withValues(alpha: 0.08))
                          : (isDark
                                ? cs.tertiaryContainer
                                : cs.tertiary.withValues(alpha: 0.08)),
                      border: Border.all(
                        color: connected
                            ? cs.secondary.withValues(alpha: 0.5)
                            : cs.tertiary.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          connected
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          color: connected ? cs.secondary : cs.tertiary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                connected
                                    ? 'Semua Perangkat Terhubung'
                                    : 'Ada Perangkat Tidak Terhubung',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: connected
                                      ? (isDark
                                            ? cs.onSecondaryContainer
                                            : cs.secondary)
                                      : (isDark
                                            ? cs.onTertiaryContainer
                                            : cs.tertiary),
                                ),
                              ),
                              Text(
                                '${hardwareProvider.connectedDevicesCount}/${hardwareProvider.totalDevicesCount} Perangkat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Device List
                  ...hardwareProvider.devices.map((device) {
                    IconData deviceIcon;
                    switch (device.type) {
                      case 'scanner':
                        deviceIcon = Icons.qr_code_scanner;
                        break;
                      case 'printer':
                        deviceIcon = Icons.print;
                        break;
                      case 'cashdrawer':
                        deviceIcon = Icons.account_balance_wallet;
                        break;
                      default:
                        deviceIcon = Icons.device_unknown;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: device.connected
                              ? cs.secondary.withValues(alpha: 0.5)
                              : cs.error.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(6),
                        color: device.connected
                            ? (isDark
                                  ? cs.secondaryContainer
                                  : cs.secondary.withValues(alpha: 0.08))
                            : (isDark
                                  ? cs.errorContainer
                                  : cs.error.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            deviceIcon,
                            color: device.connected
                                ? (isDark
                                      ? cs.onSecondaryContainer
                                      : cs.secondary)
                                : (isDark ? cs.onErrorContainer : cs.error),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: device.connected
                                        ? (isDark
                                              ? cs.onSecondaryContainer
                                              : cs.secondary)
                                        : (isDark
                                              ? cs.onErrorContainer
                                              : cs.error),
                                  ),
                                ),
                                if (device.details != null)
                                  Text(
                                    device.details!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: device.connected ? cs.secondary : cs.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              device.connected ? 'OK' : 'OFFLINE',
                              style: TextStyle(
                                color: device.connected
                                    ? cs.onSecondary
                                    : cs.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Refresh Button
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: hardwareProvider.isScanning
                        ? null
                        : () {
                            hardwareProvider.refreshDevices();
                          },
                    icon: const Icon(Icons.refresh),
                    label: hardwareProvider.isScanning
                        ? const Text('Memindai...')
                        : const Text('Pindai Ulang'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Tampilan'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => SettingsTile(
              icon: themeProvider.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
              title: 'Mode Gelap',
              subtitle: themeProvider.isDarkMode ? 'Aktif' : 'Tidak aktif',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.setDarkMode(value),
              ),
              onTap: () => themeProvider.setDarkMode(!themeProvider.isDarkMode),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Lainnya'),
          SettingsTile(
            icon: Icons.help,
            title: 'Bantuan',
            subtitle: 'FAQ dan cara penggunaan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          SettingsTile(
            icon: Icons.privacy_tip,
            title: 'Kebijakan Privasi',
            subtitle: 'Baca kebijakan kami',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Kebijakan Privasi'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Perlindungan Data Pribadi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aplikasi Kasir Digital berkomitmen untuk melindungi privasi dan data pribadi pengguna. Kami menjaga kerahasiaan informasi yang Anda berikan.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Pengumpulan Data',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Kami hanya mengumpulkan data yang diperlukan untuk operasi sistem, seperti informasi penjualan, data produk, dan profil toko. Data tidak akan dibagikan kepada pihak ketiga tanpa persetujuan Anda.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Keamanan Data',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Data disimpan secara lokal di perangkat Anda dan dilindungi dengan enkripsi standar. Kami menyarankan membuat backup secara berkala untuk mencegah kehilangan data.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Hak Pengguna',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Anda memiliki hak untuk mengakses, mengubah, dan menghapus data pribadi Anda kapan saja melalui menu pengaturan aplikasi.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Perubahan Kebijakan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Kami dapat memperbarui kebijakan privasi ini kapan saja. Perubahan akan diberi tahu kepada pengguna melalui pembaruan aplikasi.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),
          SettingsTile(
            icon: Icons.info,
            title: 'Tentang Aplikasi',
            subtitle: 'Versi ${AppConstants.appVersion}',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tentang Aplikasi'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Kasir Digital'),
                      SizedBox(height: 8),
                      Text('Versi: ${AppConstants.appVersion}'),
                      SizedBox(height: 8),
                      Text(
                        'Aplikasi Sistem Point of Sales (POS) untuk memudahkan proses transaksi penjualan.',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        trailing:
            trailing ?? Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
