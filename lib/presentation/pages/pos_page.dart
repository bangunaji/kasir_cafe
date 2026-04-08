import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../widgets/product_grid_item.dart';
import '../widgets/cart_sidebar.dart';
import '../../../domain/entities/product.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/firestore_service.dart';
import 'login_page.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final FirestoreService _firestoreService = FirestoreService();
  
  String selectedCategory = 'Semua Menu';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onLogout() {
    context.read<AuthBloc>().add(SignOutEvent());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  String get _currentOwnerId {
    final state = context.read<AuthBloc>().state;
    if (state is AuthenticatedAsOwner) {
      return state.uid;
    } else if (state is AuthenticatedAsKasir) {
      return state.ownerId;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = _currentOwnerId;

    return BlocProvider(
      create: (context) => CartBloc(),
      child: ResponsiveBuilder(
        builder: (context, sizingInformation) {
          bool isMobile = sizingInformation.deviceScreenType == DeviceScreenType.mobile;
          
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            drawer: isMobile ? const Drawer(child: CartSidebar()) : null,
            appBar: isMobile 
                ? AppBar(
                    backgroundColor: AppColors.cardLight,
                    iconTheme: const IconThemeData(color: AppColors.textLight),
                    title: const Text('Kasir Cafe', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.error),
                        onPressed: _onLogout,
                      )
                    ],
                  )
                : null,
            body: SafeArea(
              child: Row(
                children: [
                  // Main Menu Area
                  Expanded(
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          color: AppColors.cardLight,
                          child: Row(
                            children: [
                              if (!isMobile)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Mode Kasir', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                    Text('Kasir Cafe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                  ],
                                ),
                              if (!isMobile) const Spacer(),
                              Flexible(
                                child: Container(
                                  constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 300),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Cari menu...',
                                      border: InputBorder.none,
                                      icon: const Icon(Icons.search, color: Colors.grey),
                                      suffixIcon: searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, color: Colors.grey),
                                              onPressed: () {
                                                searchController.clear();
                                                setState(() {
                                                  searchQuery = '';
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isMobile) ...[
                                const SizedBox(width: 24),
                                ElevatedButton.icon(
                                  onPressed: _onLogout,
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Keluar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        
                        // Categories
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCategoryChip('Semua Menu'),
                                const SizedBox(width: 12),
                                _buildCategoryChip('Kopi'),
                                const SizedBox(width: 12),
                                _buildCategoryChip('Teh'),
                                const SizedBox(width: 12),
                                _buildCategoryChip('Makanan'),
                              ],
                            ),
                          ),
                        ),

                        // Grid
                        Expanded(
                          child: ownerId.isEmpty 
                            ? const Center(child: Text('Data toko tidak ditemukan.'))
                            : StreamBuilder<List<Product>>(
                                stream: _firestoreService.getProducts(ownerId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  
                                  if (snapshot.hasError) {
                                    return Center(child: Text('Terjadi kesalahan: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                                  }

                                  List<Product> products = snapshot.data ?? [];
                                  
                                  // Filter locally
                                  products = products.where((product) {
                                    final matchesCategory = selectedCategory == 'Semua Menu' || product.category == selectedCategory;
                                    final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
                                    return matchesCategory && matchesSearch;
                                  }).toList();

                                  if (products.isEmpty) {
                                    return const Center(
                                      child: Text('Belum ada produk atau produk tidak ditemukan.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                    );
                                  }

                                  int crossAxisCount = 2; // Default for mobile
                                  if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
                                    crossAxisCount = 5;
                                  } else if (sizingInformation.deviceScreenType == DeviceScreenType.tablet) {
                                    crossAxisCount = 4;
                                  }

                                  return GridView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: isMobile ? 80 : 24),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      childAspectRatio: 0.8,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return ProductGridItem(
                                        product: product,
                                        onTap: () {
                                          context.read<CartBloc>().add(AddToCart(product));
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Sidebar Cart
                  if (!isMobile)
                    const CartSidebar(),
                ],
              ),
            ),
            floatingActionButton: isMobile 
                ? Builder(
                    builder: (context) => FloatingActionButton(
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: BlocBuilder<CartBloc, CartState>(
                        builder: (context, state) {
                          int totalItems = state.items.fold(0, (sum, item) => sum + item.quantity);
                          if (totalItems == 0) {
                            return const Icon(Icons.shopping_cart, color: Colors.white);
                          }
                          return Badge(
                            label: Text(totalItems.toString()),
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.shopping_cart, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  )
                : null,
          );
        }
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardLight,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
