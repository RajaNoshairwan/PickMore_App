class AddressModel {
  final String label;
  final String fullAddress;
  final double lat;
  final double lng;
  final bool isDefault;

  AddressModel({
    required this.label,
    required this.fullAddress,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  factory AddressModel.fromMap(Map<String, dynamic> m) => AddressModel(
    label: m['label'] ?? '',
    fullAddress: m['fullAddress'] ?? '',
    lat: (m['lat'] ?? 0).toDouble(),
    lng: (m['lng'] ?? 0).toDouble(),
    isDefault: m['isDefault'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'label': label,
    'fullAddress': fullAddress,
    'lat': lat,
    'lng': lng,
    'isDefault': isDefault,
  };

  AddressModel copyWith({String? label, String? fullAddress, double? lat, double? lng, bool? isDefault}) =>
      AddressModel(
        label: label ?? this.label,
        fullAddress: fullAddress ?? this.fullAddress,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        isDefault: isDefault ?? this.isDefault,
      );
}