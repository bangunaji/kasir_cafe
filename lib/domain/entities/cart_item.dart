import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;
  final double discount;

  const CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0.0,
  });

  CartItem copyWith({int? quantity, double? discount}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }

  double get subtotal => product.price * quantity;
  double get total => subtotal - discount;

  @override
  List<Object?> get props => [product, quantity, discount];
}
