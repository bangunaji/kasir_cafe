import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../widgets/product_grid_item.dart';
import '../widgets/cart_sidebar.dart';
import '../../../domain/entities/product.dart';
import '../../../core/theme/app_colors.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  // Dummy products
  final List<Product> dummyProducts = [
    const Product(id: '1', name: 'Espresso', category: 'Coffee', price: 25000, imageUrl: '', color: Color(0xFF6D4C41)),
    const Product(id: '2', name: 'Cappuccino', category: 'Coffee', price: 35000, imageUrl: '', color: Color(0xFF8D6E63)),
    const Product(id: '3', name: 'Latte', category: 'Coffee', price: 35000, imageUrl: '', color: Color(0xFFBCAAA4)),
    const Product(id: '4', name: 'Matcha', category: 'Tea', price: 40000, imageUrl: '', color: Color(0xFF81C784)),
    const Product(id: '5', name: 'Lemon Tea', category: 'Tea', price: 20000, imageUrl: '', color: Color(0xFFFFD54F)),
    const Product(id: '6', name: 'Croissant', category: 'Food', price: 25000, imageUrl: '', color: Color(0xFFFFB74D)),
    const Product(id: '7', name: 'Cheesecake', category: 'Food', price: 30000, imageUrl: '', color: Color(0xFFFFE082)),
    const Product(id: '8', name: 'French Fries', category: 'Food', price: 20000, imageUrl: '', color: Color(0xFFFFCC80)),
  ];

  String selectedCategory = 'All Menus';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  List<Product> get filteredProducts {
    return dummyProducts.where((product) {
      final matchesCategory = selectedCategory == 'All Menus' || product.category == selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                    Text('Welcome, Kasir 1', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                                      hintText: 'Search menu...',
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
                                _buildCategoryChip('All Menus'),
                                const SizedBox(width: 12),
                                _buildCategoryChip('Coffee'),
                                const SizedBox(width: 12),
                                _buildCategoryChip('Tea'),
                                const SizedBox(width: 12),
                                _buildCategoryChip('Food'),
                              ],
                            ),
                          ),
                        ),

                        // Grid
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              int crossAxisCount = 2; // Default for mobile
                              if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
                                crossAxisCount = 5;
                              } else if (sizingInformation.deviceScreenType == DeviceScreenType.tablet) {
                                crossAxisCount = 4;
                              }

                              final products = filteredProducts;

                              if (products.isEmpty) {
                                return const Center(
                                  child: Text('No products found matching your search.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                );
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
                                      if (isMobile) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${product.name} added to cart'),
                                            duration: const Duration(seconds: 1),
                                            action: SnackBarAction(
                                              label: 'VIEW CART',
                                              onPressed: () {
                                                Scaffold.of(context).openDrawer();
                                              },
                                            ),
                                          ),
                                        );
                                      }
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
                      child: const Icon(Icons.shopping_cart, color: Colors.white),
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
