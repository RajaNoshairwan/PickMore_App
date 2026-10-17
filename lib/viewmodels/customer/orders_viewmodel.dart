// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
//
// import '../../core/constants/app_strings.dart';
// import '../../core/constants/collections.dart';
// import '../../models/order_model.dart';
//
// class OrdersViewModel extends ChangeNotifier {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   List<OrderModel> activeOrders = [];
//   List<OrderModel> pastOrders = [];
//   bool loading = false;
//   String? error;
//
//   Future<void> load(String customerId) async {
//     loading = true;
//     notifyListeners();
//     try {
//       final activeSnap = await _db
//           .collection(FireCollections.pendingOrders)
//           .where('customerId', isEqualTo: customerId)
//           .get();
//       activeOrders = activeSnap.docs
//           .map((d) => OrderModel.fromMap(d.id, d.data()))
//           .toList()
//         ..sort((a, b) =>
//             (b.createdAt?.millisecondsSinceEpoch ?? 0)
//                 .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
//
//       final pastSnap = await _db
//           .collection(FireCollections.completedOrders)
//           .where('customerId', isEqualTo: customerId)
//           .get();
//       pastOrders = pastSnap.docs
//           .map((d) => OrderModel.fromMap(d.id, d.data()))
//           .toList()
//         ..sort((a, b) =>
//             (b.createdAt?.millisecondsSinceEpoch ?? 0)
//                 .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
//     } catch (e) {
//       error = e.toString();
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }
//
//   Future<bool> cancelOrder(OrderModel order) async {
//     if (order.status != OrderStatus.pending) return false;
//     try {
//       await _db
//           .collection(FireCollections.completedOrders)
//           .doc(order.id)
//           .set({
//         ...order.toMap(),
//         'status': OrderStatus.cancelled,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//       await _db
//           .collection(FireCollections.pendingOrders)
//           .doc(order.id)
//           .delete();
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   Future<bool> submitFeedback({
//     required String orderId,
//     required String customerId,
//     required String customerName,
//     required int rating,
//     required String comment,
//   }) async {
//     try {
//       await _db.collection(FireCollections.feedback).doc(orderId).set({
//         'customerId': customerId,
//         'customerName': customerName,
//         'rating': rating,
//         'comment': comment,
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/collections.dart';
import '../../models/order_model.dart';

class OrdersViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<OrderModel> activeOrders = [];
  List<OrderModel> pastOrders = [];
  bool loading = false;
  String? error;

  Future<void> load(String customerId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      // Fetch from all order collections in parallel.
      final futures = FireCollections.allOrderCollections.map((col) {
        return _db
            .collection(col)
            .where('customerId', isEqualTo: customerId)
            .get();
      }).toList();

      final results = await Future.wait(futures);

      final all = <OrderModel>[];
      for (final snap in results) {
        all.addAll(
          snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())),
        );
      }

      all.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));

      activeOrders = all
          .where((o) =>
      o.status != OrderStatus.completed &&
          o.status != OrderStatus.cancelled &&
          o.status != OrderStatus.rejected)
          .toList();

      pastOrders = all
          .where((o) =>
      o.status == OrderStatus.completed ||
          o.status == OrderStatus.cancelled ||
          o.status == OrderStatus.rejected)
          .toList();
    } catch (e) {
      error = e.toString();
      debugPrint('OrdersViewModel load error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Customer cancels a pending order — moves it from `pending_orders`
  /// to `cancelled_orders` in one atomic batch.
  Future<bool> cancelOrder(OrderModel order) async {
    if (order.status != OrderStatus.pending) return false;
    try {
      final batch = _db.batch();

      batch.delete(
        _db.collection(FireCollections.pendingOrders).doc(order.id),
      );

      final data = order.toMap();
      data['status'] = OrderStatus.cancelled;
      data['updatedAt'] = FieldValue.serverTimestamp();

      batch.set(
        _db.collection(FireCollections.cancelledOrders).doc(order.id),
        data,
      );

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('cancelOrder error: $e');
      return false;
    }
  }

  Future<bool> submitFeedback({
    required String orderId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    try {
      await _db.collection(FireCollections.feedback).doc(orderId).set({
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}