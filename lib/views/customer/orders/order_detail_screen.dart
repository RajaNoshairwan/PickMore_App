import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/order_model.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../../../viewmodels/customer/orders_viewmodel.dart';
import 'feedback_screen.dart';

// ============================================================
// RESPONSIVE SCALING HELPERS
// ============================================================
class _Resp {
  static const double _base = 390.0;
  static const double _maxContentWidth = 640.0;

  static Size _size(BuildContext c) => MediaQuery.sizeOf(c);

  static double _w(BuildContext c) => _size(c).width;
  static double _h(BuildContext c) => _size(c).height;

  static double scale(BuildContext c) {
    final w = _w(c);
    final h = _h(c);
    final byWidth = (w / _base).clamp(0.82, 1.30);
    final byHeight = h < 480 ? 0.90 : 1.0;
    return byWidth * byHeight;
  }

  static double textScale(BuildContext c) {
    final w = _w(c);
    final s = (w / _base).clamp(0.88, 1.18);
    final system = MediaQuery.textScalerOf(c).scale(1.0);
    return s * system.clamp(0.85, 1.25);
  }

  static double s(BuildContext c, double v) => v * scale(c);
  static double t(BuildContext c, double v) => v * textScale(c);

  static double contentWidth(BuildContext c) {
    final w = _w(c);
    return w > _maxContentWidth ? _maxContentWidth : w;
  }

  static double hPad(BuildContext c) => s(c, 16);
}

// ============================================================
// LOCAL PALETTE (mirrors HomeScreen)
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF6B35);

  static final accentA10 = accent.withOpacity(0.10);
  static final accentA08 = accent.withOpacity(0.08);
  static final headerEndA35 = headerEnd.withOpacity(0.35);
  static final blackA04 = Colors.black.withOpacity(0.04);
  static final blackA05 = Colors.black.withOpacity(0.05);
  static final divider = AppColors.divider;
}

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _Resp.contentWidth(context),
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              _Resp.hPad(context),
              _Resp.s(context, 16),
              _Resp.hPad(context),
              _Resp.s(context, 24),
            ),
            children: [
              // ── Status ──
              _statusCard(context),

              SizedBox(height: _Resp.s(context, 12)),

              // ── Placed on (date + time) ──
              _placedOnCard(context),

              SizedBox(height: _Resp.s(context, 12)),

              // ── Items ──
              _itemsCard(context),

              SizedBox(height: _Resp.s(context, 12)),

              // ── Totals ──
              _totalsCard(context),

              // ── Address (conditional, same check) ──
              if (order.address != null) ...[
                SizedBox(height: _Resp.s(context, 12)),
                _addressCard(context),
              ],

              SizedBox(height: _Resp.s(context, 20)),

              // ── Cancel (pending) ──
              if (order.status == OrderStatus.pending)
                CustomButton(
                  label: 'Cancel order',
                  outlined: true,
                  onPressed: () async {
                    final ok =
                    await OrdersViewModel().cancelOrder(order);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                ok ? 'Order cancelled' : 'Cannot cancel')),
                      );
                    }
                  },
                ),

              // ── Reorder + Feedback (completed) ──
              if (order.status == OrderStatus.completed) ...[
                CustomButton(
                  label: 'Reorder',
                  icon: Icons.replay,
                  onPressed: () {
                    context
                        .read<CartViewModel>()
                        .replaceAll(order.items);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Items added to cart')),
                    );
                  },
                ),
                SizedBox(height: _Resp.s(context, 8)),
                CustomButton(
                  label: 'Give feedback',
                  icon: Icons.star_outline,
                  outlined: true,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackScreen(order: order),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APPBAR — gradient, matches the rest of the app
  // ------------------------------------------------------------
  // Title shows the same `'Order ${order.orderNo}'` string.
  // ============================================================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final titleRowH = _Resp.s(context, 56);
    final totalH = topPad + titleRowH;

    return PreferredSize(
      preferredSize: Size.fromHeight(totalH),
      child: Container(
        height: totalH,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_Palette.headerStart, _Palette.headerEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(_Resp.s(context, 24)),
          ),
          boxShadow: [
            BoxShadow(
              color: _Palette.headerEndA35,
              blurRadius: _Resp.s(context, 14),
              offset: Offset(0, _Resp.s(context, 6)),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _Resp.contentWidth(context),
              ),
              child: SizedBox(
                height: titleRowH,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _Resp.s(context, 8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: _Resp.s(context, 20),
                        ),
                        splashRadius: _Resp.s(context, 22),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: _Resp.s(context, 4),
                            right: _Resp.s(context, 8),
                          ),
                          child: Text(
                            'Order ${order.orderNo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _Resp.t(context, 18),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CARD — same status string + same color logic
  // ============================================================
  Widget _statusCard(BuildContext context) {
    final isPending = order.status == OrderStatus.pending;
    final valueColor = isPending
        ? Colors.orange.shade800
        : AppColors.success;

    return _card(
      context,
      icon: Icons.local_shipping_outlined,
      title: 'Status',
      value: order.status.replaceAll('_', ' ').toUpperCase(),
      valueColor: valueColor,
    );
  }

  // ============================================================
  // PLACED ON CARD — date + time the order was placed
  // ------------------------------------------------------------
  // Uses the same Formatters.date() method the Orders list uses.
  // ============================================================
  Widget _placedOnCard(BuildContext context) {
    return _card(
      context,
      icon: Icons.schedule_outlined,
      title: 'Placed on',
      value: Formatters.date(order.createdAt),
    );
  }

  // ============================================================
  // ITEMS CARD — same data read (order.items), rendered as rows
  // ============================================================
  Widget _itemsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_Resp.s(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA04,
            blurRadius: _Resp.s(context, 10),
            offset: Offset(0, _Resp.s(context, 4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _iconChip(context, Icons.shopping_bag_outlined),
              SizedBox(width: _Resp.s(context, 8)),
              Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  fontSize: _Resp.t(context, 12),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: _Resp.s(context, 12)),

          // Items list — same data as the original joined string
          ...order.items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final isLast = i == order.items.length - 1;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: _Resp.s(context, 6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quantity badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _Resp.s(context, 8),
                          vertical: _Resp.s(context, 3),
                        ),
                        decoration: BoxDecoration(
                          color: _Palette.accentA10,
                          borderRadius:
                          BorderRadius.circular(_Resp.s(context, 6)),
                        ),
                        child: Text(
                          '${item.quantity}×',
                          style: TextStyle(
                            color: _Palette.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: _Resp.t(context, 12),
                          ),
                        ),
                      ),
                      SizedBox(width: _Resp.s(context, 10)),
                      Expanded(
                        child: Text(
                          item.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _Resp.t(context, 13.5),
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(width: _Resp.s(context, 8)),
                      Text(
                        Formatters.price(item.lineTotal),
                        style: TextStyle(
                          fontSize: _Resp.t(context, 13.5),
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: _Palette.divider,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // TOTALS CARD — same 4 values read from order
  // ============================================================
  Widget _totalsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_Resp.s(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA04,
            blurRadius: _Resp.s(context, 10),
            offset: Offset(0, _Resp.s(context, 4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _iconChip(context, Icons.receipt_long_outlined),
              SizedBox(width: _Resp.s(context, 8)),
              Text(
                'Totals',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  fontSize: _Resp.t(context, 12),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: _Resp.s(context, 14)),

          _totalRow(context, 'Subtotal',
              Formatters.price(order.subtotal)),
          SizedBox(height: _Resp.s(context, 8)),
          _totalRow(context, 'Discount',
              '-${Formatters.price(order.discount)}',
              valueColor: order.discount > 0
                  ? AppColors.success
                  : null),
          SizedBox(height: _Resp.s(context, 8)),
          _totalRow(context, 'Delivery',
              Formatters.price(order.deliveryFee)),

          Padding(
            padding: EdgeInsets.symmetric(
              vertical: _Resp.s(context, 12),
            ),
            child: Divider(height: 1, color: _Palette.divider),
          ),

          _totalRow(
            context,
            'Total',
            Formatters.price(order.total),
            bold: true,
            valueColor: _Palette.accent,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
      BuildContext context,
      String label,
      String value, {
        bool bold = false,
        Color? valueColor,
      }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _Resp.t(context, bold ? 14.5 : 13),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: bold ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: _Resp.t(context, bold ? 16 : 13),
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADDRESS CARD — shows profile address + coordinates
  // ============================================================
  Widget _addressCard(BuildContext context) {
    final addr = order.address!;
    final hasCoords = addr.lat != 0.0 || addr.lng != 0.0;

    // Cardinal directions based on sign
    final latDir = addr.lat >= 0 ? 'N' : 'S';
    final lngDir = addr.lng >= 0 ? 'E' : 'W';
    final coordsText =
        '${addr.lat.abs().toStringAsFixed(5)}° $latDir, '
        '${addr.lng.abs().toStringAsFixed(5)}° $lngDir';

    return Container(
      padding: EdgeInsets.all(_Resp.s(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA04,
            blurRadius: _Resp.s(context, 10),
            offset: Offset(0, _Resp.s(context, 4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _iconChip(context, Icons.location_on_outlined),
              SizedBox(width: _Resp.s(context, 8)),
              Text(
                'Delivery address',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  fontSize: _Resp.t(context, 12),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: _Resp.s(context, 10)),

          // Label chip (Home / Work / etc.)
          if (addr.label.trim().isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _Resp.s(context, 8),
                vertical: _Resp.s(context, 3),
              ),
              decoration: BoxDecoration(
                color: _Palette.accentA10,
                borderRadius: BorderRadius.circular(_Resp.s(context, 6)),
              ),
              child: Text(
                addr.label.toUpperCase(),
                style: TextStyle(
                  color: _Palette.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: _Resp.t(context, 10),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            SizedBox(height: _Resp.s(context, 8)),
          ],

          // Full address from profile
          Text(
            addr.fullAddress,
            style: TextStyle(
              fontSize: _Resp.t(context, 14),
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),

          // Coordinates where order was placed
          if (hasCoords) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: _Resp.s(context, 12),
              ),
              child: Divider(height: 1, color: _Palette.divider),
            ),

            Row(
              children: [
                Icon(
                  Icons.my_location_rounded,
                  color: _Palette.accent,
                  size: _Resp.s(context, 14),
                ),
                SizedBox(width: _Resp.s(context, 6)),
                Text(
                  'Location when order was placed',
                  style: TextStyle(
                    fontSize: _Resp.t(context, 11.5),
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: _Resp.s(context, 6)),

            Text(
              coordsText,
              style: TextStyle(
                fontSize: _Resp.t(context, 13.5),
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SHARED CARD — same (icon, title, value) shape as original
  // ============================================================
  Widget _card(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        Color? valueColor,
      }) {
    return Container(
      padding: EdgeInsets.all(_Resp.s(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA04,
            blurRadius: _Resp.s(context, 10),
            offset: Offset(0, _Resp.s(context, 4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconChip(context, icon),
              SizedBox(width: _Resp.s(context, 8)),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  fontSize: _Resp.t(context, 12),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: _Resp.s(context, 10)),
          Text(
            value,
            style: TextStyle(
              fontSize: _Resp.t(context, 14),
              color: valueColor ?? AppColors.textDark,
              fontWeight:
              valueColor != null ? FontWeight.w800 : FontWeight.w500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ICON CHIP — accent-tinted background behind small card icons
  // ============================================================
  Widget _iconChip(BuildContext context, IconData icon) {
    final size = _Resp.s(context, 28);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _Palette.accentA08,
        borderRadius: BorderRadius.circular(_Resp.s(context, 8)),
      ),
      child: Icon(
        icon,
        size: _Resp.s(context, 16),
        color: _Palette.accent,
      ),
    );
  }
}