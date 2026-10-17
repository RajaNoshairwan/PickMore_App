import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/launchers.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/order_model.dart';
import '../../../viewmodels/admin/admin_orders_viewmodel.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const AdminOrderDetailScreen({super.key, required this.order});
  @override
  State<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late OrderModel order;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    order = widget.order;
  }

  Future<void> _advance(String status) async {
    setState(() => _working = true);
    final vm = context.read<AdminOrdersViewModel>();
    final ok = await vm.advanceStatus(order, status);
    if (!mounted) return;
    setState(() => _working = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked as ${_labelFor(status)}'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Failed to update order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(order);
    final canCancelAsAdmin = order.status == OrderStatus.accepted ||
        order.status == OrderStatus.preparing;

    final statusColor = _statusColor(order.status);
    final statusLabel = _labelFor(order.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  order.orderNo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // -------- Status header card --------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon(order.status),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order.orderType == OrderType.delivery
                            ? 'Delivery order'
                            : 'Pickup order',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.price(order.total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // -------- Customer --------
          _sectionCard(
            icon: Icons.person_outline,
            title: 'Customer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      order.phone,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // -------- Timeline --------
          _sectionCard(
            icon: Icons.access_time,
            title: 'Timeline',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kvRow('Placed on', Formatters.date(order.createdAt)),
                if (order.updatedAt != null) ...[
                  const SizedBox(height: 6),
                  _kvRow('Last updated', Formatters.date(order.updatedAt)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // -------- Address --------
          if (order.address != null) ...[
            _sectionCard(
              icon: Icons.location_on_outlined,
              title: 'Delivery Address',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.address!.fullAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Launchers.map(order.address!.lat, order.address!.lng),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Open in Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(
                          color: AppColors.secondary.withOpacity(0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // -------- Items --------
          _sectionCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Items (${order.items.length})',
            child: Column(
              children: order.items.map((i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${i.quantity}×',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          i.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.price(i.lineTotal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // -------- Totals --------
          _sectionCard(
            icon: Icons.receipt_outlined,
            title: 'Bill Summary',
            child: Column(
              children: [
                _kvRow('Subtotal', Formatters.price(order.subtotal)),
                const SizedBox(height: 6),
                _kvRow(
                  'Discount',
                  '-${Formatters.price(order.discount)}',
                  valueColor: order.discount > 0
                      ? Colors.green.shade700
                      : null,
                ),
                const SizedBox(height: 6),
                _kvRow('Delivery', Formatters.price(order.deliveryFee)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      Formatters.price(order.total),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // -------- Payment --------
          _sectionCard(
            icon: Icons.payments_outlined,
            title: 'Payment',
            child: Row(
              children: [
                Expanded(
                  child: _chip(
                    order.paymentMethod.toUpperCase(),
                    _isCod(order.paymentMethod)
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _chip(
                    order.paymentStatus.toUpperCase(),
                    order.paymentStatus.toLowerCase().contains('paid')
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -------- Action buttons --------
          if (next != null)
            CustomButton(
              label: 'Mark as ${_labelFor(next)}',
              loading: _working,
              onPressed: () => _advance(next),
            ),
          if (order.status == OrderStatus.pending) ...[
            const SizedBox(height: 10),
            CustomButton(
              label: 'Reject Order',
              outlined: true,
              onPressed: () => _advance(OrderStatus.rejected),
            ),
          ],
          if (canCancelAsAdmin) ...[
            const SizedBox(height: 10),
            CustomButton(
              label: 'Cancel Order (admin)',
              outlined: true,
              onPressed: () => _advance(OrderStatus.cancelled),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Reusable section card ----------
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ---------- Key-value row ----------
  Widget _kvRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ---------- Small pill chip ----------
  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            // color: color.shade700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  // ---------- Helpers ----------
  bool _isCod(String method) {
    final m = method.toLowerCase();
    return m.contains('cod') || m.contains('cash');
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending')) return Colors.orange;
    if (s.contains('accept')) return Colors.blue;
    if (s.contains('prepar')) return Colors.purple;
    if (s.contains('ready') || s.contains('out') || s.contains('deliver')) {
      return Colors.teal;
    }
    if (s.contains('complet')) return Colors.green;
    if (s.contains('cancel')) return Colors.red;
    if (s.contains('reject')) return Colors.red.shade900;
    return AppColors.primary;
  }

  IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending')) return Icons.hourglass_empty;
    if (s.contains('accept')) return Icons.check_circle_outline;
    if (s.contains('prepar')) return Icons.restaurant;
    if (s.contains('ready')) return Icons.shopping_bag_outlined;
    if (s.contains('out') || s.contains('deliver')) {
      return Icons.delivery_dining;
    }
    if (s.contains('complet')) return Icons.verified_outlined;
    if (s.contains('cancel')) return Icons.cancel_outlined;
    if (s.contains('reject')) return Icons.block;
    return Icons.receipt_long;
  }

  String? _nextStatus(OrderModel o) {
    switch (o.status) {
      case OrderStatus.pending:
        return OrderStatus.accepted;
      case OrderStatus.accepted:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return o.orderType == OrderType.delivery
            ? OrderStatus.outForDelivery
            : OrderStatus.readyForPickup;
      case OrderStatus.outForDelivery:
      case OrderStatus.readyForPickup:
        return OrderStatus.completed;
      default:
        return null;
    }
  }

  String _labelFor(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}