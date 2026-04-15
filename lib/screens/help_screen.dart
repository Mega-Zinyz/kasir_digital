import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Section
          _buildSectionHeader(context, 'Pertanyaan yang Sering Diajukan'),
          _buildFAQItem(
            context,
            'Bagaimana cara menambah produk?',
            'Untuk menambah produk, pergi ke menu "Daftar Produk" di sidebar kiri. Klik tombol "Tambah Produk" dan isi informasi produk seperti nama, harga, dan stok. Kemudian simpan.',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara melakukan transaksi penjualan?',
            'Buka menu "Penjualan" di sidebar. Pilih produk yang ingin dijual dari daftar, masukkan jumlah, dan klik "Tambah ke Keranjang". Setelah selesai, klik "Selesaikan Transaksi" untuk menyelesaikan penjualan.',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara melihat riwayat transaksi?',
            'Buka menu "Riwayat" di sidebar untuk melihat semua transaksi yang telah dilakukan. Anda dapat melihat detail transaksi seperti tanggal, waktu, produk, dan total harga.',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara membuat backup data?',
            'Buka menu "Backup" di sidebar. Pilih "Backup Manual" untuk membuat backup sekarang, atau atur jadwal backup otomatis dengan memilih "Setiap Hari" atau "Setiap Minggu".',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara mengexport laporan?',
            'Buka menu "Laporan" di sidebar. Pilih format export (PDF atau Excel) dan tentukan folder tujuan. Data akan diexport beserta tanggal dan nama file secara otomatis.',
          ),
          _buildFAQItem(
            context,
            'Di mana gambar produk disimpan?',
            'Gambar produk disimpan secara otomatis di folder aplikasi (/assets/images/). Tidak perlu khawatir gambar hilang karena sudah aman di dalam folder aplikasi dan termasuk dalam backup otomatis.',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara mengganti gambar produk?',
            'Buka menu "Daftar Produk", klik pada produk yang ingin diedit, pilih "Edit Produk", kemudian klik area gambar untuk mengganti. Gambar lama otomatis akan dihapus dan gambar baru akan disimpan.',
          ),
          _buildFAQItem(
            context,
            'Apakah gambar produk ikut dalam backup?',
            'Ya, semua gambar produk otomatis termasuk dalam backup karena disimpan di folder aplikasi (/assets/images/) yang merupakan bagian dari data aplikasi.',
          ),
          _buildFAQItem(
            context,
            'Folder backup ada di mana setelah install?',
            'Folder Backup dan Laporan otomatis dibuat di folder instalasi aplikasi (biasanya: C:\\Program Files\\Kasir Digital\\). Folder sudah siap digunakan untuk backup otomatis.',
          ),

          const SizedBox(height: 24),

          // How to Use Section
          _buildSectionHeader(context, 'Cara Penggunaan Sistem'),
          _buildUsageItem(
            context,
            '1. Dashboard',
            'Halaman utama yang menampilkan ringkasan penjualan hari ini, analisis grafik, statistik produk, dan status perangkat yang terhubung.',
          ),
          _buildUsageItem(
            context,
            '2. Daftar Produk',
            'Kelola inventaris produk Anda. Tambah, edit, atau hapus produk. Pantau stok dan batas stok minimal untuk setiap produk.',
          ),
          _buildUsageItem(
            context,
            '3. Penjualan',
            'Proses transaksi penjualan. Cari produk, tentukan jumlah, dan selesaikan transaksi. Sistem otomatis mengurangi stok produk.',
          ),
          _buildUsageItem(
            context,
            '4. Riwayat',
            'Lihat semua transaksi yang telah dilakukan. Filter berdasarkan tanggal dan lihat detail setiap transaksi.',
          ),
          _buildUsageItem(
            context,
            '5. Analisis',
            'Lihat grafik penjualan, analisis tren, dan statistik performa produk untuk membantu pengambilan keputusan bisnis.',
          ),
          _buildUsageItem(
            context,
            '6. Pengaturan',
            'Atur profil toko, folder export, batas stok minimal, jadwal backup, dan lihat perangkat yang terhubung.',
          ),

          const SizedBox(height: 24),

          // Feature Documentation Section
          _buildSectionHeader(context, 'Dokumentasi Fitur'),
          _buildFeatureDocumentation(
            context,
            'Penyimpanan Gambar Produk',
            'Gambar produk disimpan secara otomatis di dalam folder aplikasi (/assets/images/). Ketika Anda menambah produk dengan gambar, sistem akan membuat copy gambar ke folder tersebut sehingga aman dan tidak akan hilang meskipun file asli di folder eksternal dihapus.',
            [
              '✓ Gambar disimpan lokal di dalam aplikasi',
              '✓ Tidak bergantung pada folder eksternal',
              '✓ Gambar ikut serta saat backup',
              '✓ Edit gambar otomatis menghapus gambar lama',
              '✓ Hapus produk otomatis menghapus gambar terkait',
            ],
          ),
          _buildFeatureDocumentation(
            context,
            'Edit Produk Lengkap',
            'Fitur edit produk memungkinkan Anda mengubah semua detail produk termasuk nama, kode, harga, kategori, barcode, dan gambar. Ketika mengganti gambar, sistem otomatis menghapus gambar lama dan menyimpan gambar baru.',
            [
              '✓ Edit nama, kode, harga, kategori, barcode',
              '✓ Ganti gambar dengan preview gambar lama',
              '✓ Gambar lama otomatis dihapus saat diganti',
              '✓ Simpan hanya field yang ingin diubah',
              '✓ Validasi form untuk data yang wajib diisi',
            ],
          ),
          _buildFeatureDocumentation(
            context,
            'Backup & Laporan',
            'Sistem backup otomatis menciptakan folder Backup dan Laporan saat instalasi. Backup otomatis dapat dijadwalkan harian atau mingguan untuk melindungi data bisnis Anda.',
            [
              '✓ Folder Backup dibuat otomatis saat install',
              '✓ Folder Laporan dibuat otomatis saat install',
              '✓ Backup otomatis harian atau mingguan',
              '✓ Manual backup kapan saja dari menu Backup',
              '✓ Export laporan ke Excel atau PDF',
              '✓ Gambar produk terinclude dalam backup',
            ],
          ),

          const SizedBox(height: 24),

          // Tips Section
          _buildSectionHeader(context, 'Tips Penggunaan'),
          _buildTipItem(
            context,
            'Atur batas stok minimal agar sistem memberikan notifikasi ketika stok produk menipis.',
          ),
          _buildTipItem(
            context,
            'Aktifkan backup otomatis untuk melindungi data bisnis Anda dari kehilangan data yang tidak terduga.',
          ),
          _buildTipItem(
            context,
            'Gunakan menu Analisis secara berkala untuk memantau performa penjualan dan membuat keputusan bisnis yang lebih baik.',
          ),
          _buildTipItem(
            context,
            'Edit profil toko Anda di Pengaturan untuk mencerminkan informasi bisnis yang akurat.',
          ),
          _buildTipItem(
            context,
            'Pastikan semua perangkat (scanner, printer, laci kasir) terhubung dengan baik melalui menu Pengaturan > Perangkat Terhubung.',
          ),
          _buildTipItem(
            context,
            'Gambar produk secara otomatis disimpan di folder aplikasi. Tidak perlu khawatir gambar hilang karena sudah ter-manage sistem.',
          ),
          _buildTipItem(
            context,
            'Saat mengganti gambar produk, gambar lama otomatis dihapus untuk menghemat disk space.',
          ),
          _buildTipItem(
            context,
            'Folder Backup dan Laporan sudah otomatis dibuat saat instalasi. Pastikan user account memiliki akses untuk menulis di folder tersebut.',
          ),
          _buildTipItem(
            context,
            'Backup otomatis akan berjalan sesuai jadwal (harian/mingguan) selama aplikasi berjalan. Aktifkan di menu Pengaturan > Backup.',
          ),

          const SizedBox(height: 24),

          // Contact Support
          _buildSectionHeader(context, 'Hubungi Kami'),
          Card(
            elevation: 0,
            color: isDark ? null : cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jika Anda mengalami masalah atau memiliki pertanyaan, silakan hubungi customer support kami:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.email, color: cs.primary),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('support@kasirdigital.com')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.phone, color: cs.primary),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('+62 XXX-XXXX-XXXX')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: cs.primary,
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? null : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(
    BuildContext context,
    String title,
    String description,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: isDark ? null : cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureDocumentation(
    BuildContext context,
    String title,
    String description,
    List<String> features,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? null : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        leading: Icon(Icons.info_outline, color: cs.primary, size: 20),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.substring(0, 1),
                          style: TextStyle(
                            color: cs.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String tip) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? cs.primaryContainer
                  : cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: isDark ? cs.onPrimaryContainer : cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
