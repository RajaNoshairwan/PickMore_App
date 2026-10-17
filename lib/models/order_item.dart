class OrderItem {
  final String productId;
  final String? variantId;      // null when product has no variants
  final String? variantName;    // "Medium"
  final String name;            // "Behari Kabab Pizza"
  final double unitPrice;
  final int quantity;
  final String imageUrl;

  OrderItem({
    required this.productId,
    this.variantId,
    this.variantName,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl = '',
  });

  /// Key used inside the cart map so variants don't collide.
  String get cartKey => variantId == null ? productId : '${productId}_$variantId';

  String get displayName =>
      variantName == null ? name : '$name ($variantName)';

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    productId: (m['productId'] ?? '').toString(),
    variantId: m['variantId']?.toString(),
    variantName: m['variantName']?.toString(),
    name: (m['name'] ?? '').toString(),
    unitPrice: (m['unitPrice'] ?? 0).toDouble(),
    quantity: m['quantity'] ?? 1,
    imageUrl: (m['imageUrl'] ?? '').toString(),
  );

  Map<String, dynamic> toMap() => {
    'productId': productId,
    if (variantId != null) 'variantId': variantId,
    if (variantName != null) 'variantName': variantName,
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'imageUrl': imageUrl,
  };
}