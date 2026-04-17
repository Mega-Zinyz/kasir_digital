// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../services/thermal_receipt_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/index.dart';

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

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _searchController = TextEditingController();
  final ThermalReceiptService _thermalReceiptService = ThermalReceiptService();
  late TextEditingController _paymentController;
  List<String> selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _paymentController = TextEditingController();
    // Schedule loading after build completes
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
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Penjualan')),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading produk...'),
                ],
              ),
            );
          }

          final products = productProvider.products;

          // Responsif layout
          final isMobile = MediaQuery.of(context).size.width < 800;

          if (isMobile) {
            // Mobile: Stacked layout
            return Column(
              children: [
                Expanded(child: _buildProductSection(products)),
                Divider(),
                Expanded(child: _buildCartSection()),
              ],
            );
          }

          // Desktop: Side by side layout
          return Row(
            children: [
              Expanded(flex: 2, child: _buildProductSection(products)),
              Expanded(flex: 1, child: _buildCartSection()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductSection(List<Product> products) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: Consumer<CategoryProvider>(
            builder: (context, categoryProvider, _) {
              final categories = categoryProvider.categories;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar with category filter integrated
                  // Search bar with category dropdown side by side
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (query) {
                            context.read<ProductProvider>().searchProducts(
                              query,
                            );
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari produk...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Category dropdown button
                      _buildCategoryDropdown(categories),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Show selected categories as chips below
                  if (selectedCategories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...selectedCategories.map((catName) {
                          return Chip(
                            label: Text(
                              catName,
                              style: TextStyle(fontSize: 12),
                            ),
                            onDeleted: () {
                              setState(() {
                                selectedCategories.remove(catName);
                              });
                            },
                            backgroundColor: isDark
                                ? cs.primaryContainer
                                : cs.primary.withValues(alpha: 0.10),
                            deleteIcon: Icon(Icons.close, size: 18),
                            deleteIconColor: cs.primary,
                          );
                        }),
                        // Clear all button
                        if (selectedCategories.isNotEmpty)
                          ActionChip(
                            label: Text(
                              'Hapus Semua',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedCategories.clear();
                              });
                            },
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
        Expanded(child: _buildFilteredProducts(products)),
      ],
    );
  }

  Widget _buildFilteredProducts(List<Product> allProducts) {
    // Filter products by selected categories
    final filteredProducts = selectedCategories.isEmpty
        ? allProducts
        : allProducts.where((product) {
            return selectedCategories.any(
              (category) => product.categories.contains(category),
            );
          }).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              selectedCategories.isEmpty
                  ? 'Tidak ada produk'
                  : 'Tidak ada produk di kategori terpilih',
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return ProductCard(product: product);
      },
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        _showCategoryDropdown(categories);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 20, color: cs.onSurfaceVariant),
            SizedBox(width: 8),
            Text(
              selectedCategories.isEmpty
                  ? 'Kategori'
                  : '${selectedCategories.length} dipilih',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showCategoryDropdown(List<Category> categories) {
    String searchQuery = '';
    List<String> tempSelected = List.from(selectedCategories);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari kategori...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
                SizedBox(height: 16),
                // Category list
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 300, minWidth: 250),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "Semua" option
                        CheckboxListTile(
                          title: Text(
                            'Semua',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: tempSelected.isEmpty,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setDialogState(() {
                              tempSelected.clear();
                            });
                          },
                        ),
                        // Filtered category checkboxes
                        ...categories
                            .where(
                              (cat) =>
                                  cat.name.toLowerCase().contains(searchQuery),
                            )
                            .map((cat) {
                              final isSelected = tempSelected.contains(
                                cat.name,
                              );
                              return CheckboxListTile(
                                title: Text(
                                  cat.name,
                                  style: TextStyle(fontSize: 13),
                                ),
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
                SizedBox(height: 16),
                // Action buttons
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
                          selectedCategories = tempSelected;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'Terapkan',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
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

  Widget _buildCartSection() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // Cart header
          Container(
            padding: EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Keranjang Belanja',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, _) {
                    return Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _showAddCustomItemDialog(context),
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.75),
                            size: 18,
                          ),
                          label: Text(
                            'Custom',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${cartProvider.itemCount} item',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Cart items - EXPANDED with larger size
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                if (cartProvider.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Keranjang kosong',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return CartItemWidget(
                      cartItem: item,
                      onQuantityChanged: (qty) {
                        cartProvider.updateItemQuantity(item.id, qty);
                      },
                      onRemove: () {
                        cartProvider.removeFromCart(item.id);
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Payment input and total - FIXED at bottom
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      final payment =
                          double.tryParse(
                            _paymentController.text.replaceAll('.', ''),
                          ) ??
                          0;
                      final change = payment - cartProvider.totalAmount;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Total Amount
                          Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Harga',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  CurrencyFormatter.format(
                                    cartProvider.totalAmount,
                                  ),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14),

                          // Payment Input
                          TextField(
                            controller: _paymentController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _CurrencyInputFormatter(),
                            ],
                            onChanged: (value) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              labelText: 'Uang Pelanggan',
                              labelStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              hintText: 'Input jumlah pembayaran',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              prefixText: 'Rp ',
                              prefixStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),

                          // Change Amount
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: change >= 0
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer
                                        : Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withValues(alpha: 0.10))
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.errorContainer
                                        : Theme.of(context).colorScheme.error
                                              .withValues(alpha: 0.08)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: change >= 0
                                    ? Theme.of(context).colorScheme.secondary
                                          .withValues(alpha: 0.5)
                                    : Theme.of(context).colorScheme.error
                                          .withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kembalian:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(
                                    change >= 0 ? change : 0,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: change >= 0
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                        : Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14),

                          // Checkout Button
                          PrimaryButton(
                            label: 'Proses Pembayaran',
                            onPressed:
                                cartProvider.items.isEmpty ||
                                    payment < cartProvider.totalAmount
                                ? null
                                : () => _showPaymentConfirmationDialog(
                                    context,
                                    cartProvider.totalAmount,
                                    payment,
                                    'cash',
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmationDialog(
    BuildContext context,
    double totalAmount,
    double paymentAmount,
    String paymentMethod,
  ) {
    final change = paymentAmount - totalAmount;
    final printer = context.read<HardwareProvider>().printer;
    final printerConnected = printer?.connected == true;
    final settingsProvider = context.read<SettingsProvider>();
    final cartProvider = context.read<CartProvider>();
    bool shouldPrintReceipt = true;

    void openReceiptPreview() {
      final previewTransactionId = const Uuid().v4();
      final previewItems = cartProvider.toTransactionItems(
        previewTransactionId,
      );
      final previewTransaction = SalesTransaction(
        id: previewTransactionId,
        transactionDate: DateTime.now(),
        totalAmount: totalAmount,
        paymentAmount: paymentAmount,
        changeAmount: change,
        paymentMethod: paymentMethod,
        status: 'preview',
        createdAt: DateTime.now(),
        items: previewItems,
      );

      _showReceiptPreviewDialog(
        context,
        receiptContent: _thermalReceiptService.buildReceiptPreview(
          storeProfile: settingsProvider.storeProfile,
          transaction: previewTransaction,
          items: previewItems,
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.shopping_cart_checkout_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Konfirmasi Pembayaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 24),

                // Payment Details
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surfaceContainerLow
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildPaymentDetailRow(
                        'Total Harga:',
                        CurrencyFormatter.format(totalAmount),
                        Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 12),
                      Divider(height: 1),
                      SizedBox(height: 12),
                      _buildPaymentDetailRow(
                        'Uang Pelanggan:',
                        CurrencyFormatter.format(paymentAmount),
                        Theme.of(context).colorScheme.tertiary,
                      ),
                      SizedBox(height: 12),
                      Divider(height: 1),
                      SizedBox(height: 12),
                      _buildPaymentDetailRow(
                        'Kembalian:',
                        CurrencyFormatter.format(change),
                        change >= 0
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.surfaceContainerLow
                                : Theme.of(context).colorScheme.surface,
                          ),
                          child: CheckboxListTile(
                            value: shouldPrintReceipt,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setDialogState(() {
                                shouldPrintReceipt = value ?? false;
                              });
                            },
                            title: Text(
                              printerConnected
                                  ? 'Cetak struk otomatis'
                                  : 'Cetak struk',
                            ),
                            subtitle: Text(
                              printerConnected
                                  ? 'Printer: ${printer?.name ?? 'Thermal Printer'}'
                                  : 'Printer belum terhubung. Gunakan tombol Preview Struk.',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Tooltip(
                          message: 'Preview struk',
                          child: OutlinedButton.icon(
                            onPressed: openReceiptPreview,
                            icon: const Icon(Icons.receipt_long_rounded, size: 22),
                            label: const Text('Preview'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.35),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

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
                        label: 'Lanjutkan',
                        onPressed: () {
                          Navigator.pop(context);
                          _processPayment(
                            context,
                            paymentMethod,
                            shouldPrintReceipt: shouldPrintReceipt,
                          );
                        },
                      ),
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

  Widget _buildPaymentDetailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _showReceiptPreviewDialog(
    BuildContext context, {
    required String receiptContent,
  }) {
    final cs = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview Struk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            'Tampilan isi struk sebelum atau sesudah dicetak.',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 292,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.7),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SelectableText(
                            receiptContent.trimRight(),
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.65,
                              color: cs.onSurface,
                              fontFamily: Platform.isWindows
                                  ? 'Consolas'
                                  : 'monospace',
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: PrimaryButton(
                    label: 'Tutup',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _processPayment(
    BuildContext context,
    String paymentMethod, {
    bool shouldPrintReceipt = true,
  }) async {
    final cartProvider = context.read<CartProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final hardwareProvider = context.read<HardwareProvider>();
    final printerConnected = hardwareProvider.printer?.connected == true;
    final payment =
        double.tryParse(_paymentController.text.replaceAll('.', '')) ?? 0;

    if (payment >= cartProvider.totalAmount) {
      try {
        // Create transaction ID first (will be used for both transaction and items)
        final transactionId = const Uuid().v4();

        // Save transaction to database
        final transactionItems = cartProvider.toTransactionItems(transactionId);
        final completedTransaction = SalesTransaction(
          id: transactionId,
          transactionDate: DateTime.now(),
          totalAmount: cartProvider.totalAmount,
          paymentAmount: payment,
          changeAmount: payment - cartProvider.totalAmount,
          paymentMethod: paymentMethod,
          status: 'completed',
          createdAt: DateTime.now(),
          items: transactionItems,
        );

        await context.read<TransactionProvider>().addTransaction(
          transactionId: transactionId,
          totalAmount: cartProvider.totalAmount,
          paymentAmount: payment,
          paymentMethod: paymentMethod,
          items: transactionItems,
        );

        if (context.mounted) {
          // Decrease stock for each item in cart
          final productProvider = context.read<ProductProvider>();
          for (var item in cartProvider.items) {
            await productProvider.decreaseStock(item.product.id, item.quantity);
          }
        }

        ThermalPrintResult? printResult;
        if (shouldPrintReceipt) {
          if (printerConnected) {
            printResult = await _thermalReceiptService.printPaymentReceipt(
              storeProfile: settingsProvider.storeProfile,
              transaction: completedTransaction,
              items: transactionItems,
              printerName: hardwareProvider.printer?.name,
            );
          } else {
            printResult = const ThermalPrintResult(
              success: false,
              message:
                  'Printer belum terhubung. Gunakan tombol preview untuk melihat struk.',
            );
          }
        }

        // Clear cart and reset payment input
        cartProvider.clearCart();
        _paymentController.clear();

        if (context.mounted) {
          // Clear previous snackbars to prevent lag
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                printResult == null
                    ? 'Transaksi berhasil diproses tanpa cetak struk'
                    : printResult.success
                    ? 'Transaksi berhasil diproses dan struk dicetak'
                    : 'Transaksi berhasil diproses. ${printResult.message}',
              ),
                backgroundColor: printResult == null
                  ? Theme.of(context).colorScheme.primary
                  : printResult.success
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.tertiary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          // Clear previous snackbars to prevent lag
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        // Clear previous snackbars to prevent lag
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran kurang'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showAddCustomItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Tambah Item Custom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Item',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Harga (Rp)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1
                        ? () => setDialogState(() => quantity--)
                        : null,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$quantity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () => setDialogState(() => quantity++),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price =
                    double.tryParse(priceController.text.replaceAll('.', '')) ??
                    0;
                if (name.isEmpty || price <= 0) return;
                final customProduct = Product(
                  id: const Uuid().v4(),
                  name: name,
                  code: 'CUSTOM',
                  costPrice: 0,
                  profitMargin: 0,
                  price: price,
                  stock: 999,
                  createdAt: DateTime.now(),
                );
                context.read<CartProvider>().addToCart(customProduct, quantity);
                Navigator.pop(context);
              },
              child: Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isProcessing = false;

  Future<void> _handleAddToCart() async {
    // Prevent multiple taps while processing
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (widget.product.stock > 0) {
        // addToCart now returns true if new item, false if quantity updated
        final isNewItem = context.read<CartProvider>().addToCart(
          widget.product,
          1,
        );

        if (mounted) {
          // Clear previous snackbars to prevent lag
          ScaffoldMessenger.of(context).clearSnackBars();

          if (isNewItem) {
            // New item added to cart
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${widget.product.name} ditambahkan ke keranjang',
                ),
                duration: Duration(milliseconds: 800),
              ),
            );
          } else {
            // Item quantity increased
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Jumlah ${widget.product.name} ditambah (+1)'),
                duration: Duration(milliseconds: 800),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          // Clear previous snackbars to prevent lag
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stok tidak tersedia'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      // Reset flag after debounce delay (500ms)
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildExpiryDateBadge(DateTime? expiryDate) {
    if (expiryDate == null) return SizedBox.shrink();

    final now = DateTime.now();
    final expiryOnly = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    final todayOnly = DateTime(now.year, now.month, now.day);
    final daysUntilExpiry = expiryOnly.difference(todayOnly).inDays;
    final isExpired = daysUntilExpiry < 0;
    final isWarning = daysUntilExpiry >= 0 && daysUntilExpiry <= 7;

    final indicatorColor = isExpired
        ? Theme.of(context).colorScheme.error
        : isWarning
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.secondary;

    String displayText;
    if (isExpired) {
      displayText = 'Expired';
    } else if (isWarning) {
      displayText = 'Exp: $daysUntilExpiry h';
    } else {
      final year = expiryDate.year.toString().substring(
        2,
      ); // 2 digit year (25 instead of 2025)
      displayText = 'Exp: ${expiryDate.day}/${expiryDate.month}/$year';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: indicatorColor, width: 1),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: indicatorColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get text sizes based on card size
    const nameSize = 14.0;
    const codeSize = 11.0;
    const priceSize = 15.0;
    const stockSize = 11.0;
    const imageAspectRatio = 0.95;
    const padding = 5.0;

    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final cs = Theme.of(context).colorScheme;
        final isLowStock =
            widget.product.stock < settingsProvider.lowStockThreshold;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: _isProcessing ? null : _handleAddToCart,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed aspect ratio image container
                    AspectRatio(
                      aspectRatio: imageAspectRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child:
                            widget.product.imagePath != null &&
                                widget.product.imagePath!.isNotEmpty &&
                                File(widget.product.imagePath!).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Image.file(
                                  File(widget.product.imagePath!),
                                  fit: BoxFit.cover,
                                  cacheWidth: 400,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.inventory_2,
                                        color: cs.primary,
                                        size: 35,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.inventory_2,
                                  color: cs.primary,
                                  size: 35,
                                ),
                              ),
                      ),
                    ),
                    // Product info
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: nameSize,
                                color: cs.onSurface,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              widget.product.code,
                              style: TextStyle(
                                fontSize: codeSize,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 1),
                            Spacer(),
                            Text(
                              CurrencyFormatter.format(widget.product.price),
                              style: TextStyle(
                                color: cs.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: priceSize,
                              ),
                            ),
                            Text(
                              'Stok: ${widget.product.stock}',
                              style: TextStyle(
                                fontSize: stockSize,
                                color: isLowStock
                                    ? cs.error
                                    : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.product.expiryDate != null) ...[
                              SizedBox(height: 2),
                              _buildExpiryDateBadge(widget.product.expiryDate),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Low stock badge
                if (isLowStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Low Stock',
                        style: TextStyle(
                          color: cs.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CartItemWidget extends StatefulWidget {
  final CartItem cartItem;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.cartItem.quantity;
  }

  @override
  void didUpdateWidget(CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local quantity with updated cartItem from provider
    if (oldWidget.cartItem.quantity != widget.cartItem.quantity) {
      setState(() {
        quantity = widget.cartItem.quantity;
      });
    }
  }

  void _showQuantityInputDialog(BuildContext context) {
    final inputController = TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Input Jumlah'),
        content: TextField(
          controller: inputController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Masukkan jumlah',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(inputController.text);
              if (newQuantity != null && newQuantity > 0) {
                setState(() {
                  quantity = newQuantity;
                });
                widget.onQuantityChanged(quantity);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Jumlah harus angka positif'),
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
              foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
            ),
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name and delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cartItem.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Harga: ${CurrencyFormatter.format(widget.cartItem.product.price)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(Icons.delete_outline, size: 26, color: cs.error),
                  padding: EdgeInsets.all(8),
                  tooltip: 'Hapus item',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Quantity and Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? cs.primaryContainer
                      : cs.primary.withValues(alpha: 0.08),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: quantity > 1
                          ? () {
                              setState(() => quantity--);
                              widget.onQuantityChanged(quantity);
                            }
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 22,
                          color: quantity > 1
                              ? cs.primary
                              : cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showQuantityInputDialog(context),
                      child: Container(
                        width: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: cs.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            right: BorderSide(
                              color: cs.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          quantity.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => quantity++);
                        widget.onQuantityChanged(quantity);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Icon(Icons.add, size: 22, color: cs.primary),
                      ),
                    ),
                  ],
                ),
              ),

              // Subtotal
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? cs.secondaryContainer
                      : cs.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.secondary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(widget.cartItem.subtotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: cs.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
