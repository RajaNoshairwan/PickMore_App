import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/customer/orders_viewmodel.dart';
import 'order_detail_screen.dart';

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
  static final whiteA18 = Colors.white.withOpacity(0.18);
  static final whiteA35 = Colors.white.withOpacity(0.35);
  static final blackA10 = Colors.black.withOpacity(0.10);
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrdersViewModel _vm = OrdersViewModel();

  // ── View state ──
  // `_past`     → Past segment selected
  // `_cancelled` → Cancelled toggle active (overrides segments)
  bool _past = false;
  bool _cancelled = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final uid = context.read<AuthViewModel>().currentUser?.uid;
      if (uid != null) _vm.load(uid);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  // ============================================================
  // TIMESTAMP FORMATTER — "4:30 PM • 13 Oct 2026"
  // ------------------------------------------------------------
  // Builds the entire string itself so we don't double-up on
  // Formatters.date()'s existing time part. No dependency on any
  // other formatter for the layout — clean and predictable.
  // ============================================================
  String _formatTimestamp(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h24 = dt.hour;
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    final month = months[dt.month - 1];
    return '$h12:$min $ampm • ${dt.day} $month ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final uid = auth.currentUser?.uid;

    // ── SIGNED-OUT STATE ──
    if (auth.currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(
          context,
          title: 'Orders',
          showSegment: false,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(_Resp.s(context, 24)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _Resp._maxContentWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: _Resp.s(context, 120),
                      height: _Resp.s(context, 120),
                      decoration: BoxDecoration(
                        color: _Palette.accentA08,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: _Resp.s(context, 60),
                        color: _Palette.accent,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 20)),
                    Text(
                      'Sign in to view orders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _Resp.t(context, 18),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 6)),
                    Text(
                      'Your orders will appear here once you sign in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: _Resp.t(context, 13.5),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 20)),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<AuthViewModel>().signOut(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: _Resp.s(context, 28),
                          vertical: _Resp.s(context, 14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(_Resp.s(context, 12)),
                        ),
                      ),
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: _Resp.t(context, 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── SIGNED-IN STATE ──
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(
          context,
          title: 'My Orders',
          showSegment: true,
        ),
        body: Consumer<OrdersViewModel>(
          builder: (context, vm, _) {
            if (vm.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            // ── Pick the list based on current view ──
            final List list = _cancelled
                ? vm.pastOrders
                .where((o) =>
                o.status.toLowerCase().contains('cancel'))
                .toList()
                : (_past ? vm.pastOrders : vm.activeOrders);

            if (list.isEmpty) {
              return EmptyState(
                message: _cancelled
                    ? 'No cancelled orders'
                    : (_past
                    ? 'No past orders yet'
                    : 'No active orders right now'),
                icon: _cancelled
                    ? Icons.cancel_outlined
                    : Icons.receipt_long,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (uid != null) await vm.load(uid);
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _Resp.contentWidth(context),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      _Resp.hPad(context),
                      _Resp.s(context, 12),
                      _Resp.hPad(context),
                      _Resp.s(context, 24),
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (_, i) => FadeSlideIn(
                      delay: Duration(milliseconds: 40 * i),
                      child: _orderCard(list[i], uid, vm),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // APPBAR — exact fixed heights so preferredSize === rendered
  // height. Title row now has the "Cancelled" toggle at the
  // top-right (only shown when segments are visible).
  // ============================================================
  PreferredSizeWidget _buildAppBar(
      BuildContext context, {
        required String title,
        required bool showSegment,
      }) {
    final topPad = MediaQuery.of(context).padding.top;

    final titleRowH = _Resp.s(context, 52);
    final gapH = _Resp.s(context, 8);
    final segH = _Resp.s(context, 44);
    final bottomPad = _Resp.s(context, 14);

    final innerH =
        titleRowH + (showSegment ? (gapH + segH) : 0) + bottomPad;
    final totalH = topPad + innerH;

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
              child: Column(
                children: [
                  // ── Title row + Cancelled toggle ──
                  SizedBox(
                    height: titleRowH,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _Resp.s(context, 20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _Resp.t(context, 20),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          if (showSegment) _cancelledToggle(context),
                        ],
                      ),
                    ),
                  ),

                  // ── Segment strip ──
                  if (showSegment) ...[
                    SizedBox(height: gapH),
                    SizedBox(
                      height: segH,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _Resp.s(context, 16),
                        ),
                        child: Row(
                          children: [
                            _segment(
                              context,
                              'Active',
                              !_past && !_cancelled,
                                  () => setState(() {
                                _past = false;
                                _cancelled = false;
                              }),
                            ),
                            SizedBox(width: _Resp.s(context, 10)),
                            _segment(
                              context,
                              'Past',
                              _past && !_cancelled,
                                  () => setState(() {
                                _past = true;
                                _cancelled = false;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: bottomPad),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CANCELLED TOGGLE — short pill at top-right of the AppBar
  // ------------------------------------------------------------
  // Tap → toggle the cancelled view. When active, it goes solid
  // white (matches segment styling) so the user sees the state.
  // ============================================================
  Widget _cancelledToggle(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() {
        _cancelled = !_cancelled;
        if (_cancelled) _past = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: _Resp.s(context, 10),
          vertical: _Resp.s(context, 6),
        ),
        decoration: BoxDecoration(
          color: _cancelled ? Colors.white : _Palette.whiteA18,
          borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
          border: Border.all(
            color: _cancelled ? Colors.white : _Palette.whiteA35,
            width: _cancelled ? 1.4 : 1.0,
          ),
          boxShadow: _cancelled
              ? [
            BoxShadow(
              color: _Palette.blackA10,
              blurRadius: _Resp.s(context, 10),
              offset: Offset(0, _Resp.s(context, 4)),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cancel_outlined,
              size: _Resp.s(context, 13),
              color: _cancelled ? _Palette.accent : Colors.white,
            ),
            SizedBox(width: _Resp.s(context, 5)),
            Text(
              'Cancelled',
              style: TextStyle(
                color: _cancelled ? _Palette.accent : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: _Resp.t(context, 11.5),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEGMENT (Active / Past)
  // ============================================================
  Widget _segment(
      BuildContext context,
      String label,
      bool selected,
      VoidCallback onTap,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : _Palette.whiteA18,
            borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
            border: Border.all(
              color: selected ? Colors.white : _Palette.whiteA35,
              width: selected ? 1.4 : 1.0,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: _Palette.blackA10,
                blurRadius: _Resp.s(context, 10),
                offset: Offset(0, _Resp.s(context, 4)),
              ),
            ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _Palette.accent : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: _Resp.t(context, 13.5),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================
  Widget _orderCard(dynamic o, String? uid, OrdersViewModel vm) {
    return Padding(
      padding: EdgeInsets.only(bottom: _Resp.s(context, 12)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_Resp.s(context, 18)),
          boxShadow: [
            BoxShadow(
              color: _Palette.blackA04,
              blurRadius: _Resp.s(context, 12),
              offset: Offset(0, _Resp.s(context, 6)),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_Resp.s(context, 18)),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(order: o)),
              );
              if (uid != null) vm.load(uid);
            },
            borderRadius: BorderRadius.circular(_Resp.s(context, 18)),
            child: Padding(
              padding: EdgeInsets.all(_Resp.s(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: _Resp.s(context, 36),
                        height: _Resp.s(context, 36),
                        decoration: BoxDecoration(
                          color: _Palette.accentA10,
                          borderRadius:
                          BorderRadius.circular(_Resp.s(context, 10)),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: _Palette.accent,
                          size: _Resp.s(context, 18),
                        ),
                      ),
                      SizedBox(width: _Resp.s(context, 10)),
                      Expanded(
                        child: Text(
                          o.orderNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: _Resp.t(context, 15),
                            color: AppColors.textDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      SizedBox(width: _Resp.s(context, 8)),
                      _statusChip(context, o.status),
                    ],
                  ),
                  SizedBox(height: _Resp.s(context, 12)),

                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: _Resp.s(context, 14),
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: _Resp.s(context, 6)),
                      Expanded(
                        child: Text(
                          '${o.items.length} item${o.items.length > 1 ? 's' : ''} • ${o.orderType.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: _Resp.t(context, 12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _Resp.s(context, 10)),

                  Divider(height: 1, color: AppColors.divider),
                  SizedBox(height: _Resp.s(context, 10)),

                  // ── Price + Timestamp row ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          Formatters.price(o.total),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _Palette.accent,
                            fontWeight: FontWeight.w900,
                            fontSize: _Resp.t(context, 16),
                          ),
                        ),
                      ),
                      SizedBox(width: _Resp.s(context, 8)),
                      Icon(
                        Icons.access_time_rounded,
                        size: _Resp.s(context, 12),
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: _Resp.s(context, 4)),
                      Text(
                        _formatTimestamp(o.createdAt),
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: _Resp.t(context, 11),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================
  Widget _statusChip(BuildContext context, String status) {
    final lower = status.toLowerCase();
    Color bg;
    Color fg;
    if (lower.contains('pending')) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else if (lower.contains('complet') || lower.contains('deliver')) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (lower.contains('cancel') || lower.contains('reject')) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _Resp.s(context, 10),
        vertical: _Resp.s(context, 4),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_Resp.s(context, 20)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: _Resp.t(context, 10),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}