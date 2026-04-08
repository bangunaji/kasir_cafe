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

  @override
  List<Object?> get props => [id, name, category, price, imageUrl, color];
}
