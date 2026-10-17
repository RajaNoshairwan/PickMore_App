class VoucherModel {
  final String code;
  final String type; // 'percent' | 'flat'
  final double value;
  final double minOrder;
  final double? maxDiscount;
  final DateTime? expiresAt;
  final int usageLimit;
  final int usedCount;
  final bool isActive;

  VoucherModel({
    required this.code,
    required this.type,
    required this.value,
    required this.minOrder,
    this.maxDiscount,
    this.expiresAt,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
  });

  factory VoucherModel.fromMap(String code, Map<String, dynamic> m) => VoucherModel(
    code: code,
    type: m['type'] ?? 'flat',
    value: (m['value'] ?? 0).toDouble(),
    minOrder: (m['minOrder'] ?? 0).toDouble(),
    maxDiscount: m['maxDiscount'] != null ? (m['maxDiscount'] as num).toDouble() : null,
    expiresAt: m['expiresAt'] != null ? (m['expiresAt'] as dynamic).toDate() : null,
    usageLimit: m['usageLimit'] ?? 0,
    usedCount: m['usedCount'] ?? 0,
    isActive: m['isActive'] ?? true,
  );

  Map<String, dynamic> toMap() => {
    'type': type,
    'value': value,
    'minOrder': minOrder,
    'maxDiscount': maxDiscount,
    'expiresAt': expiresAt,
    'usageLimit': usageLimit,
    'usedCount': usedCount,
    'isActive': isActive,
  };

  double compute(double subtotal) {
    if (subtotal < minOrder) return 0;
    double disc = type == 'percent' ? subtotal * value / 100 : value;
    if (maxDiscount != null && disc > maxDiscount!) disc = maxDiscount!;
    return disc;
  }
}