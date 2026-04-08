import 'package:equatable/equatable.dart';
import '../../../domain/entities/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final double discount;

  const CartState({
    this.items = const [],
    this.discount = 0.0,
  });

  CartState copyWith({
    List<CartItem>? items,
    double? discount,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
    );
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get total => subtotal - discount;

  @override
  List<Object> get props => [items, discount];
}
