import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../providers/settings_provider.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner peringatan jika backup otomatis tidak aktif
          Consumer<SettingsProvider>(
            builder: (ctx, settings, _) {
              if (settings.backupFrequency != 'none') {
                return const SizedBox.shrink();
              }
              final cs = Theme.of(ctx).colorScheme;
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? cs.errorContainer
                      : cs.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.error.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.backup_outlined, color: cs.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup Otomatis Tidak Aktif',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? cs.onErrorContainer
                                  : cs.onSurface,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Aktifkan backup otomatis di bawah untuk melindungi data Anda.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? cs.onErrorContainer
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Backup Section
          const BackupSectionHeader(title: 'Cadangan Data'),
          const SizedBox(height: 12),
          Text(
            'Buat cadangan data aplikasi Anda. Backup mencakup database utama dan gambar produk yang dikelola aplikasi.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handleExportBackup,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? cs.secondaryContainer
                        : cs.secondary,
                    foregroundColor: isDark
                        ? cs.onSecondaryContainer
                        : cs.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<SettingsProvider>(
                builder: (ctx, settings, _) {
                  final backupPath = settings.getBackupPath();
                  return Tooltip(
                    message: backupPath.isEmpty
                        ? 'Atur lokasi backup di Settings terlebih dahulu'
                        : 'Buka Folder Backup',
                    child: ElevatedButton(
                      onPressed: backupPath.isNotEmpty
                          ? () => _openFolder(backupPath)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? cs.primaryContainer
                            : cs.primary.withValues(alpha: 0.08),
                        foregroundColor: isDark
                            ? cs.onPrimaryContainer
                            : cs.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                      ),
                      child: const Icon(Icons.folder_open),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Restore Section
          const BackupSectionHeader(title: 'Pulihkan Data'),
          const SizedBox(height: 12),
          Text(
            'Pulihkan database dari file backup yang telah dibuat sebelumnya.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _handleImportBackup,
            icon: const Icon(Icons.upload),
            label: const Text('Import Backup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? cs.tertiaryContainer : cs.tertiary,
              foregroundColor: isDark ? cs.onTertiaryContainer : cs.onTertiary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),

          // Automatic Backup Schedule Section
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              final cs = Theme.of(context).colorScheme;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackupSectionHeader(
                    title: 'Pengaturan Backup Otomatis',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Atur backup otomatis untuk melindungi data Anda secara berkala.',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Frequency Selection
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? null : cs.surface,
                      border: Border.all(color: cs.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // ignore: deprecated_member_use
                        RadioListTile<String>(
                          title: const Text('Tidak Ada (Manual)'),
                          value: 'none',
                          // ignore: deprecated_member_use
                          groupValue: settings.backupFrequency,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            if (value != null) {
                              context
                                  .read<SettingsProvider>()
                                  .setBackupFrequency(value);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        // ignore: deprecated_member_use
                        RadioListTile<String>(
                          title: const Text('Setiap Hari'),
                          subtitle: const Text(
                            'Backup dilakukan setiap 24 jam',
                          ),
                          value: 'daily',
                          // ignore: deprecated_member_use
                          groupValue: settings.backupFrequency,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            if (value != null) {
                              context
                                  .read<SettingsProvider>()
                                  .setBackupFrequency(value);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        // ignore: deprecated_member_use
                        RadioListTile<String>(
                          title: const Text('Setiap Minggu'),
                          subtitle: const Text(
                            'Backup dilakukan setiap 7 hari',
                          ),
                          value: 'weekly',
                          // ignore: deprecated_member_use
                          groupValue: settings.backupFrequency,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            if (value != null) {
                              context
                                  .read<SettingsProvider>()
                                  .setBackupFrequency(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Last Backup Info
                  const SizedBox(height: 16),
                  if (settings.lastBackupTime != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.secondaryContainer
                            : cs.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: cs.secondary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: cs.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Backup Terakhir',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? cs.onSecondaryContainer
                                        : cs.onSurface,
                                  ),
                                ),
                                Text(
                                  _formatLastBackup(settings.lastBackupTime!),
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (settings.backupFrequency != 'none') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? cs.primaryContainer : cs.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: cs.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Backup otomatis akan segera dilakukan',
                              style: TextStyle(
                                color: isDark
                                    ? cs.onPrimaryContainer
                                    : cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
          Builder(
            builder: (context) {
              final cs = Theme.of(context).colorScheme;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.primaryContainer
                          : cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: cs.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Informasi Backup',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? cs.onPrimaryContainer
                                      : cs.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          context,
                          '📁 Format File',
                          'Format JSON yang mudah dibaca dan dapat diedit',
                          cs,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          context,
                          '⏰ Otomatis Timestamp',
                          'Setiap backup membawa timestamp untuk kemudahan identifikasi',
                          cs,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          context,
                          '💾 Lokasi Default',
                          'Folder "Backup" atau lokasi yang sudah diatur di Settings',
                          cs,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          context,
                          '🔄 Backup Penuh',
                          'Mencakup produk, riwayat transaksi, item transaksi, dan gambar produk yang dikelola aplikasi',
                          cs,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.tertiaryContainer
                          : cs.tertiary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cs.tertiary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: cs.tertiary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Lakukan backup secara berkala untuk mencegah kehilangan data yang tidak terduga.',
                            style: TextStyle(
                              color: isDark
                                  ? cs.onTertiaryContainer
                                  : cs.onSurface,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openFile(String filePath) {
    final winPath = filePath.replaceAll('/', '\\');
    Process.run('explorer.exe', ['/select,$winPath']);
  }

  void _openFolder(String folderPath) {
    final winPath = folderPath.replaceAll('/', '\\');
    Process.run('explorer.exe', [winPath]);
  }

  String _formatLastBackup(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return dateTime.toString().split('.')[0];
    }
  }

  Future<void> _handleExportBackup() async {
    setState(() => _isProcessing = true);
    final cs = Theme.of(context).colorScheme;

    try {
      final backupPath = context.read<SettingsProvider>().getBackupPath();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Membuat backup...')));

      final filePath = await _backupService.exportDatabase(
        defaultPath: backupPath.isNotEmpty ? backupPath : null,
      );

      if (mounted) {
        if (filePath != null) {
          // Update last backup time
          context.read<SettingsProvider>().setLastBackupTime(DateTime.now());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup berhasil dibuat'),
              backgroundColor: cs.secondary,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'Buka File',
                textColor: cs.onSecondary,
                onPressed: () => _openFile(filePath),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup dibatalkan'),
              backgroundColor: cs.tertiary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: cs.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleImportBackup() async {
    setState(() => _isProcessing = true);
    final cs = Theme.of(context).colorScheme;

    Map<String, dynamic>? backupData;

    try {
      backupData = await _backupService.validateBackupFile();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == '__cancelled__') return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $msg'), backgroundColor: cs.error),
      );
      return;
    } finally {
      if (backupData == null && mounted) {
        setState(() => _isProcessing = false);
      }
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Show confirmation dialog with the validated data captured
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: cs.tertiary),
        title: const Text('Konfirmasi Restore'),
        content: const Text(
          'File backup valid. Lanjutkan untuk mengembalikan data?\n\n'
          '⚠️ Semua data saat ini (produk & transaksi) akan diganti dengan data dari backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.tertiary,
              foregroundColor: cs.onTertiary,
            ),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await _backupService.restoreDatabase(backupData);
      if (mounted) {
        context.read<SettingsProvider>().setLastBackupTime(DateTime.now());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data berhasil dipulihkan dari backup'),
            backgroundColor: cs.secondary,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulihkan data: ${e.toString()}'),
            backgroundColor: cs.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildInfoItem(
    BuildContext context,
    String title,
    String description,
    ColorScheme cs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isDark ? cs.onPrimaryContainer : cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: (isDark ? cs.onPrimaryContainer : cs.onSurfaceVariant)
                .withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class BackupSectionHeader extends StatelessWidget {
  final String title;

  const BackupSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
