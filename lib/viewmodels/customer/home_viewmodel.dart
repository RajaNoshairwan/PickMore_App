import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/collections.dart';
import '../../models/product_model.dart';
import '../../models/store_settings.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ProductModel> products = [];
  List<String> categories = [];
  List<ProductModel> deals = [];
  StoreSettings? store;
  bool loading = false;
  String? error;

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection(FireCollections.products)
          .where('isAvailable', isEqualTo: true)
          .get();

      products = snap.docs
          .map((d) => ProductModel.fromMap(d.id, d.data()))
          .toList();

      final seen = <String>{};
      categories = products
          .map((p) => p.category)
          .where((c) => c.isNotEmpty && seen.add(c))
          .toList();

      deals = products.where((p) => p.isDeal).toList();

      // Load store settings for open/closed status.
      final s = await _db
          .collection(FireCollections.settings)
          .doc(FireCollections.settingsStoreDoc)
          .get();
      if (s.exists) store = StoreSettings.fromMap(s.data()!);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<ProductModel> byCategory(String category) =>
      products.where((p) => p.category == category).toList();

  /// Same category products (excluding current), used by "You may also like".
  List<ProductModel> related(ProductModel p, {int limit = 8}) {
    final list = products
        .where((x) => x.category == p.category && x.id != p.id)
        .toList();
    return list.take(limit).toList();
  }

  List<ProductModel> search(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return [];
    return products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.searchKeywords.any((k) => k.toLowerCase().contains(query));
    }).toList();
  }

  /// Simple open/closed check parsing "11:00 AM - 3:00 AM".
  bool get isStoreOpen {
    final hours = store?.openingHours ?? '';
    if (hours.isEmpty) return true;
    try {
      final parts = hours.split('-').map((s) => s.trim()).toList();
      if (parts.length != 2) return true;
      final open = _parseTime(parts[0]);
      final close = _parseTime(parts[1]);
      if (open == null || close == null) return true;

      final now = DateTime.now();
      final nowMin = now.hour * 60 + now.minute;
      final openMin = open.hour * 60 + open.minute;
      final closeMin = close.hour * 60 + close.minute;

      if (closeMin > openMin) {
        return nowMin >= openMin && nowMin < closeMin;
      } else {
        // overnight (e.g. 11 AM -> 3 AM)
        return nowMin >= openMin || nowMin < closeMin;
      }
    } catch (_) {
      return true;
    }
  }

  ({int hour, int minute})? _parseTime(String s) {
    final re = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
    final m = re.firstMatch(s);
    if (m == null) return null;
    int h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final isPm = m.group(3)!.toUpperCase() == 'PM';
    if (isPm && h != 12) h += 12;
    if (!isPm && h == 12) h = 0;
    return (hour: h, minute: min);
  }
}