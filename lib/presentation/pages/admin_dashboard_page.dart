import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/firestore_service.dart';
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
  final TextEditingController _pinController = TextEditingController();

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
    final imageUrlCtrl = TextEditingController(text: product?.imageUrl);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk')),
                TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Kategori')),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Harga (Angka)'), keyboardType: TextInputType.number),
                TextField(controller: imageUrlCtrl, decoration: const InputDecoration(labelText: 'Image URL (Opsional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final newProduct = Product(
                  id: product?.id ?? '', // empty id for add, firestore generates it
                  name: nameCtrl.text,
                  category: categoryCtrl.text,
                  price: double.tryParse(priceCtrl.text) ?? 0,
                  imageUrl: imageUrlCtrl.text,
                  color: const Color(0xFFFF6F00), // Default color
                );

                if (product == null) {
                  await _firestoreService.addProduct(newProduct);
                } else {
                  await _firestoreService.updateProduct(newProduct);
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Menu
          Container(
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
                  },
                ),
              ],
            ),
          ),
          
          // Main Content (Products list)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daftar Produk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Produk'),
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
                                leading: CircleAvatar(backgroundColor: p.color, child: const Icon(Icons.fastfood, color: Colors.white)),
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
}
