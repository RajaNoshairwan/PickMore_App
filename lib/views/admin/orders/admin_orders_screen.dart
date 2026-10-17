import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/order_model.dart';
import '../../../viewmodels/admin/admin_orders_viewmodel.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminOrdersViewModel>(
      builder: (context, vm, _) {
        final onTheWay = [
          ...vm.outForDeliveryOrders,
          ...vm.readyForPickupOrders,
        ]..sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
            .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            toolbarHeight: 64,
            titleSpacing: 16,
            automaticallyImplyLeading: true,
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
                const Text(
                  'Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: AppColors.secondary,
                child: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.65),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tabs: [
                    _tabWithBadge('Pending', vm.pendingOrders.length),
                    _tabWithBadge('Accepted', vm.acceptedOrders.length),
                    _tabWithBadge('Preparing', vm.preparingOrders.length),
                    _tabWithBadge('Ready / Out', onTheWay.length),
                    _tabWithBadge('Completed', vm.completedOrders.length),
                    _tabWithBadge('Cancelled', vm.cancelledOrders.length),
                    _tabWithBadge('Rejected', vm.rejectedOrders.length),
                  ],
                ),
              ),
            ),
          ),
          body: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            controller: _tab,
            children: [
              _list(vm.pendingOrders, 'No pending orders'),
              _list(vm.acceptedOrders, 'No accepted orders'),
              _list(vm.preparingOrders, 'No orders preparing'),
              _list(onTheWay, 'Nothing out for delivery'),
              _list(vm.completedOrders, 'No completed orders'),
              _list(vm.cancelledOrders, 'No cancelled orders'),
              _list(vm.rejectedOrders, 'No rejected orders'),
            ],
          ),
        );
      },
    );
  }

  // -------- Tab with count badge --------
  Tab _tabWithBadge(String label, int count) {
    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------- Responsive order list --------
  Widget _list(List<OrderModel> orders, String emptyMsg) {
    if (orders.isEmpty) {
      return EmptyState(message: emptyMsg, icon: Icons.receipt_long);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Decide columns based on available width
        final crossAxisCount = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;

        if (crossAxisCount == 1) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: orders.length,
            itemBuilder: (_, i) => _orderCard(orders[i], constraints),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 148,
          ),
          itemCount: orders.length,
          itemBuilder: (_, i) => _orderCard(orders[i], constraints),
        );
      },
    );
  }

  // -------- Single order card --------
  Widget _orderCard(OrderModel o, BoxConstraints constraints) {
    final statusColor = _statusColor(o.status);
    final statusLabel = o.status.replaceAll('_', ' ').toUpperCase();

    return Container(
      margin: constraints.maxWidth >= 640
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminOrderDetailScreen(order: o),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left status bar
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Order no + customer
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.orderNo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _paymentChip(o.paymentMethod),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Customer name row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 9,
                            backgroundColor:
                            statusColor.withOpacity(0.15),
                            child: Text(
                              (o.customerName.isNotEmpty
                                  ? o.customerName[0]
                                  : '?')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              o.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Status + total
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Formatters.price(o.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Date
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 11, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.date(o.createdAt),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right chevron
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------- Payment chip --------
  Widget _paymentChip(String method) {
    final isCod = method.toLowerCase().contains('cod') ||
        method.toLowerCase().contains('cash');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isCod
            ? Colors.orange.withOpacity(0.12)
            : Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isCod ? Colors.orange.shade800 : Colors.green.shade700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // -------- Status color helper --------
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
}