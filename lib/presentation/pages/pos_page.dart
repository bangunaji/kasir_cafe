import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../widgets/product_grid_item.dart';
import '../widgets/cart_sidebar.dart';
import '../../../domain/entities/product.dart';
import '../../../core/theme/app_colors.dart';

class PosPage extends StatelessWidget {
  PosPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CartBloc(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Welcome, Kasir 1', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              Text('Kasir Cafe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: 300,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: 'Search menu...',
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Categories
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          _buildCategoryChip('All Menus', true),
                          const SizedBox(width: 12),
                          _buildCategoryChip('Coffee', false),
                          const SizedBox(width: 12),
                          _buildCategoryChip('Tea', false),
                          const SizedBox(width: 12),
                          _buildCategoryChip('Food', false),
                        ],
                      ),
                    ),

                    // Grid
                    Expanded(
                      child: ResponsiveBuilder(
                        builder: (context, sizingInformation) {
                          int crossAxisCount = 3;
                          if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
                            crossAxisCount = 5;
                          } else if (sizingInformation.deviceScreenType == DeviceScreenType.tablet) {
                            crossAxisCount = 4;
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: dummyProducts.length,
                            itemBuilder: (context, index) {
                              final product = dummyProducts[index];
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
              const CartSidebar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
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
    );
  }
}
