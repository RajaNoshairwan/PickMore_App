// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
//
// import '../../core/constants/collections.dart';
// import '../../models/voucher_model.dart';
//
// class AdminOffersViewModel extends ChangeNotifier {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   List<VoucherModel> vouchers = [];
//   bool loading = false;
//
//   Future<void> load() async {
//     loading = true;
//     notifyListeners();
//     final snap = await _db.collection(FireCollections.vouchers).get();
//     vouchers =
//         snap.docs.map((d) => VoucherModel.fromMap(d.id, d.data())).toList();
//     loading = false;
//     notifyListeners();
//   }
//
//   Future<bool> saveVoucher(VoucherModel v) async {
//     try {
//       await _db
//           .collection(FireCollections.vouchers)
//           .doc(v.code.toUpperCase())
//           .set(v.toMap());
//       await load();
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   Future<bool> deleteVoucher(String code) async {
//     try {
//       await _db.collection(FireCollections.vouchers).doc(code).delete();
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
import '../../models/voucher_model.dart';

class AdminOffersViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<VoucherModel> vouchers = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final snap = await _db.collection(FireCollections.vouchers).get();
      vouchers =
          snap.docs.map((d) => VoucherModel.fromMap(d.id, d.data())).toList();
    } catch (e) {
      error = e.toString();
      debugPrint('AdminOffers load error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveVoucher(VoucherModel v) async {
    try {
      final code = v.code.trim().toUpperCase();
      if (code.isEmpty) {
        error = 'Voucher code is required';
        notifyListeners();
        return false;
      }
      final data = v.toMap();
      data.removeWhere((k, value) => value == null);
      await _db
          .collection(FireCollections.vouchers)
          .doc(code)
          .set(data, SetOptions(merge: true));
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      debugPrint('AdminOffers saveVoucher error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVoucher(String code) async {
    try {
      await _db.collection(FireCollections.vouchers).doc(code).delete();
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }
}