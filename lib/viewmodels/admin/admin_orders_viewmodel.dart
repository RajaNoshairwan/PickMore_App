// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/foundation.dart';
// //
// // import '../../core/constants/app_strings.dart';
// // import '../../core/constants/collections.dart';
// // import '../../models/order_model.dart';
// //
// // class AdminOrdersViewModel extends ChangeNotifier {
// //   final FirebaseFirestore _db = FirebaseFirestore.instance;
// //
// //   List<OrderModel> pendingOrders = [];
// //   List<OrderModel> activeOrders = [];
// //   List<OrderModel> completedOrders = [];
// //   bool loading = false;
// //   String? error;
// //
// //   Future<void> loadAll() async {
// //     loading = true;
// //     notifyListeners();
// //     try {
// //       final pendingSnap = await _db
// //           .collection(FireCollections.pendingOrders)
// //           .where('status', isEqualTo: OrderStatus.pending)
// //           .get();
// //       pendingOrders = pendingSnap.docs
// //           .map((d) => OrderModel.fromMap(d.id, d.data()))
// //           .toList();
// //
// //       final activeSnap = await _db
// //           .collection(FireCollections.pendingOrders)
// //           .where('status', whereIn: OrderStatus.activeStatuses)
// //           .get();
// //       activeOrders = activeSnap.docs
// //           .map((d) => OrderModel.fromMap(d.id, d.data()))
// //           .toList();
// //
// //       final doneSnap = await _db
// //           .collection(FireCollections.completedOrders)
// //           .get();
// //       completedOrders = doneSnap.docs
// //           .map((d) => OrderModel.fromMap(d.id, d.data()))
// //           .toList();
// //     } catch (e) {
// //       error = e.toString();
// //     } finally {
// //       loading = false;
// //       notifyListeners();
// //     }
// //   }
// //
// //   Future<bool> advanceStatus(OrderModel order, String newStatus,
// //       {String? reason}) async {
// //     try {
// //       final data = {
// //         ...order.toMap(),
// //         'status': newStatus,
// //         'updatedAt': FieldValue.serverTimestamp(),
// //         if (reason != null) 'rejectionReason': reason,
// //         if (newStatus == OrderStatus.completed &&
// //             order.paymentMethod == PaymentMethod.cod)
// //           'paymentStatus': 'paid',
// //       };
// //       if (OrderStatus.terminalStatuses.contains(newStatus)) {
// //         await _db
// //             .collection(FireCollections.completedOrders)
// //             .doc(order.id)
// //             .set(data);
// //         await _db
// //             .collection(FireCollections.pendingOrders)
// //             .doc(order.id)
// //             .delete();
// //       } else {
// //         await _db
// //             .collection(FireCollections.pendingOrders)
// //             .doc(order.id)
// //             .update({
// //           'status': newStatus,
// //           'updatedAt': FieldValue.serverTimestamp(),
// //           if (reason != null) 'rejectionReason': reason,
// //         });
// //       }
// //       await loadAll();
// //       return true;
// //     } catch (e) {
// //       error = e.toString();
// //       notifyListeners();
// //       return false;
// //     }
// //   }
// // }
//
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
//
// import '../../core/constants/app_strings.dart';
// import '../../core/constants/collections.dart';
// import '../../models/order_model.dart';
//
// class AdminOrdersViewModel extends ChangeNotifier {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   List<OrderModel> pendingOrders = [];
//   List<OrderModel> activeOrders = [];
//   List<OrderModel> completedOrders = [];
//   bool loading = false;
//   String? error;
//
//   Future<void> loadAll() async {
//     loading = true;
//     error = null;
//     notifyListeners();
//     try {
//       final pendingSnap = await _db
//           .collection(FireCollections.pendingOrders)
//           .where('status', isEqualTo: OrderStatus.pending)
//           .get();
//
//       final activeSnap = await _db
//           .collection(FireCollections.pendingOrders)
//           .where('status', whereIn: OrderStatus.activeStatuses)
//           .get();
//
//       final doneSnap = await _db
//           .collection(FireCollections.completedOrders)
//           .get();
//
//       pendingOrders = pendingSnap.docs
//           .map((d) => OrderModel.fromMap(d.id, d.data()))
//           .toList()
//         ..sort(_byNewest);
//
//       activeOrders = activeSnap.docs
//           .map((d) => OrderModel.fromMap(d.id, d.data()))
//           .toList()
//         ..sort(_byNewest);
//
//       completedOrders = doneSnap.docs
//           .map((d) => OrderModel.fromMap(d.id, d.data()))
//           .toList()
//         ..sort(_byNewest);
//     } catch (e) {
//       error = e.toString();
//       debugPrint('AdminOrders loadAll error: $e');
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }
//
//   int _byNewest(OrderModel a, OrderModel b) {
//     final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
//     final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
//     return tb.compareTo(ta);
//   }
//
//   Future<bool> advanceStatus(
//       OrderModel order,
//       String newStatus, {
//         String? reason,
//       }) async {
//     try {
//       if (OrderStatus.terminalStatuses.contains(newStatus)) {
//         // Move to completed_orders
//         final data = order.toMap();
//         data['status'] = newStatus;
//         data['updatedAt'] = FieldValue.serverTimestamp();
//         if (reason != null) data['rejectionReason'] = reason;
//         if (newStatus == OrderStatus.completed &&
//             order.paymentMethod == PaymentMethod.cod) {
//           data['paymentStatus'] = 'paid';
//         }
//
//         await _db
//             .collection(FireCollections.completedOrders)
//             .doc(order.id)
//             .set(data);
//
//         await _db
//             .collection(FireCollections.pendingOrders)
//             .doc(order.id)
//             .delete();
//       } else {
//         // Stay in pending_orders, just update status
//         final update = <String, dynamic>{
//           'status': newStatus,
//           'updatedAt': FieldValue.serverTimestamp(),
//         };
//         if (reason != null) update['rejectionReason'] = reason;
//
//         await _db
//             .collection(FireCollections.pendingOrders)
//             .doc(order.id)
//             .update(update);
//       }
//
//       await loadAll();
//       return true;
//     } catch (e) {
//       error = e.toString();
//       debugPrint('AdminOrders advanceStatus error: $e');
//       notifyListeners();
//       return false;
//     }
//   }
// }

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/collections.dart';
import '../../models/order_model.dart';

class AdminOrdersViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, StreamSubscription<QuerySnapshot>> _subs = {};

  List<OrderModel> pendingOrders = [];
  List<OrderModel> acceptedOrders = [];
  List<OrderModel> preparingOrders = [];
  List<OrderModel> outForDeliveryOrders = [];
  List<OrderModel> readyForPickupOrders = [];
  List<OrderModel> completedOrders = [];
  List<OrderModel> cancelledOrders = [];
  List<OrderModel> rejectedOrders = [];

  bool loading = true;
  String? error;

  AdminOrdersViewModel() {
    _startStreams();
  }

  void _startStreams() {
    for (final col in FireCollections.allOrderCollections) {
      _subs[col] = _db.collection(col).snapshots().listen(
            (snap) {
          final list = snap.docs
              .map((d) => OrderModel.fromMap(d.id, d.data()))
              .toList()
            ..sort((a, b) =>
                (b.createdAt?.millisecondsSinceEpoch ?? 0)
                    .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
          _assign(col, list);
          loading = false;
          notifyListeners();
        },
        onError: (e) {
          error = e.toString();
          loading = false;
          debugPrint('AdminOrders stream error [$col]: $e');
          notifyListeners();
        },
      );
    }
  }

  void _assign(String col, List<OrderModel> list) {
    switch (col) {
      case FireCollections.pendingOrders:
        pendingOrders = list;
        break;
      case FireCollections.acceptedOrders:
        acceptedOrders = list;
        break;
      case FireCollections.preparingOrders:
        preparingOrders = list;
        break;
      case FireCollections.outForDeliveryOrders:
        outForDeliveryOrders = list;
        break;
      case FireCollections.readyForPickupOrders:
        readyForPickupOrders = list;
        break;
      case FireCollections.completedOrders:
        completedOrders = list;
        break;
      case FireCollections.cancelledOrders:
        cancelledOrders = list;
        break;
      case FireCollections.rejectedOrders:
        rejectedOrders = list;
        break;
    }
  }

  /// Manually refresh all streams is unnecessary — they're live.
  /// Kept for compatibility with existing calls.
  Future<void> loadAll() async {
    // no-op: streams are always up-to-date
  }

  /// Moves an order between status collections atomically.
  Future<bool> advanceStatus(
      OrderModel order,
      String newStatus, {
        String? reason,
      }) async {
    try {
      final fromCol = FireCollections.orderCollectionFor(order.status);
      final toCol = FireCollections.orderCollectionFor(newStatus);

      if (fromCol == toCol) return true;

      final batch = _db.batch();

      batch.delete(_db.collection(fromCol).doc(order.id));

      final data = order.toMap();
      data['status'] = newStatus;
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (reason != null) data['rejectionReason'] = reason;
      if (newStatus == OrderStatus.completed &&
          order.paymentMethod == PaymentMethod.cod) {
        data['paymentStatus'] = 'paid';
      }

      batch.set(_db.collection(toCol).doc(order.id), data);

      await batch.commit();
      return true;
    } catch (e) {
      error = e.toString();
      debugPrint('AdminOrders advanceStatus error: $e');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    super.dispose();
  }
}