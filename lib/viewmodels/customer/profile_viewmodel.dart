import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/collections.dart';
import '../../models/address_model.dart';
import '../../models/app_user.dart';
import '../../models/store_settings.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StoreSettings? store;
  bool loading = false;
  String? error;

  Future<void> loadStore() async {
    loading = true;
    notifyListeners();
    try {
      final doc = await _db
          .collection(FireCollections.settings)
          .doc(FireCollections.settingsStoreDoc)
          .get();
      if (doc.exists) store = StoreSettings.fromMap(doc.data()!);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(AppUser user) async {
    try {
      final collection = user.role == 'admin'
          ? FireCollections.admins
          : FireCollections.customers;
      await _db.collection(collection).doc(user.uid).update(user.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveAddress(String uid, AddressModel address) async {
    try {
      await _db.collection(FireCollections.customers).doc(uid).update({
        'defaultAddress': address.toMap(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}