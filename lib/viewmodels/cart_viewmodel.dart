import 'package:flutter/foundation.dart';

import '../models/order_item.dart';
import '../models/product_model.dart';
import '../models/product_variant.dart';

class CartViewModel extends ChangeNotifier {
  final Map<String, OrderItem> _items = {};

  List<OrderItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.values.fold(0, (a, b) => a + b.quantity);
  double get subtotal => _items.values.fold(0.0, (sum, i) => sum + i.lineTotal);

  /// Whether any variant of this product is in the cart.
  bool contains(String productId) =>
      _items.values.any((i) => i.productId == productId);

  bool containsVariant(String productId, String? variantId) =>
      _items.containsKey(variantId == null ? productId : '${productId}_$variantId');

  OrderItem? getLine(String productId, String? variantId) =>
      _items[variantId == null ? productId : '${productId}_$variantId'];

  void addVariant(ProductModel p, ProductVariant? variant) {
    final key = variant == null ? p.id : '${p.id}_${variant.id}';
    final existing = _items[key];
    final unitPrice = variant?.price ?? p.effectivePrice;

    if (existing != null) {
      _items[key] = OrderItem(
        productId: existing.productId,
        variantId: existing.variantId,
        variantName: existing.variantName,
        name: existing.name,
        unitPrice: existing.unitPrice,
        quantity: existing.quantity + 1,
        imageUrl: existing.imageUrl,
      );
    } else {
      _items[key] = OrderItem(
        productId: p.id,
        variantId: variant?.id,
        variantName: variant?.name,
        name: p.name,
        unitPrice: unitPrice,
        quantity: 1,
        imageUrl: p.imageUrl,
      );
    }
    notifyListeners();
  }

  /// Convenience for products without variants.
  void add(ProductModel p) => addVariant(p, null);

  /// Used by CartScreen +/- buttons.
  void incrementLine(OrderItem item) {
    final key = item.cartKey;
    final existing = _items[key];
    if (existing == null) return;
    _items[key] = OrderItem(
      productId: existing.productId,
      variantId: existing.variantId,
      variantName: existing.variantName,
      name: existing.name,
      unitPrice: existing.unitPrice,
      quantity: existing.quantity + 1,
      imageUrl: existing.imageUrl,
    );
    notifyListeners();
  }

  void decrementLine(OrderItem item) {
    final key = item.cartKey;
    final existing = _items[key];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      _items.remove(key);
    } else {
      _items[key] = OrderItem(
        productId: existing.productId,
        variantId: existing.variantId,
        variantName: existing.variantName,
        name: existing.name,
        unitPrice: existing.unitPrice,
        quantity: existing.quantity - 1,
        imageUrl: existing.imageUrl,
      );
    }
    notifyListeners();
  }

  void removeLine(OrderItem item) {
    _items.remove(item.cartKey);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void replaceAll(List<OrderItem> items) {
    _items.clear();
    for (final i in items) {
      _items[i.cartKey] = i;
    }
    notifyListeners();
  }
}