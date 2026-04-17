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
            'Untuk menambah produk, buka menu "Daftar Barang" di sidebar kiri. Klik tombol tambah produk lalu isi informasi seperti nama, harga, stok, dan kategori sebelum menyimpan.',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara melakukan transaksi penjualan?',
            'Buka menu "Penjualan" di sidebar. Pilih produk yang ingin dijual dari daftar, masukkan jumlah, dan klik "Tambah ke Keranjang". Setelah selesai, klik "Selesaikan Transaksi" untuk menyelesaikan penjualan.',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara melihat riwayat transaksi?',
            'Buka menu "History" di sidebar untuk melihat semua transaksi yang telah dilakukan. Di halaman ini Anda juga bisa membuka detail transaksi dan export laporan sesuai periode yang dipilih.',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara membuat backup data?',
            'Buka menu "Backup" di sidebar. Gunakan tombol export backup untuk membuat backup sekarang, atau atur jadwal backup otomatis dengan memilih "Setiap Hari" atau "Setiap Minggu".',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara mengexport laporan?',
            'Buka menu "History" di sidebar. Pilih export PDF atau Excel, lalu file laporan akan disimpan ke folder laporan default atau lokasi yang sudah Anda atur di Pengaturan.',
          ),
          _buildFAQItem(
            context,
            'Di mana gambar produk disimpan?',
            'Gambar produk disimpan secara otomatis di folder aplikasi pada subfolder assets/images. Sistem membuat salinan gambar ke folder ini agar file tetap aman meskipun file asli dari folder lain sudah dipindah atau dihapus.',
          ),
          _buildFAQItem(
            context,
            'Bagaimana cara mengganti gambar produk?',
            'Buka menu "Daftar Barang", pilih produk yang ingin diedit, lalu klik area gambar untuk mengganti file. Gambar lama otomatis akan dihapus dan gambar baru akan disimpan oleh sistem.',
          ),
          _buildFAQItem(
            context,
            'Apakah gambar produk ikut dalam backup?',
            'Ya. Backup aplikasi menyimpan data produk, transaksi, item transaksi, dan salinan gambar produk yang dikelola aplikasi sehingga gambar bisa dipulihkan saat restore.',
          ),
          _buildFAQItem(
            context,
            'Folder backup ada di mana setelah install?',
            'Secara default folder Backup dan Laporan dibuat di folder aplikasi, biasanya di C:\\Users\\<username>\\AppData\\Local\\Kasir Digital\\. Lokasi backup dan laporan ini juga bisa diubah dari menu Pengaturan.',
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
            '2. Daftar Barang',
            'Kelola inventaris produk Anda. Tambah, edit, atau hapus produk. Pantau stok dan batas stok minimal untuk setiap produk.',
          ),
          _buildUsageItem(
            context,
            '3. Penjualan',
            'Proses transaksi penjualan. Cari produk, tentukan jumlah, dan selesaikan transaksi. Sistem otomatis mengurangi stok produk.',
          ),
          _buildUsageItem(
            context,
            '4. History',
            'Lihat semua transaksi yang telah dilakukan. Filter berdasarkan tanggal, lihat detail transaksi, dan export laporan penjualan.',
          ),
          _buildUsageItem(
            context,
            '5. Analitik',
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
            'Gambar produk disimpan secara otomatis di dalam folder aplikasi pada assets/images. Ketika Anda menambah produk dengan gambar, sistem membuat copy gambar ke folder tersebut sehingga referensi gambar tetap aman dan dapat dipulihkan kembali dari file backup.',
            [
              '✓ Gambar disimpan lokal di dalam aplikasi',
              '✓ Tidak bergantung pada folder eksternal',
              '✓ Gambar ikut tersimpan saat backup dan restore',
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
            'Sistem backup otomatis menciptakan folder Backup dan Laporan saat instalasi. Backup otomatis dapat dijadwalkan harian atau mingguan, dan file backup akan menyimpan data utama beserta gambar produk yang dikelola aplikasi.',
            [
              '✓ Folder Backup dibuat otomatis saat install',
              '✓ Folder Laporan dibuat otomatis saat install',
              '✓ Backup otomatis harian atau mingguan',
              '✓ Manual backup kapan saja dari menu Backup',
              '✓ Export laporan ke Excel atau PDF',
              '✓ Gambar produk ikut tersimpan dalam backup',
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
            'Gunakan menu Analitik secara berkala untuk memantau performa penjualan dan membuat keputusan bisnis yang lebih baik.',
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
