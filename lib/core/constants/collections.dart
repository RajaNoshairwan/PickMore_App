// class FireCollections {
//   static const customers = 'customers';
//   static const admins = 'admins';
//   static const categories = 'categories';
//   static const products = 'products';
//   static const pendingOrders = 'pending_orders';
//   static const completedOrders = 'completed_orders';
//   static const vouchers = 'vouchers';
//   static const feedback = 'feedback';
//   static const settings = 'settings';
//
//   static const settingsStoreDoc = 'store';
// }

class FireCollections {
  static const customers = 'customers';
  static const admins = 'admins';
  static const categories = 'categories';
  static const products = 'products';

  // ─── Order collections (one per status) ───
  static const pendingOrders = 'pending_orders';
  static const acceptedOrders = 'accepted_orders';
  static const preparingOrders = 'preparing_orders';
  static const outForDeliveryOrders = 'out_for_delivery_orders';
  static const readyForPickupOrders = 'ready_for_pickup_orders';
  static const completedOrders = 'completed_orders';
  static const cancelledOrders = 'cancelled_orders';
  static const rejectedOrders = 'rejected_orders';

  static const activeOrderCollections = [
    pendingOrders,
    acceptedOrders,
    preparingOrders,
    outForDeliveryOrders,
    readyForPickupOrders,
  ];

  static const terminalOrderCollections = [
    completedOrders,
    cancelledOrders,
    rejectedOrders,
  ];

  static const allOrderCollections = [
    ...activeOrderCollections,
    ...terminalOrderCollections,
  ];

  static const vouchers = 'vouchers';
  static const feedback = 'feedback';
  static const settings = 'settings';
  static const settingsStoreDoc = 'store';

  /// Maps an order status string to its Firestore collection name.
  static String orderCollectionFor(String status) {
    switch (status) {
      case 'pending':
        return pendingOrders;
      case 'accepted':
        return acceptedOrders;
      case 'preparing':
        return preparingOrders;
      case 'out_for_delivery':
        return outForDeliveryOrders;
      case 'ready_for_pickup':
        return readyForPickupOrders;
      case 'completed':
        return completedOrders;
      case 'cancelled':
        return cancelledOrders;
      case 'rejected':
        return rejectedOrders;
      default:
        return pendingOrders;
    }
  }
}