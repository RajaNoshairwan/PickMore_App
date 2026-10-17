class OrderStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const preparing = 'preparing';
  static const outForDelivery = 'out_for_delivery';
  static const readyForPickup = 'ready_for_pickup';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const rejected = 'rejected';

  static const activeStatuses = [accepted, preparing, outForDelivery, readyForPickup];
  static const terminalStatuses = [completed, cancelled, rejected];
}

class OrderType {
  static const delivery = 'delivery';
  static const takeaway = 'takeaway';
}

class PaymentMethod {
  static const cod = 'cod';
  static const gateway = 'gateway';
}

class UserRole {
  static const customer = 'customer';
  static const admin = 'admin';
}