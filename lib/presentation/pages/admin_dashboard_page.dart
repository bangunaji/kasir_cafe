import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../domain/entities/product.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import 'login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final TextEditingController _pinController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedMenu = 'produk'; // 'produk', 'kategori', 'laporan', 'pin'

  @override
  void initState() {
    super.initState();
    _loadKasirPin();
  }

  String get _currentUid {
    final state = context.read<AuthBloc>().state;
    if (state is AuthenticatedAsOwner) {
      return state.uid;
    }
    return '';
  }

  Future<void> _loadKasirPin() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    
    final pin = await _firestoreService.getKasirPin(uid);
    setState(() {
      _pinController.text = pin;
    });
  }

  Future<void> _saveKasirPin() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    if (_pinController.text.isNotEmpty) {
      await _firestoreService.updateKasirPin(uid, _pinController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN Kasir berhasil diperbarui')),
        );
      }
    }
  }

  void _showAddEditProductDialog({Product? product}) {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    final nameCtrl = TextEditingController(text: product?.name);
    final categoryCtrl = TextEditingController(text: product?.category ?? 'Coffee');
    final priceCtrl = TextEditingController(text: product?.price.toString() ?? '');
    File? selectedImage;
    bool isUploading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isUploading ? null : () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setDialogState(() {
                            selectedImage = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: selectedImage != null 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(selectedImage!, fit: BoxFit.cover),
                            )
                          : (product?.imageUrl != null && product!.imageUrl.isNotEmpty 
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    product.imageUrl, 
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red),
                                          Text('Gagal memuat gambar', style: TextStyle(fontSize: 10, color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Tap untuk pilih foto', style: TextStyle(color: Colors.grey)),
                                  ],
                                )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk')),
                    const SizedBox(height: 12),
                    StreamBuilder<List<String>>(
                      stream: _firestoreService.getCategories(_currentUid),
                      builder: (context, snapshot) {
                        final categories = snapshot.data ?? [];
                        
                        // Ensure current category is in the list to avoid dropdown error
                        if (categoryCtrl.text.isNotEmpty && !categories.contains(categoryCtrl.text)) {
                          categories.add(categoryCtrl.text);
                        }

                        if (categories.isEmpty) {
                          return TextField(
                            controller: categoryCtrl, 
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              hintText: 'Belum ada kategori. Ketik manual...',
                            )
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: categoryCtrl.text.isEmpty ? null : categoryCtrl.text,
                          items: categories.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          )).toList(),
                          onChanged: (val) => categoryCtrl.text = val ?? '',
                          decoration: const InputDecoration(labelText: 'Pilih Kategori'),
                        );
                      }
                    ),
                    TextField(
                      controller: priceCtrl, 
                      decoration: const InputDecoration(labelText: 'Harga (Angka)'), 
                      keyboardType: TextInputType.number
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context), 
                  child: const Text('Batal')
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                    
                    setDialogState(() => isUploading = true);
                    
                    String imageUrl = product?.imageUrl ?? '';
                    
                    // Upload new image if selected
                    if (selectedImage != null) {
                      final uploadedUrl = await _storageService.uploadProductImage(selectedImage!);
                      if (uploadedUrl != null) {
                        imageUrl = uploadedUrl;
                      } else {
                        // Upload failed
                        setDialogState(() => isUploading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gagal mengupload gambar. Periksa koneksi internet Anda.'), backgroundColor: Colors.red),
                          );
                        }
                        return;
                      }
                    }

                    final newProduct = Product(
                      id: product?.id ?? '',
                      name: nameCtrl.text,
                      category: categoryCtrl.text,
                      price: double.tryParse(priceCtrl.text) ?? 0,
                      imageUrl: imageUrl,
                      color: AppColors.primary,
                    );

                    if (product == null) {
                      await _firestoreService.addProduct(uid, newProduct);
                    } else {
                      await _firestoreService.updateProduct(uid, newProduct);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.cardLight,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          _buildSidebarItem(
            icon: Icons.inventory, 
            label: 'Daftar Produk', 
            view: 'produk',
          ),
          _buildSidebarItem(
            icon: Icons.category, 
            label: 'Kelola Kategori', 
            view: 'kategori',
          ),
          _buildSidebarItem(
            icon: Icons.bar_chart, 
            label: 'Laporan Penjualan', 
            view: 'laporan',
          ),
          _buildSidebarItem(
            icon: Icons.security, 
            label: 'PIN Kasir', 
            view: 'pin',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String label, required String view}) {
    bool isSelected = _selectedMenu == view;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      title: Text(label, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : Colors.black87,
      )),
      selected: isSelected,
      onTap: () {
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
        if (view == 'pin') {
          _showPinDialog();
        } else {
          setState(() {
            _selectedMenu = view;
          });
        }
      },
    );
  }

  void _showPinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah PIN Kasir'),
        content: TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN Baru (Angka)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ElevatedButton(
            onPressed: () {
              _saveKasirPin();
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUid;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dasbor Admin'),
            leading: isMobile ? null : const SizedBox.shrink(), // Remove back button on desktop
            actions: [
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: () {
                  context.read<AuthBloc>().add(SignOutEvent());
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              )
            ],
          ),
          drawer: isMobile ? Drawer(child: Builder(builder: (context) => _buildSidebar(context))) : null,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) Builder(builder: (context) => _buildSidebar(context)),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                  child: _buildMainContent(uid, isMobile),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMainContent(String uid, bool isMobile) {
    switch (_selectedMenu) {
      case 'kategori':
        return _buildCategoryList(uid);
      case 'laporan':
        return _buildSalesReport(uid);
      case 'produk':
      default:
        return _buildProductList(uid, isMobile);
    }
  }

  Widget _buildProductList(String uid, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Daftar Produk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: isMobile ? const Text('Tambah') : const Text('Tambah Produk'),
              onPressed: () => _showAddEditProductDialog(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: uid.isEmpty 
            ? const Center(child: Text('User ID tidak ditemukan. Harap login ulang.'))
            : StreamBuilder<List<Product>>(
                stream: _firestoreService.getProducts(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const Center(child: Text('Belum ada produk. Tambahkan sekarang!'));
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: p.color.withValues(alpha: 0.1),
                            ),
                            child: p.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, color: AppColors.primary)),
                                )
                              : const Icon(Icons.fastfood, color: AppColors.primary),
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${p.category} - Rp ${p.price.toStringAsFixed(0)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAddEditProductDialog(product: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _firestoreService.deleteProduct(uid, p.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(String uid) {
    final TextEditingController catCtrl = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kelola Kategori', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: catCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tambah Kategori Baru',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                if (catCtrl.text.isNotEmpty) {
                  _firestoreService.addCategory(uid, catCtrl.text);
                  catCtrl.clear();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
              child: const Text('Tambah'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: StreamBuilder<List<String>>(
            stream: _firestoreService.getCategories(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final categories = snapshot.data ?? [];
              if (categories.isEmpty) return const Center(child: Text('Belum ada kategori kustom.'));
              
              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Card(
                    child: ListTile(
                      title: Text(cat),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _firestoreService.deleteCategory(uid, cat),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSalesReport(String uid) {
    String reportType = 'hari'; // 'hari', 'minggu', 'bulan'
    
    return StatefulBuilder(
      builder: (context, setReportState) {
        DateTime now = DateTime.now();
        DateTime start;
        
        if (reportType == 'minggu') {
          start = now.subtract(const Duration(days: 7));
        } else if (reportType == 'bulan') {
          start = DateTime(now.year, now.month, 1);
        } else {
          start = DateTime(now.year, now.month, now.day);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Laporan Penjualan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildReportFilter(
                  label: 'Hari Ini', 
                  active: reportType == 'hari', 
                  onTap: () => setReportState(() => reportType = 'hari')
                ),
                const SizedBox(width: 12),
                _buildReportFilter(
                  label: '7 Hari Terakhir', 
                  active: reportType == 'minggu', 
                  onTap: () => setReportState(() => reportType = 'minggu')
                ),
                const SizedBox(width: 12),
                _buildReportFilter(
                  label: 'Bulan Ini', 
                  active: reportType == 'bulan', 
                  onTap: () => setReportState(() => reportType = 'bulan')
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<List<SaleTransaction>>(
                stream: _firestoreService.getTransactions(uid, start: start),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final transactions = snapshot.data ?? [];
                  
                  double totalRevenue = transactions.fold(0, (sum, tx) => sum + tx.total);
                  
                  if (transactions.isEmpty) return const Center(child: Text('Belum ada data penjualan pada periode ini.'));

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            const Text('Total Pendapatan', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(
                              'Rp ${totalRevenue.toStringAsFixed(0)}', 
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)
                            ),
                            Text('${transactions.length} Transaksi', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return Card(
                              child: ListTile(
                                title: Text('Transaksi #${tx.id.substring(0, 5)}'),
                                subtitle: Text('${tx.createdAt.hour}:${tx.createdAt.minute} - ${tx.items.length} item'),
                                trailing: Text('Rp ${tx.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildReportFilter({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
