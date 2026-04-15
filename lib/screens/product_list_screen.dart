import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../utils/formatters.dart';
import '../../widgets/index.dart';
import 'settings_screen.dart';

// Custom input formatter untuk format currency dengan pemisah titik
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return TextEditingValue.empty;
    }

    // Format dengan separator titik setiap 3 digit
    final formatted = _formatWithSeparator(digits);

    // Update cursor position ke akhir text
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithSeparator(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;

    for (int i = 0; i < length; i++) {
      // Add separator setiap 3 digit dari belakang
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  List<String> _selectedCategoryFilter = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ProductProvider>().loadProducts();
        context.read<CategoryProvider>().loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Barang'),
      ),
      body: Column(
        children: [
          // Search bar + category dropdown
          Padding(
            padding: EdgeInsets.all(16),
            child: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, _) {
                final categories = categoryProvider.categories;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (query) {
                              setState(() => _currentPage = 1);
                              context.read<ProductProvider>().searchProducts(query);
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari barang...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showCategoryFilterDialog(categories),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedCategoryFilter.isEmpty
                                    ? cs.outline
                                    : cs.primary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: _selectedCategoryFilter.isEmpty
                                  ? Colors.transparent
                                  : (isDark
                                    ? cs.primaryContainer
                                    : cs.primary.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 20,
                                  color: _selectedCategoryFilter.isEmpty
                                      ? cs.onSurfaceVariant
                                      : cs.primary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _selectedCategoryFilter.isEmpty
                                      ? 'Kategori'
                                      : '${_selectedCategoryFilter.length} dipilih',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedCategoryFilter.isEmpty
                                        ? cs.onSurfaceVariant
                                        : cs.primary,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 20,
                                  color: _selectedCategoryFilter.isEmpty
                                      ? cs.onSurfaceVariant
                                      : cs.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedCategoryFilter.isNotEmpty) ...[  
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ..._selectedCategoryFilter.map((catName) => Chip(
                            label: Text(catName, style: TextStyle(fontSize: 11)),
                            onDeleted: () => setState(() {
                              _selectedCategoryFilter.remove(catName);
                              _currentPage = 1;
                            }),
                            backgroundColor: isDark
                                ? cs.primaryContainer
                                : cs.primary.withValues(alpha: 0.08),
                            deleteIcon: Icon(Icons.close, size: 16),
                            deleteIconColor: cs.primary,
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )),
                          ActionChip(
                            label: Text('Hapus Semua',
                                style: TextStyle(fontSize: 11, color: cs.error)),
                            onPressed: () => setState(() {
                              _selectedCategoryFilter.clear();
                              _currentPage = 1;
                            }),
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // Estimasi nilai stok
          Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              final products = productProvider.products;
              final totalModal = products.fold<double>(
                  0, (sum, p) => sum + p.costPrice * p.stock);
              final totalNilaiJual = products.fold<double>(
                  0, (sum, p) => sum + p.price * p.stock);
              final totalProfit = products.fold<double>(
                  0, (sum, p) => sum + p.profitMargin * p.stock);

              if (products.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? cs.primaryContainer
                      : cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimasi Nilai Stok (${products.length} produk)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _EstimasiTile(
                            label: 'Modal',
                            value: CurrencyFormatter.format(totalModal),
                            color: cs.tertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _EstimasiTile(
                            label: 'Nilai Jual',
                            value: CurrencyFormatter.format(totalNilaiJual),
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _EstimasiTile(
                            label: 'Est. Profit',
                            value: CurrencyFormatter.format(totalProfit),
                            color: cs.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Product list with pagination
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                if (productProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                final allProducts = _selectedCategoryFilter.isEmpty
                    ? productProvider.products
                    : productProvider.products
                        .where((p) => _selectedCategoryFilter.any(
                            (cat) => p.categories.contains(cat)))
                        .toList();

                if (allProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: cs.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada barang',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate pagination
                final totalPages = (allProducts.length / _itemsPerPage).ceil();
                final startIndex = (_currentPage - 1) * _itemsPerPage;
                final endIndex = (startIndex + _itemsPerPage).clamp(0, allProducts.length);
                final paginatedProducts = allProducts.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    // Products list
                    Expanded(
                      child: ListView.builder(
                        itemCount: paginatedProducts.length,
                        itemBuilder: (context, index) {
                          final product = paginatedProducts[index];
                          return ProductListItem(product: product);
                        },
                      ),
                    ),

                    // Pagination controls
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: cs.outlineVariant),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Halaman $_currentPage dari $totalPages',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Previous button
                              ElevatedButton.icon(
                                onPressed: _currentPage > 1
                                    ? () {
                                        setState(() => _currentPage--);
                                      }
                                    : null,
                                icon: Icon(Icons.arrow_back),
                                label: Text('Sebelumnya'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentPage > 1
                                      ? cs.primary
                                      : cs.surfaceContainerHighest,
                                  foregroundColor: _currentPage > 1
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(width: 12),
                              
                              // Page numbers
                              ...List.generate(
                                totalPages,
                                (index) {
                                  final pageNum = index + 1;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() => _currentPage = pageNum);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _currentPage == pageNum
                                            ? cs.primary
                                            : cs.surfaceContainerHighest,
                                        foregroundColor: _currentPage == pageNum
                                            ? cs.onPrimary
                                            : cs.onSurface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: Text(
                                        pageNum.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              SizedBox(width: 12),
                              
                              // Next button
                              ElevatedButton.icon(
                                onPressed: _currentPage < totalPages
                                    ? () {
                                        setState(() => _currentPage++);
                                      }
                                    : null,
                                icon: Icon(Icons.arrow_forward),
                                label: Text('Selanjutnya'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentPage < totalPages
                                      ? cs.primary
                                      : cs.surfaceContainerHighest,
                                  foregroundColor: _currentPage < totalPages
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Menampilkan $startIndex - $endIndex dari ${allProducts.length} barang',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: () {
          _showAddProductDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showCategoryFilterDialog(List<Category> categories) {
    String searchQuery = '';
    List<String> tempSelected = List.from(_selectedCategoryFilter);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter Kategori',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari kategori...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) =>
                      setDialogState(() => searchQuery = value.toLowerCase()),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 300, minWidth: 250),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          title: Text('Semua',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                          value: tempSelected.isEmpty,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (_) =>
                              setDialogState(() => tempSelected.clear()),
                        ),
                        ...categories
                            .where((cat) =>
                                cat.name.toLowerCase().contains(searchQuery))
                            .map((cat) {
                          final isSelected = tempSelected.contains(cat.name);
                          return CheckboxListTile(
                            title: Text(cat.name,
                                style: TextStyle(fontSize: 13)),
                            value: isSelected,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value ?? false) {
                                  if (!tempSelected.contains(cat.name)) {
                                    tempSelected.add(cat.name);
                                  }
                                } else {
                                  tempSelected.remove(cat.name);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategoryFilter = tempSelected;
                          _currentPage = 1;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: Text('Terapkan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String code = '';
    String barcode = '';
    double costPrice = 0;
    double profitMargin = 0;
    int stock = 0;
    List<String> selectedCategories = [];
    String? imagePath;
    DateTime? selectedExpiryDate;
    String unit = 'pcs';
    final barcodeController = TextEditingController();

    // Refresh devices saat dialog dibuka
    final hardwareProvider = context.read<HardwareProvider>();
    hardwareProvider.refreshDevices();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Barang',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Image picker - Fixed size 200x200
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                      );
                      if (pickedFile != null) {
                        setState(() {
                          imagePath = pickedFile.path;
                        });
                      }
                    },
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                        ),
                        child: imagePath == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined,
                                      size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  SizedBox(height: 8),
                                  Text('Pilih Gambar',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  SizedBox(height: 4),
                                  Text('(Akan disimpan di folder aplikasi)',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      )),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(imagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            imagePath = null;
                                          });
                                        },
                                        child: Icon(Icons.close,
                                            color: Theme.of(context).colorScheme.onError, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Nama Barang',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Tidak boleh kosong' : null,
                          onSaved: (value) => name = value ?? '',
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Kode Barang',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Tidak boleh kosong' : null,
                          onSaved: (value) => code = value ?? '',
                        ),
                        SizedBox(height: 12),
                        Consumer<HardwareProvider>(
                          builder: (context, hardwareProvider, _) {
                            final scannerConnected = hardwareProvider.devices
                                .where((d) => d.type == 'scanner')
                                .any((d) => d.connected);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Barcode field dengan suffix button
                                TextFormField(
                                  controller: barcodeController,
                                  decoration: InputDecoration(
                                    labelText: 'Barcode (Scanner)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    suffixIcon: Container(
                                      margin: EdgeInsets.all(4),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: scannerConnected
                                              ? () {
                                                  _scanBarcode(
                                                    context,
                                                    barcodeController,
                                                  );
                                                }
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: scannerConnected
                                                  ? Theme.of(context).colorScheme.primaryContainer
                                                  : Theme.of(context).colorScheme.tertiaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.qr_code_scanner,
                                              color: scannerConnected
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.tertiary,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    helperText: scannerConnected
                                        ? 'Tekan ikon scanner untuk scan otomatis'
                                        : '⚠ Scanner tidak terhubung. Periksa pengaturan perangkat.',
                                    helperMaxLines: 2,
                                  ),
                                  onChanged: (value) => barcode = value,
                                ),
                                
                                // Warning banner jika scanner tidak terhubung
                                if (!scannerConnected)
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.tertiaryContainer,
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Theme.of(context).colorScheme.tertiary,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Scanner tidak terhubung',
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Input barcode manual atau periksa pengaturan perangkat',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          InkWell(
                                            onTap: () {
                                              // Close dialog terlebih dahulu
                                              Navigator.pop(context);
                                              // Kemudian navigate ke Settings
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SettingsScreen(),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.tertiary,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Atur',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onTertiary,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Harga Asli (Rp)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _CurrencyInputFormatter(),
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Tidak boleh kosong';
                            }
                            if (double.tryParse(value!.replaceAll('.', '')) == null) {
                              return 'Format tidak valid';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              costPrice = double.tryParse(value?.replaceAll('.', '') ?? '0') ?? 0,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Margin Profit (Rp)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Input besaran profit dalam rupiah',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _CurrencyInputFormatter(),
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Tidak boleh kosong';
                            }
                            if (double.tryParse(value!.replaceAll('.', '')) == null) {
                              return 'Format tidak valid';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              profitMargin = double.tryParse(value?.replaceAll('.', '') ?? '0') ?? 0,
                        ),
                        SizedBox(height: 12),
                        // Kategori Multi-select dengan Dialog
                        Consumer<CategoryProvider>(
                          builder: (context, categoryProvider, _) {
                            final categories = categoryProvider.categories;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _showCategorySelectionDialog(
                                          context,
                                          categories,
                                          selectedCategories,
                                          (updated) {
                                            setState(() {
                                              selectedCategories = updated;
                                            });
                                          },
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.category, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  selectedCategories.isEmpty
                                                      ? 'Pilih Kategori...'
                                                      : selectedCategories.join(', '),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: selectedCategories.isEmpty
                                                        ? Theme.of(context).colorScheme.onSurfaceVariant
                                                        : Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Icon(Icons.expand_more, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Compact add button
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.all(8),
                                        constraints: BoxConstraints(minHeight: 48, minWidth: 48),
                                        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                                        onPressed: () => _showAddCategoryDialog(context),
                                        tooltip: 'Tambah Kategori Baru',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Stok (Jumlah)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Tidak boleh kosong';
                            }
                            if (int.tryParse(value!) == null) {
                              return 'Harus berupa angka bulat';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              stock = int.tryParse(value ?? '0') ?? 0,
                        ),
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedExpiryDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedExpiryDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedExpiryDate != null
                                      ? 'Exp: ${selectedExpiryDate!.day}/${selectedExpiryDate!.month}/${selectedExpiryDate!.year}'
                                      : 'Tanggal Kadaluarsa (Opsional)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedExpiryDate != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: unit,
                          decoration: InputDecoration(
                            labelText: 'Satuan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          items: ['pcs', 'kg', 'gram', 'liter', 'ml', 'lusin', 'pak', 'dus']
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => unit = value);
                          },
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: 'Batal',
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Tambah',
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    formKey.currentState!.save();
                                    barcode = barcodeController.text;
                                    final buildContext = context;
                                    try {
                                      await buildContext
                                          .read<ProductProvider>()
                                          .addProduct(
                                            name: name,
                                            code: code,
                                            barcode: barcode.isNotEmpty ? barcode : null,
                                            costPrice: costPrice,
                                            profitMargin: profitMargin,
                                            stock: stock,
                                            categories: selectedCategories.isNotEmpty ? selectedCategories : null,
                                            imagePath: imagePath,
                                            expiryDate: selectedExpiryDate,
                                            unit: unit,
                                          );
                                      if (buildContext.mounted) {
                                        Navigator.pop(buildContext);
                                        ScaffoldMessenger.of(buildContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Barang berhasil ditambahkan'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (buildContext.mounted) {
                                        // Check if error is duplicate code
                                        if (e.toString().contains('UNIQUE constraint failed') &&
                                            e.toString().contains('products.code')) {
                                          _showDuplicateCodeDialog(buildContext, code);
                                        } else {
                                          ScaffoldMessenger.of(buildContext)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}'),
                                              backgroundColor: Theme.of(buildContext).colorScheme.error,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDuplicateCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: 32,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Kode Sudah Digunakan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Kode produk "$code" sudah digunakan oleh produk lain.\n\nSilakan gunakan kode yang berbeda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Kembali',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scanBarcode(BuildContext context, TextEditingController controller) {
    // Simulasi scanning barcode
    // Dalam implementasi nyata, Anda dapat mengintegrasikan dengan hardware scanner
    // Untuk saat ini, kami menampilkan dialog untuk input manual
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tempel scanner ke letak pembacaan dan tekan tombol scan pada perangkat Anda.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Menunggu barcode...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    // Simulasi menerima data barcode setelah delay
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context);
        // Dalam implementasi nyata, barcode akan diterima dari hardware
        // Untuk demo, kita bisa menambahkan barcode contoh atau membiarkan user input manual
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scanner siap. Tuju barcode produk untuk mengambil data.',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showAddCategoryDialog(BuildContext context) {
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Kategori Baru'),
        content: TextField(
          controller: categoryController,
          decoration: InputDecoration(
            hintText: 'Nama kategori',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final categoryName = categoryController.text.trim();
              if (categoryName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Nama kategori tidak boleh kosong')),
                );
                return;
              }

              try {
                await context
                    .read<CategoryProvider>()
                    .addCategory(name: categoryName);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kategori berhasil ditambahkan'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showCategorySelectionDialog(
    BuildContext context,
    List<Category> categories,
    List<String> selectedCategories,
    Function(List<String>) onChanged,
  ) {
    List<String> tempSelected = List.from(selectedCategories);
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pilih Kategori'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search field
                TextField(
                  onChanged: (value) {
                    setDialogState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari kategori...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                SizedBox(height: 16),
                // Category checkboxes
                if (categories.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Tidak ada kategori. Tambah kategori terlebih dahulu.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  ...categories
                      .where((cat) => cat.name.toLowerCase().contains(searchQuery))
                      .map((cat) {
                    final isSelected = tempSelected.contains(cat.name);
                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value ?? false) {
                              if (!tempSelected.contains(cat.name)) {
                                tempSelected.add(cat.name);
                              }
                            } else {
                              tempSelected.remove(cat.name);
                            }
                          });
                        },
                      ),
                      title: Text(cat.name),
                      contentPadding: EdgeInsets.zero,
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                        onPressed: () async {
                          // Confirm delete
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Hapus Kategori'),
                              content: Text('Yakin ingin menghapus kategori "${cat.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(ctx).colorScheme.error,
                                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      await context.read<CategoryProvider>().deleteCategory(cat.id);
                                      setDialogState(() {});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Kategori berhasil dihapus'),
                                            backgroundColor: Theme.of(context).colorScheme.secondary,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: ${e.toString()}'),
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Hapus Kategori',
                      ),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                onChanged(tempSelected);
                Navigator.pop(context);
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimasiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _EstimasiTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ProductListItem extends StatefulWidget {
  final Product product;

  const ProductListItem({super.key, required this.product});

  @override
  State<ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<ProductListItem> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildProductImage(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary);
              },
            ),
          );
        }
      } catch (e) {
        // Error handling for file access
      }
    }
    return Builder(builder: (context) => Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary));
  }

  String _formatCurrency(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final isLowStock = widget.product.stock < settingsProvider.lowStockThreshold;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isLowStock
              ? Border.all(color: cs.error, width: 2)
              : null,
        ),
            child: Stack(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildProductImage(widget.product.imagePath),
                  ),
                  title: Text(
                    widget.product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Kode: ${widget.product.code}',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Stok: ${widget.product.stock} ${widget.product.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLowStock ? cs.error : cs.onSurfaceVariant,
                              )),
                          if (isLowStock) ...[  
                            SizedBox(width: 8),
                            Icon(Icons.warning, color: cs.error, size: 16),
                          ],
                        ],
                      ),
                      SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        children: [
                          Text(
                            'Modal: ${CurrencyFormatter.format(widget.product.costPrice)}',
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                          Text(
                            'Jual: ${CurrencyFormatter.format(widget.product.price)}',
                            style: TextStyle(fontSize: 11, color: cs.secondary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Profit: ${CurrencyFormatter.format(widget.product.profitMargin)}',
                            style: TextStyle(fontSize: 11, color: cs.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(widget.product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.secondary,
                    ),
                  ),
                  onTap: () => _showProductDetailsDialog(context),
                ),
                // Warning badge jika stok rendah
                if (isLowStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stok Rendah',
                        style: TextStyle(
                          color: cs.onError,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      ),
    );
  }

  void _showProductDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detail Barang',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(context);
                      },
                      child: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.onError, size: 20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              DetailRow(label: 'Nama', value: widget.product.name),
              DetailRow(label: 'Kode', value: widget.product.code),
              DetailRow(
                  label: 'Harga Asli',
                  value: CurrencyFormatter.format(widget.product.costPrice)),
              DetailRow(
                  label: 'Harga Jual',
                  value: CurrencyFormatter.format(widget.product.price)),
              DetailRow(
                  label: 'Profit/Unit',
                  value: CurrencyFormatter.format(widget.product.profitMargin)),
              DetailRow(label: 'Stok', value: '${widget.product.stock} ${widget.product.unit}'),
              if (widget.product.categories.isNotEmpty)
                DetailRow(label: 'Kategori', value: widget.product.categories.join(', ')),
              if (widget.product.expiryDate != null)
                DetailRow(
                  label: 'Tanggal Kadaluarsa',
                  value: '${widget.product.expiryDate!.day}/${widget.product.expiryDate!.month}/${widget.product.expiryDate!.year}',
                ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Edit Produk',
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditProductDialog(context);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Edit Stok',
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditStockDialog(context);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SecondaryButton(
                label: 'Tutup',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = widget.product.name;
    String code = widget.product.code;
    String? barcode = widget.product.barcode;
    double costPrice = widget.product.costPrice;
    double profitMargin = widget.product.profitMargin;
    List<String> selectedCategories = [...widget.product.categories];
    String? newImagePath;
    DateTime? selectedExpiryDate = widget.product.expiryDate;
    String unit = widget.product.unit;
    final barcodeController = TextEditingController(text: barcode ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Barang',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Image picker section
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                      );
                      if (pickedFile != null) {
                        setState(() {
                          newImagePath = pickedFile.path;
                        });
                      }
                    },
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                        ),
                        child: newImagePath == null
                            ? (widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(widget.product.imagePath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.image_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                SizedBox(height: 8),
                                                Text('Ubah Gambar', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      Container(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.edit, size: 32, color: Theme.of(context).colorScheme.onPrimary),
                                              SizedBox(height: 8),
                                              Text('Ubah Gambar', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      SizedBox(height: 8),
                                      Text('Pilih Gambar', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    ],
                                  ))
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(newImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            newImagePath = null;
                                          });
                                        },
                                        child: Icon(Icons.close, color: Theme.of(context).colorScheme.onError, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: name,
                          decoration: InputDecoration(
                            labelText: 'Nama Barang',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.shopping_bag),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Tidak boleh kosong';
                            }
                            return null;
                          },
                          onSaved: (value) => name = value ?? '',
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          initialValue: code,
                          decoration: InputDecoration(
                            labelText: 'Kode Barang',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Tidak boleh kosong';
                            }
                            return null;
                          },
                          onSaved: (value) => code = value ?? '',
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          initialValue: _formatCurrency(costPrice.toInt()),
                          decoration: InputDecoration(
                            labelText: 'Harga Asli (Rp)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _CurrencyInputFormatter(),
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Tidak boleh kosong';
                            }
                            if (double.tryParse(value!.replaceAll('.', '')) == null) {
                              return 'Harus berupa angka';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              costPrice = double.tryParse(value?.replaceAll('.', '') ?? '0') ?? 0,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          initialValue: _formatCurrency(profitMargin.toInt()),
                          decoration: InputDecoration(
                            labelText: 'Margin Profit (Rp)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.attach_money),
                            hintText: 'Input besaran profit dalam rupiah',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _CurrencyInputFormatter(),
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Tidak boleh kosong';
                            }
                            if (double.tryParse(value!.replaceAll('.', '')) == null) {
                              return 'Harus berupa angka';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              profitMargin = double.tryParse(value?.replaceAll('.', '') ?? '0') ?? 0,
                        ),
                        SizedBox(height: 12),
                        // Kategori Multi-select dengan Dialog
                        Consumer<CategoryProvider>(
                          builder: (context, categoryProvider, _) {
                            final categories = categoryProvider.categories;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _showCategorySelectionDialog(
                                          context,
                                          categories,
                                          selectedCategories,
                                          (updated) {
                                            setState(() {
                                              selectedCategories = updated;
                                            });
                                          },
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.category, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  selectedCategories.isEmpty
                                                      ? 'Pilih Kategori...'
                                                      : selectedCategories.join(', '),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: selectedCategories.isEmpty
                                                      ? Theme.of(context).colorScheme.onSurfaceVariant
                                                      : Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Icon(Icons.expand_more, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Compact add button
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.all(8),
                                        constraints: BoxConstraints(minHeight: 48, minWidth: 48),
                                        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                                        onPressed: () => _showAddCategoryDialog(context),
                                        tooltip: 'Tambah Kategori Baru',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Barcode (Opsional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.barcode_reader),
                          ),
                          onSaved: (value) =>
                              barcode = value?.isEmpty ?? true ? null : value,
                        ),
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedExpiryDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedExpiryDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedExpiryDate != null
                                      ? 'Exp: ${selectedExpiryDate!.day}/${selectedExpiryDate!.month}/${selectedExpiryDate!.year}'
                                      : 'Tanggal Kadaluarsa (Opsional)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedExpiryDate != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: unit,
                          decoration: InputDecoration(
                            labelText: 'Satuan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          items: ['pcs', 'kg', 'gram', 'liter', 'ml', 'lusin', 'pak', 'dus']
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => unit = value);
                          },
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: 'Batal',
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Simpan',
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    formKey.currentState!.save();
                                    final buildContext = context;
                                    try {
                                      await buildContext
                                          .read<ProductProvider>()
                                          .updateProduct(
                                            id: widget.product.id,
                                            name: name,
                                            code: code,
                                            barcode: barcode,
                                            costPrice: costPrice,
                                            profitMargin: profitMargin,
                                            stock: widget.product.stock,
                                            categories: selectedCategories.isNotEmpty ? selectedCategories : null,
                                            imagePath: newImagePath,
                                            oldImagePath: widget.product.imagePath,
                                            expiryDate: selectedExpiryDate,
                                            unit: unit,
                                          );
                                      if (buildContext.mounted) {
                                        Navigator.pop(buildContext);
                                        ScaffoldMessenger.of(buildContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Barang berhasil diperbarui'),
                                            backgroundColor: Theme.of(buildContext).colorScheme.secondary,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (buildContext.mounted) {
                                        ScaffoldMessenger.of(buildContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Error: ${e.toString()}'),
                                            backgroundColor: Theme.of(buildContext).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditStockDialog(BuildContext context) {
    int newStock = widget.product.stock;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Stok Barang',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.product.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 24),
              
              // Current stock display
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stok Saat Ini:',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${widget.product.stock}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              
              // Stock input
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            newStock = int.tryParse(value) ?? widget.product.stock;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Stok Baru',
                          hintText: '${widget.product.stock}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.layers),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Change preview
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: newStock > widget.product.stock
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.secondaryContainer
                                  : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08))
                              : newStock < widget.product.stock
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).colorScheme.errorContainer
                                      : Theme.of(context).colorScheme.error.withValues(alpha: 0.08))
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).colorScheme.surfaceContainerLow
                                      : Theme.of(context).colorScheme.surface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: newStock > widget.product.stock
                                ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4)
                                : newStock < widget.product.stock
                                    ? Theme.of(context).colorScheme.error.withValues(alpha: 0.4)
                                    : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              newStock > widget.product.stock ? 'Penambahan:' : newStock < widget.product.stock ? 'Pengurangan:' : 'Tidak ada perubahan',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: newStock > widget.product.stock
                                    ? Theme.of(context).colorScheme.secondary
                                    : newStock < widget.product.stock
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  newStock > widget.product.stock
                                      ? Icons.arrow_upward_rounded
                                      : newStock < widget.product.stock
                                          ? Icons.arrow_downward_rounded
                                          : Icons.remove,
                                  color: newStock > widget.product.stock
                                      ? Theme.of(context).colorScheme.secondary
                                      : newStock < widget.product.stock
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  newStock != widget.product.stock
                                      ? '${(newStock - widget.product.stock).abs()}'
                                      : '0',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: newStock > widget.product.stock
                                        ? Theme.of(context).colorScheme.secondary
                                        : newStock < widget.product.stock
                                            ? Theme.of(context).colorScheme.error
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Batal',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Simpan',
                      onPressed: () async {
                        if (newStock == widget.product.stock) {
                          Navigator.pop(context);
                          return;
                        }
                        Navigator.pop(context);
                        try {
                          await context.read<ProductProvider>().updateProduct(
                            id: widget.product.id,
                            name: widget.product.name,
                            code: widget.product.code,
                            barcode: widget.product.barcode,
                            costPrice: widget.product.costPrice,
                            profitMargin: widget.product.profitMargin,
                            stock: newStock,
                            categories: widget.product.categories,
                            imagePath: widget.product.imagePath,
                            oldImagePath: widget.product.imagePath,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Stok berhasil diubah'),
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Barang'),
        content: Text('Apakah Anda yakin ingin menghapus barang ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final buildContext = context;
              Navigator.pop(context);
              if (!buildContext.mounted) return;
              try {
                await buildContext.read<ProductProvider>().deleteProduct(widget.product.id);
                if (buildContext.mounted) {
                  ScaffoldMessenger.of(buildContext).showSnackBar(
                    SnackBar(content: Text('Barang berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (buildContext.mounted) {
                  ScaffoldMessenger.of(buildContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Theme.of(buildContext).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text('Hapus', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Kategori Baru'),
        content: TextField(
          controller: categoryController,
          decoration: InputDecoration(
            hintText: 'Nama kategori',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final categoryName = categoryController.text.trim();
              if (categoryName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Nama kategori tidak boleh kosong')),
                );
                return;
              }

              try {
                await context
                    .read<CategoryProvider>()
                    .addCategory(name: categoryName);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kategori berhasil ditambahkan'),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showCategorySelectionDialog(
    BuildContext context,
    List<Category> categories,
    List<String> selectedCategories,
    Function(List<String>) onChanged,
  ) {
    List<String> tempSelected = List.from(selectedCategories);
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pilih Kategori'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search field
                TextField(
                  onChanged: (value) {
                    setDialogState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari kategori...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                SizedBox(height: 16),
                // Category checkboxes
                if (categories.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Tidak ada kategori. Tambah kategori terlebih dahulu.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  ...categories
                      .where((cat) => cat.name.toLowerCase().contains(searchQuery))
                      .map((cat) {
                    final isSelected = tempSelected.contains(cat.name);
                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value ?? false) {
                              if (!tempSelected.contains(cat.name)) {
                                tempSelected.add(cat.name);
                              }
                            } else {
                              tempSelected.remove(cat.name);
                            }
                          });
                        },
                      ),
                      title: Text(cat.name),
                      contentPadding: EdgeInsets.zero,
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                        onPressed: () async {
                          // Confirm delete
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Hapus Kategori'),
                              content: Text('Yakin ingin menghapus kategori "${cat.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(ctx).colorScheme.error,
                                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      await context.read<CategoryProvider>().deleteCategory(cat.id);
                                      setDialogState(() {});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Kategori berhasil dihapus'),
                                            backgroundColor: Theme.of(context).colorScheme.secondary,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: ${e.toString()}'),
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Hapus Kategori',
                      ),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                onChanged(tempSelected);
                Navigator.pop(context);
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
