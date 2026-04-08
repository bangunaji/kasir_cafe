import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale_transaction.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Helper to get consistent collection path for a user
  CollectionReference<Map<String, dynamic>> _userProductsRef(String userId) {
    return _db.collection('users').doc(userId).collection('products');
  }

  DocumentReference<Map<String, dynamic>> _userConfigRef(String userId) {
    return _db.collection('users').doc(userId).collection('settings').doc('config');
  }

  CollectionReference<Map<String, dynamic>> _userTransactionsRef(String userId) {
    return _db.collection('users').doc(userId).collection('transactions');
  }

  DocumentReference<Map<String, dynamic>> _userCategoriesDoc(String userId) {
    return _db.collection('users').doc(userId).collection('settings').doc('categories');
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

  // CATEGORIES
  Stream<List<String>> getCategories(String userId) {
    return _userCategoriesDoc(userId).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data();
      if (data == null || !data.containsKey('list')) return [];
      return List<String>.from(data['list']);
    });
  }

  Future<void> addCategory(String userId, String categoryName) async {
    final doc = await _userCategoriesDoc(userId).get();
    List<String> categories = [];
    if (doc.exists && doc.data() != null) {
      categories = List<String>.from(doc.data()!['list'] ?? []);
    }
    if (!categories.contains(categoryName)) {
      categories.add(categoryName);
      await _userCategoriesDoc(userId).set({'list': categories});
    }
  }

  Future<void> deleteCategory(String userId, String categoryName) async {
    final doc = await _userCategoriesDoc(userId).get();
    if (doc.exists && doc.data() != null) {
      List<String> categories = List<String>.from(doc.data()!['list'] ?? []);
      categories.remove(categoryName);
      await _userCategoriesDoc(userId).set({'list': categories});
    }
  }

  // TRANSACTIONS
  Future<void> saveTransaction(String userId, SaleTransaction transaction) async {
    await _userTransactionsRef(userId).add(transaction.toMap());
  }

  Stream<List<SaleTransaction>> getTransactions(String userId, {DateTime? start, DateTime? end}) {
    Query<Map<String, dynamic>> query = _userTransactionsRef(userId).orderBy('createdAt', descending: true);
    
    if (start != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    if (end != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SaleTransaction.fromMap(doc.data(), doc.id)).toList();
    });
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
