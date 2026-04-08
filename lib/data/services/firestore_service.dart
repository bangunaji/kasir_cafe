import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // PRODUCT CRUD
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _db.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  // SETTINGS (PIN)
  Future<String> getKasirPin() async {
    final doc = await _db.collection('settings').doc('kasir_pin').get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('pin')) {
      return doc.data()!['pin'].toString();
    }
    return '1234'; // Default
  }

  Future<void> updateKasirPin(String newPin) async {
    await _db.collection('settings').doc('kasir_pin').set({'pin': newPin}, SetOptions(merge: true));
  }
}
