import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../../domain/entities/cart_item.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<UpdateDiscount>(_onUpdateDiscount);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final index = updatedItems.indexWhere((item) => item.product.id == event.product.id);

    if (index >= 0) {
      final currentItem = updatedItems[index];
      updatedItems[index] = currentItem.copyWith(quantity: currentItem.quantity + 1);
    } else {
      updatedItems.add(CartItem(product: event.product, quantity: 1));
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final index = updatedItems.indexWhere((item) => item.product.id == event.product.id);

    if (index >= 0) {
      final currentItem = updatedItems[index];
      if (currentItem.quantity > 1) {
        updatedItems[index] = currentItem.copyWith(quantity: currentItem.quantity - 1);
      } else {
        updatedItems.removeAt(index);
      }
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  void _onUpdateDiscount(UpdateDiscount event, Emitter<CartState> emit) {
    emit(state.copyWith(discount: event.discount));
  }
}
