// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
//
// import '../../core/constants/collections.dart';
// import '../../models/store_settings.dart';
//
// class AdminSettingsViewModel extends ChangeNotifier {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   StoreSettings? store;
//   bool loading = false;
//
//   Future<void> load() async {
//     loading = true;
//     notifyListeners();
//     final doc = await _db
//         .collection(FireCollections.settings)
//         .doc(FireCollections.settingsStoreDoc)
//         .get();
//     if (doc.exists) store = StoreSettings.fromMap(doc.data()!);
//     loading = false;
//     notifyListeners();
//   }
//
//   Future<bool> save(StoreSettings s) async {
//     try {
//       await _db
//           .collection(FireCollections.settings)
//           .doc(FireCollections.settingsStoreDoc)
//           .set(s.toMap());
//       store = s;
//       notifyListeners();
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/collections.dart';
import '../../models/store_settings.dart';

class AdminSettingsViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StoreSettings? store;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final doc = await _db
          .collection(FireCollections.settings)
          .doc(FireCollections.settingsStoreDoc)
          .get();
      if (doc.exists) {
        store = StoreSettings.fromMap(doc.data()!);
      } else {
        // Seed defaults if the doc doesn't exist yet
        store = StoreSettings(
          deliveryFee: 100,
          takeawayFee: 0,
          whatsappNumber: '',
          phoneNumber: '',
          storeAddress: '',
          storeLat: 0,
          storeLng: 0,
          openingHours: '11:00 AM - 3:00 AM',
          aboutText: '',
        );
      }
    } catch (e) {
      error = e.toString();
      debugPrint('AdminSettings load error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(StoreSettings s) async {
    try {
      await _db
          .collection(FireCollections.settings)
          .doc(FireCollections.settingsStoreDoc)
          .set(s.toMap());
      store = s;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      debugPrint('AdminSettings save error: $e');
      notifyListeners();
      return false;
    }
  }
}