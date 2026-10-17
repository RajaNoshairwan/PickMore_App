import 'address_model.dart';

class AppUser {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String role; // 'customer' | 'admin'
  final AddressModel? defaultAddress;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.defaultAddress,
    this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
    uid: uid,
    name: m['name'] ?? '',
    phone: m['phone'] ?? '',
    email: m['email'] ?? '',
    role: m['role'] ?? 'customer',
    defaultAddress: m['defaultAddress'] != null
        ? AddressModel.fromMap(Map<String, dynamic>.from(m['defaultAddress']))
        : null,
    createdAt: m['createdAt'] != null
        ? (m['createdAt'] as dynamic).toDate()
        : null,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'email': email,
    'role': role,
    if (defaultAddress != null) 'defaultAddress': defaultAddress!.toMap(),
    'createdAt': createdAt,
  };

  AppUser copyWith({
    String? name,
    String? phone,
    String? email,
    AddressModel? defaultAddress,
  }) =>
      AppUser(
        uid: uid,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        role: role,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        createdAt: createdAt,
      );
}