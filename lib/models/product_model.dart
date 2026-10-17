import 'product_variant.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;         // string, e.g. "Special Pizza"
  final String imageUrl;
  final List<ProductVariant> variants;
  final double? price;           // for products without variants
  final bool isAvailable;
  final bool isDeal;
  final double? dealPrice;
  final List<String> searchKeywords;

  ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.imageUrl,
    this.variants = const [],
    this.price,
    this.isAvailable = true,
    this.isDeal = false,
    this.dealPrice,
    this.searchKeywords = const [],
  });

  bool get hasVariants => variants.isNotEmpty;

  /// Cheapest price shown on lists.
  double get minPrice {
    if (hasVariants) {
      return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
    }
    return effectivePrice;
  }

  /// Highest price for "From X - Y" range display.
  double get maxPrice {
    if (hasVariants) {
      return variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);
    }
    return effectivePrice;
  }

  /// Price if the product has no variants.
  double get effectivePrice {
    if (isDeal && dealPrice != null && dealPrice! > 0) return dealPrice!;
    return price ?? 0;
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> m) {
    final variantsRaw = (m['variants'] as List?) ?? const [];
    return ProductModel(
      id: id,
      name: (m['name'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      category: (m['category'] ?? '').toString(),
      imageUrl: (m['imageUrl'] ?? '').toString(),
      variants: variantsRaw
          .map((e) => ProductVariant.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      price: m['price'] != null ? (m['price'] as num).toDouble() : null,
      isAvailable: m['isAvailable'] ?? true,
      isDeal: m['isDeal'] ?? false,
      dealPrice:
      m['dealPrice'] != null ? (m['dealPrice'] as num).toDouble() : null,
      searchKeywords: List<String>.from(m['searchKeywords'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (description.isNotEmpty) 'description': description,
    'category': category,
    'imageUrl': imageUrl,
    if (variants.isNotEmpty)
      'variants': variants.map((v) => v.toMap()).toList(),
    if (price != null) 'price': price,
    'isAvailable': isAvailable,
    'isDeal': isDeal,
    if (dealPrice != null) 'dealPrice': dealPrice,
    'searchKeywords': searchKeywords,
  };
}