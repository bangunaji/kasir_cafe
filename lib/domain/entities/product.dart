import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final Color color;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.color = const Color(0xFFFF6F00),
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'color': color.value,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      color: map['color'] != null ? Color(map['color'] as int) : const Color(0xFFFF6F00),
    );
  }

  @override
  List<Object?> get props => [id, name, category, price, imageUrl, color];
}
