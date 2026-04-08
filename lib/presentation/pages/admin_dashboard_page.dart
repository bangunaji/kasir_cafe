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

  @override
  void initState() {
    super.initState();
    _loadKasirPin();
  }

  Future<void> _loadKasirPin() async {
    final pin = await _firestoreService.getKasirPin();
    setState(() {
      _pinController.text = pin;
    });
  }

  Future<void> _saveKasirPin() async {
    if (_pinController.text.isNotEmpty) {
      await _firestoreService.updateKasirPin(_pinController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN Kasir berhasil diperbarui')),
        );
      }
    }
  }

  void _showAddEditProductDialog({Product? product}) {
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
                          image: selectedImage != null 
                            ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                            : (product?.imageUrl != null && product!.imageUrl.isNotEmpty 
                                ? DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover)
                                : null),
                        ),
                        child: selectedImage == null && (product?.imageUrl == null || product!.imageUrl.isEmpty)
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap untuk pilih foto', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk')),
                    TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Kategori')),
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
                      // Delete old image if exists
                      if (product?.imageUrl != null && product!.imageUrl.isNotEmpty) {
                        await _storageService.deleteImage(product.imageUrl);
                      }
                      final uploadedUrl = await _storageService.uploadProductImage(selectedImage!);
                      if (uploadedUrl != null) {
                        imageUrl = uploadedUrl;
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
                      await _firestoreService.addProduct(newProduct);
                    } else {
                      await _firestoreService.updateProduct(newProduct);
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

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: AppColors.cardLight,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.inventory, color: AppColors.primary),
            title: Text('Daftar Produk', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.grey),
            title: const Text('Pengaturan PIN Kasir'),
            onTap: () {
              // Close drawer if it's open (for mobile)
              if (Scaffold.of(context).isDrawerOpen) {
                Navigator.pop(context);
              }
              _showPinDialog();
            },
          ),
        ],
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
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
          drawer: isMobile ? Drawer(child: _buildSidebar()) : null,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) _buildSidebar(),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                  child: Column(
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
                        child: StreamBuilder<List<Product>>(
                          stream: _firestoreService.getProducts(),
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
                                        color: p.color.withOpacity(0.1),
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
                                          onPressed: () => _firestoreService.deleteProduct(p.id),
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
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
