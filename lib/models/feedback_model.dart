class FeedbackModel {
  final String orderId;
  final String customerId;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  FeedbackModel({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory FeedbackModel.fromMap(String orderId, Map<String, dynamic> m) => FeedbackModel(
    orderId: orderId,
    customerId: m['customerId'] ?? '',
    customerName: m['customerName'] ?? '',
    rating: m['rating'] ?? 0,
    comment: m['comment'] ?? '',
    createdAt: m['createdAt'] != null ? (m['createdAt'] as dynamic).toDate() : null,
  );

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'customerName': customerName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt,
  };
}