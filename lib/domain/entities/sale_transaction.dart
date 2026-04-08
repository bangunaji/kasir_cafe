import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaleTransaction extends Equatable {
  final String id;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discount;
  final double total;
  final double cashReceived;
  final double change;
  final DateTime createdAt;

  const SaleTransaction({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.cashReceived,
    required this.change,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'cashReceived': cashReceived,
      'change': change,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SaleTransaction.fromMap(Map<String, dynamic> map, String docId) {
    return SaleTransaction(
      id: docId,
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      cashReceived: (map['cashReceived'] ?? 0).toDouble(),
      change: (map['change'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  List<Object?> get props => [id, items, subtotal, discount, total, cashReceived, change, createdAt];
}
