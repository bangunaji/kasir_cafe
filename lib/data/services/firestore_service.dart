import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Helper to get consistent collection path for a user
  CollectionReference<Map<String, dynamic>> _userProductsRef(String userId) {
    return _db.collection('users').doc(userId).collection('products');
  }

  DocumentReference<Map<String, dynamic>> _userConfigRef(String userId) {
    return _db.collection('users').doc(userId).collection('settings').doc('config');
  }

  // PRODUCT CRUD
  Stream<List<Product>> getProducts(String userId) {
    return _userProductsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addProduct(String userId, Product product) async {
    await _userProductsRef(userId).add(product.toMap());
  }

  Future<void> updateProduct(String userId, Product product) async {
    await _userProductsRef(userId).doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String userId, String productId) async {
    await _userProductsRef(userId).doc(productId).delete();
  }

  // SETTINGS (PIN) - Per User
  Future<String> getKasirPin(String userId) async {
    final doc = await _userConfigRef(userId).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('pin')) {
      return doc.data()!['pin'].toString();
    }
    return '1234'; // Default
  }

  Future<void> updateKasirPin(String userId, String newPin) async {
    await _userConfigRef(userId).set({'pin': newPin}, SetOptions(merge: true));
  }
}
