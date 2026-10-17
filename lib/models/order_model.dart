import 'address_model.dart';
import 'order_item.dart';

class OrderModel {
  final String id;
  final String orderNo;
  final String customerId;
  final String customerName;
  final String phone;
  final List<OrderItem> items;
  final String orderType; // 'delivery' | 'takeaway'
  final AddressModel? address;
  final String paymentMethod; // 'cod' | 'gateway'
  final String paymentStatus; // 'unpaid' | 'paid'
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String? voucherCode;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason;

  OrderModel({
    required this.id,
    required this.orderNo,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.items,
    required this.orderType,
    this.address,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    this.voucherCode,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.rejectionReason,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) => OrderModel(
    id: id,
    orderNo: m['orderNo'] ?? '',
    customerId: m['customerId'] ?? '',
    customerName: m['customerName'] ?? '',
    phone: m['phone'] ?? '',
    items: ((m['items'] ?? []) as List)
        .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
    orderType: m['orderType'] ?? 'delivery',
    address: m['address'] != null
        ? AddressModel.fromMap(Map<String, dynamic>.from(m['address']))
        : null,
    paymentMethod: m['paymentMethod'] ?? 'cod',
    paymentStatus: m['paymentStatus'] ?? 'unpaid',
    subtotal: (m['subtotal'] ?? 0).toDouble(),
    discount: (m['discount'] ?? 0).toDouble(),
    deliveryFee: (m['deliveryFee'] ?? 0).toDouble(),
    total: (m['total'] ?? 0).toDouble(),
    voucherCode: m['voucherCode'],
    status: m['status'] ?? 'pending',
    createdAt: m['createdAt'] != null ? (m['createdAt'] as dynamic).toDate() : null,
    updatedAt: m['updatedAt'] != null ? (m['updatedAt'] as dynamic).toDate() : null,
    rejectionReason: m['rejectionReason'],
  );

  Map<String, dynamic> toMap() => {
    'orderNo': orderNo,
    'customerId': customerId,
    'customerName': customerName,
    'phone': phone,
    'items': items.map((e) => e.toMap()).toList(),
    'orderType': orderType,
    if (address != null) 'address': address!.toMap(),
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'subtotal': subtotal,
    'discount': discount,
    'deliveryFee': deliveryFee,
    'total': total,
    'voucherCode': voucherCode,
    'status': status,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'rejectionReason': rejectionReason,
  };
}