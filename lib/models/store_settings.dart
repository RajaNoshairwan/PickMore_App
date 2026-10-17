class StoreSettings {
  final double deliveryFee;
  final double takeawayFee;
  final String whatsappNumber;
  final String phoneNumber;
  final String storeAddress;
  final double storeLat;
  final double storeLng;
  final String openingHours;
  final String aboutText;

  StoreSettings({
    required this.deliveryFee,
    required this.takeawayFee,
    required this.whatsappNumber,
    required this.phoneNumber,
    required this.storeAddress,
    required this.storeLat,
    required this.storeLng,
    required this.openingHours,
    required this.aboutText,
  });

  // factory StoreSettings.fromMap(Map<String, dynamic> m) => StoreSettings(
  //   deliveryFee: (m['deliveryFee'] ?? 0).toDouble(),
  //   takeawayFee: (m['takeawayFee'] ?? 0).toDouble(),
  //   whatsappNumber: m['whatsappNumber'] ?? '',
  //   phoneNumber: m['phoneNumber'] ?? '',
  //   storeAddress: m['storeAddress'] ?? '',
  //   storeLat: (m['storeLat'] ?? 0).toDouble(),
  //   storeLng: (m['storeLng'] ?? 0).toDouble(),
  //   openingHours: m['openingHours'] ?? '',
  //   aboutText: m['aboutText'] ?? '',
  // );

  factory StoreSettings.fromMap(Map<String, dynamic> m) => StoreSettings(
    deliveryFee: _toDouble(m['deliveryFee']),
    takeawayFee: _toDouble(m['takeawayFee']),
    whatsappNumber: (m['whatsappNumber'] ?? '').toString(),
    phoneNumber: (m['phoneNumber'] ?? '').toString(),
    storeAddress: (m['storeAddress'] ?? '').toString(),
    storeLat: _toDouble(m['storeLat']),
    storeLng: _toDouble(m['storeLng']),
    openingHours: (m['openingHours'] ?? '').toString(),
    aboutText: (m['aboutText'] ?? '').toString(),
  );

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Map<String, dynamic> toMap() => {
    'deliveryFee': deliveryFee,
    'takeawayFee': takeawayFee,
    'whatsappNumber': whatsappNumber,
    'phoneNumber': phoneNumber,
    'storeAddress': storeAddress,
    'storeLat': storeLat,
    'storeLng': storeLng,
    'openingHours': openingHours,
    'aboutText': aboutText,
  };
}