class ProductVariant {
  final String id;
  final String name;
  final double price;

  ProductVariant({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> m) => ProductVariant(
    id: (m['id'] ?? '').toString(),
    name: (m['name'] ?? '').toString(),
    price: (m['price'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
  };
}