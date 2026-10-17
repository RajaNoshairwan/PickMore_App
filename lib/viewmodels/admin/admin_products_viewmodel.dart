// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
//
// import '../../core/constants/collections.dart';
// import '../../models/category_model.dart';
// import '../../models/product_model.dart';
//
// class AdminProductsViewModel extends ChangeNotifier {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   List<ProductModel> products = [];
//   List<CategoryModel> categories = [];
//   bool loading = false;
//
//   Future<void> load() async {
//     loading = true;
//     notifyListeners();
//     final snap = await _db.collection(FireCollections.products).get();
//     products = snap.docs.map((d) => ProductModel.fromMap(d.id, d.data())).toList();
//     final csnap = await _db.collection(FireCollections.categories).get();
//     categories =
//         csnap.docs.map((d) => CategoryModel.fromMap(d.id, d.data())).toList();
//     loading = false;
//     notifyListeners();
//   }
//
//   Future<bool> saveProduct(ProductModel product, {String? docId}) async {
//     try {
//       final data = product.toMap();
//       if (docId == null) {
//         await _db.collection(FireCollections.products).add(data);
//       } else {
//         // Clean up empty optional fields so Firestore doesn't get weird nulls.
//         final clean = Map<String, dynamic>.from(data);
//         if (clean['price'] == null) clean.remove('price');
//         if (clean['dealPrice'] == null) clean.remove('dealPrice');
//         if ((clean['variants'] as List?)?.isEmpty ?? true) {
//           clean.remove('variants');
//         }
//         await _db
//             .collection(FireCollections.products)
//             .doc(docId)
//             .update(clean);
//       }
//       await load();
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   Future<bool> deleteProduct(String id) async {
//     try {
//       await _db.collection(FireCollections.products).doc(id).delete();
//       await load();
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   Future<bool> toggleAvailable(ProductModel p, bool v) async {
//     try {
//       await _db
//           .collection(FireCollections.products)
//           .doc(p.id)
//           .update({'isAvailable': v});
//       await load();
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/collections.dart';
import '../../models/product_model.dart';

class AdminProductsViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ProductModel> products = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final snap = await _db.collection(FireCollections.products).get();
      products = snap.docs
          .map((d) => ProductModel.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      error = e.toString();
      debugPrint('AdminProducts load error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProduct(ProductModel product, {String? docId}) async {
    try {
      final data = product.toMap();
      // Remove null values (Firestore rejects them)
      data.removeWhere((k, v) => v == null);
      // If variants exist, drop single price — avoid stale field
      if ((data['variants'] as List?)?.isNotEmpty == true) {
        data.remove('price');
      }
      // If no variants, drop variants field
      if ((data['variants'] as List?)?.isEmpty ?? true) {
        data.remove('variants');
      }

      if (docId == null) {
        await _db.collection(FireCollections.products).add(data);
      } else {
        // Full replace — removes stale fields
        await _db
            .collection(FireCollections.products)
            .doc(docId)
            .set(data);
      }
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      debugPrint('AdminProducts saveProduct error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _db.collection(FireCollections.products).doc(id).delete();
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  Future<bool> toggleAvailable(ProductModel p, bool v) async {
    try {
      await _db
          .collection(FireCollections.products)
          .doc(p.id)
          .update({'isAvailable': v});
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}