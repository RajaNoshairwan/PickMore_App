class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final int sortOrder;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sortOrder,
    required this.isActive,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> m) => CategoryModel(
    id: id,
    name: m['name'] ?? '',
    imageUrl: m['imageUrl'] ?? '',
    sortOrder: m['sortOrder'] ?? 0,
    isActive: m['isActive'] ?? true,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'imageUrl': imageUrl,
    'sortOrder': sortOrder,
    'isActive': isActive,
  };
}