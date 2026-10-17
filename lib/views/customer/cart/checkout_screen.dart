import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/collections.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../models/address_model.dart';
import '../../../models/order_model.dart';
import '../../../models/voucher_model.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import 'order_placed_screen.dart';

// ============================================================
// RESPONSIVE SCALING HELPERS
// ============================================================
class _Resp {
  static const double _base = 390.0;

  static double _w(BuildContext c) => MediaQuery.sizeOf(c).width;

  static double scale(BuildContext c) => (_w(c) / _base).clamp(0.82, 1.30);
  static double textScale(BuildContext c) =>
      (_w(c) / _base).clamp(0.88, 1.18);

  static double s(BuildContext c, double v) => v * scale(c);
  static double t(BuildContext c, double v) => v * textScale(c);
}

// ============================================================
// LOCAL PALETTE (mirrors HomeScreen)
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF6B35);
  static const accentDeep = Color(0xFFE85A2B);

  static final accentA30 = accent.withOpacity(0.30);
  static final accentA15 = accent.withOpacity(0.15);
  static final accentA10 = accent.withOpacity(0.10);
  static final accentA08 = accent.withOpacity(0.08);
  static final accentBorder = accent.withOpacity(0.25);
  static final headerEndA35 = headerEnd.withOpacity(0.35);
  static final blackA04 = Colors.black.withOpacity(0.04);
  static final blackA05 = Colors.black.withOpacity(0.05);
}

// ============================================================
// SESSION HOLDER — persists voucher across screen re-entries
// ------------------------------------------------------------
// In-memory only (survives push/pop within the app session).
// Cleared automatically after an order is placed.
// ============================================================
class _CheckoutSession {
  static VoucherModel? voucher;
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _orderType = OrderType.delivery;
  String _payment = PaymentMethod.cod;

  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _voucherCtrl = TextEditingController();

  VoucherModel? _appliedVoucher;
  double _deliveryFee = 40;
  bool _placing = false;

  // ── Current location ──
  Position? _currentPosition;
  bool _fetchingLocation = false;
  String? _locationError;

  // ── Available vouchers (loaded on demand) ──
  bool _loadingVouchers = false;

  // ── Restaurant coordinates (from Google Maps share link) ──
  static const double _restaurantLat = 30.6731918;
  static const double _restaurantLng = 73.0920935;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _phone.text = user?.phone ?? '';
    _address.text = user?.defaultAddress?.fullAddress ?? '';

    // ── Restore voucher from previous visit in this session ──
    _appliedVoucher = _CheckoutSession.voucher;
    if (_appliedVoucher != null) {
      _voucherCtrl.text = _appliedVoucher!.code;
    }

    _loadDeliveryFee();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentLocation();
    });
  }

  // ── IDENTICAL to original ──
  Future<void> _loadDeliveryFee() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FireCollections.settings)
          .doc(FireCollections.settingsStoreDoc)
          .get();
      if (doc.exists && mounted) {
        final fee = (doc.data()?['deliveryFee'] ?? 40).toDouble();
        setState(() => _deliveryFee = fee);
      }
    } catch (_) {
      // keep default
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _voucherCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================
  Future<void> _fetchCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _fetchingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _fetchingLocation = false;
            _locationError = 'Location services disabled';
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _fetchingLocation = false;
            _locationError = 'Location permission denied';
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _fetchingLocation = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _fetchingLocation = false;
          _locationError = 'Could not fetch location';
        });
      }
    }
  }

  String get _locationDisplay {
    if (_locationError != null) return _locationError!;
    if (_currentPosition == null) return 'Location unavailable';
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(5)}° $latDir, '
        '${lng.abs().toStringAsFixed(5)}° $lngDir';
  }

  // ============================================================
  // OPEN USER'S CURRENT LOCATION IN GOOGLE MAPS
  // ============================================================
  Future<void> _openCurrentLocationInMaps() async {
    // Prefer the fetched GPS coordinates if available.
    if (_currentPosition != null) {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
      return;
    }

    // Fallback: use the typed delivery address.
    final address = _address.text.trim();
    if (address.isNotEmpty) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('No location available. Please fetch your location first.'),
        ),
      );
    }
  }

  // ============================================================
  // OPEN RESTAURANT LOCATION IN GOOGLE MAPS
  // ============================================================
  Future<void> _openRestaurantLocationInMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_restaurantLat,$_restaurantLng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  // ============================================================
  // VOUCHER — apply / remove / persist
  // ============================================================
  // ── IDENTICAL to original: manual code entry ──
  Future<void> _applyVoucher() async {
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection(FireCollections.vouchers)
        .doc(code)
        .get();
    if (!doc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid voucher')));
      }
      return;
    }
    final v = VoucherModel.fromMap(doc.id, doc.data()!);
    if (!mounted) return;
    if (!v.isActive) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Voucher is not active')));
      return;
    }
    _setAppliedVoucher(v);
  }

  /// Apply a voucher that was already loaded (from the sheet).
  void _applyVoucherModel(VoucherModel v) {
    _voucherCtrl.text = v.code;
    _setAppliedVoucher(v);
  }

  void _setAppliedVoucher(VoucherModel v) {
    setState(() {
      _appliedVoucher = v;
      _CheckoutSession.voucher = v;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher "${v.code}" applied'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Remove the applied voucher. Restores state to "no voucher".
  void _removeVoucher() {
    setState(() {
      _appliedVoucher = null;
      _CheckoutSession.voucher = null;
      _voucherCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voucher removed'),
        duration: Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Load active vouchers from Firestore, then open the picker sheet.
  Future<void> _showAvailableVouchers(double subtotal) async {
    setState(() => _loadingVouchers = true);

    List<VoucherModel> vouchers = [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection(FireCollections.vouchers)
          .get();
      vouchers = snap.docs
          .map((d) => VoucherModel.fromMap(d.id, d.data()))
          .where((v) => v.isActive)
          .toList();
    } catch (_) {
      // keep empty
    }

    if (!mounted) return;
    setState(() => _loadingVouchers = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildVouchersSheet(
        sheetContext,
        vouchers,
        subtotal,
      ),
    );
  }

  // ============================================================
  // VOUCHERS SHEET
  // ============================================================
  Widget _buildVouchersSheet(
      BuildContext sheetContext,
      List<VoucherModel> vouchers,
      double subtotal,
      ) {
    final maxH = MediaQuery.sizeOf(sheetContext).height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_Resp.s(sheetContext, 24)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: EdgeInsets.only(
                top: _Resp.s(sheetContext, 12),
                bottom: _Resp.s(sheetContext, 6),
              ),
              child: Container(
                width: _Resp.s(sheetContext, 44),
                height: _Resp.s(sheetContext, 4),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(
                      _Resp.s(sheetContext, 2)),
                ),
              ),
            ),

            // Title row
            Padding(
              padding: EdgeInsets.fromLTRB(
                _Resp.s(sheetContext, 20),
                _Resp.s(sheetContext, 10),
                _Resp.s(sheetContext, 12),
                _Resp.s(sheetContext, 4),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_Resp.s(sheetContext, 8)),
                    decoration: BoxDecoration(
                      color: _Palette.accentA10,
                      borderRadius: BorderRadius.circular(
                          _Resp.s(sheetContext, 10)),
                    ),
                    child: Icon(
                      Icons.local_offer_rounded,
                      color: _Palette.accent,
                      size: _Resp.s(sheetContext, 18),
                    ),
                  ),
                  SizedBox(width: _Resp.s(sheetContext, 10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available vouchers',
                          style: TextStyle(
                            fontSize: _Resp.t(sheetContext, 17),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: _Resp.s(sheetContext, 2)),
                        Text(
                          'Tap a voucher to apply it instantly',
                          style: TextStyle(
                            fontSize: _Resp.t(sheetContext, 11.5),
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textLight,
                      size: _Resp.s(sheetContext, 22),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppColors.divider),

            // Body
            Flexible(
              child: vouchers.isEmpty
                  ? _emptyVouchers(sheetContext)
                  : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  _Resp.s(sheetContext, 16),
                  _Resp.s(sheetContext, 14),
                  _Resp.s(sheetContext, 16),
                  _Resp.s(sheetContext, 20),
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: vouchers.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: _Resp.s(sheetContext, 10)),
                itemBuilder: (_, i) {
                  final v = vouchers[i];
                  final saving = v.compute(subtotal);
                  return _voucherCard(
                    sheetContext,
                    v,
                    saving,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _applyVoucherModel(v);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyVouchers(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _Resp.s(context, 32),
        _Resp.s(context, 40),
        _Resp.s(context, 32),
        _Resp.s(context, 48),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _Resp.s(context, 72),
            height: _Resp.s(context, 72),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Palette.accentA10,
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: _Palette.accent,
              size: _Resp.s(context, 32),
            ),
          ),
          SizedBox(height: _Resp.s(context, 16)),
          Text(
            'No vouchers right now',
            style: TextStyle(
              fontSize: _Resp.t(context, 15),
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: _Resp.s(context, 6)),
          Text(
            "Check back later — we add new deals often!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _Resp.t(context, 12.5),
              color: AppColors.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _voucherCard(
      BuildContext context,
      VoucherModel v,
      double saving, {
        required VoidCallback onTap,
      }) {
    final hasSaving = saving > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(_Resp.s(context, 14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
            border: Border.all(
              color: _Palette.accentBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _Palette.blackA04,
                blurRadius: _Resp.s(context, 10),
                offset: Offset(0, _Resp.s(context, 4)),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ticket icon
              Container(
                width: _Resp.s(context, 46),
                height: _Resp.s(context, 46),
                decoration: BoxDecoration(
                  color: _Palette.accentA10,
                  borderRadius:
                  BorderRadius.circular(_Resp.s(context, 12)),
                ),
                child: Icon(
                  Icons.local_activity_rounded,
                  color: _Palette.accent,
                  size: _Resp.s(context, 24),
                ),
              ),
              SizedBox(width: _Resp.s(context, 12)),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _Resp.t(context, 15),
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 4)),
                    Text(
                      hasSaving
                          ? 'Save ${Formatters.price(saving)} on this order'
                          : 'Min. order value not met',
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: _Resp.t(context, 11.5),
                        fontWeight: FontWeight.w600,
                        color: hasSaving
                            ? AppColors.success
                            : AppColors.textLight,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _Resp.s(context, 8)),

              // Apply chip
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _Resp.s(context, 12),
                  vertical: _Resp.s(context, 8),
                ),
                decoration: BoxDecoration(
                  color: hasSaving
                      ? _Palette.accent
                      : _Palette.accentA10,
                  borderRadius:
                  BorderRadius.circular(_Resp.s(context, 20)),
                ),
                child: Text(
                  'APPLY',
                  style: TextStyle(
                    color: hasSaving ? Colors.white : _Palette.accent,
                    fontSize: _Resp.t(context, 10.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // _placeOrder — original logic + session clear on success
  // ============================================================
  Future<void> _placeOrder() async {
    final auth = context.read<AuthViewModel>().currentUser;
    final cart = context.read<CartViewModel>();

    if (auth == null) return;

    if (_orderType == OrderType.delivery &&
        (Validators.required(_address.text) != null ||
            Validators.phone(_phone.text) != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Address and phone required for delivery')),
      );
      return;
    }

    setState(() => _placing = true);

    try {
      final subtotal = cart.subtotal;
      final discount = _appliedVoucher?.compute(subtotal) ?? 0.0;
      final deliveryFee =
      _orderType == OrderType.delivery ? _deliveryFee : 0.0;
      final total = subtotal - discount + deliveryFee;

      final counterRef = FirebaseFirestore.instance
          .collection('counters')
          .doc('orders');

      final orderRef = FirebaseFirestore.instance
          .collection(FireCollections.pendingOrders)
          .doc();

      final orderNo = await FirebaseFirestore.instance
          .runTransaction<String>((tx) async {
        final snap = await tx.get(counterRef);
        final next = ((snap.data()?['last'] ?? 1000) as int) + 1;
        tx.set(counterRef, {'last': next}, SetOptions(merge: true));
        return '#$next';
      });

      final order = OrderModel(
        id: orderRef.id,
        orderNo: orderNo,
        customerId: auth.uid,
        customerName: auth.name,
        phone: _phone.text.trim(),
        items: cart.items,
        orderType: _orderType,
        address: _orderType == OrderType.delivery
            ? AddressModel(
          label: 'Home',
          fullAddress: _address.text.trim(),
          lat: _currentPosition?.latitude ??
              auth.defaultAddress?.lat ??
              0.0,
          lng: _currentPosition?.longitude ??
              auth.defaultAddress?.lng ??
              0.0,
          isDefault: true,
        )
            : null,
        paymentMethod: _payment,
        paymentStatus: 'unpaid',
        subtotal: subtotal,
        discount: discount,
        deliveryFee: deliveryFee,
        total: total,
        voucherCode: _appliedVoucher?.code,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final data = order.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await orderRef.set(data);

      cart.clear();
      // ── Clear persisted voucher after successful order ──
      _CheckoutSession.voucher = null;
      _appliedVoucher = null;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderPlacedScreen(order: order)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final subtotal = cart.subtotal;
    final discount = _appliedVoucher?.compute(subtotal) ?? 0.0;
    final deliveryFee =
    _orderType == OrderType.delivery ? _deliveryFee : 0.0;
    final total = subtotal - discount + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          _Resp.s(context, 16),
          _Resp.s(context, 16),
          _Resp.s(context, 16),
          _Resp.s(context, 32),
        ),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Order Type ──
            _sectionTitle(
                context, 'Order Type', Icons.shopping_bag_outlined),
            SizedBox(height: _Resp.s(context, 10)),
            _orderTypeSelector(context),

            // ── Delivery Details ──
            if (_orderType == OrderType.delivery) ...[
              SizedBox(height: _Resp.s(context, 22)),
              _sectionTitle(context, 'Delivery Details',
                  Icons.location_on_outlined),
              SizedBox(height: _Resp.s(context, 10)),
              CustomTextField(
                controller: _phone,
                label: 'Phone',
                keyboard: TextInputType.phone,
              ),
              SizedBox(height: _Resp.s(context, 10)),
              CustomTextField(
                controller: _address,
                label: 'Delivery address',
                maxLines: 2,
              ),
              SizedBox(height: _Resp.s(context, 10)),
              _currentLocationCard(context),
              SizedBox(height: _Resp.s(context, 10)),
              // ── NEW: View user's location on Google Maps ──
              _viewMyLocationButton(context),
            ],

            // ── Takeaway: Restaurant Location ──
            if (_orderType == OrderType.takeaway) ...[
              SizedBox(height: _Resp.s(context, 22)),
              _sectionTitle(context, 'Restaurant Location',
                  Icons.storefront_outlined),
              SizedBox(height: _Resp.s(context, 10)),
              _viewRestaurantLocationButton(context),
            ],

            // ── Payment ──
            SizedBox(height: _Resp.s(context, 22)),
            _sectionTitle(
                context, 'Payment Method', Icons.payments_outlined),
            SizedBox(height: _Resp.s(context, 10)),
            _paymentSelector(context),

            // ── Voucher ──
            SizedBox(height: _Resp.s(context, 22)),
            _sectionTitle(
                context, 'Voucher', Icons.local_offer_outlined),
            SizedBox(height: _Resp.s(context, 10)),

            if (_appliedVoucher == null) ...[
              // Not applied → manual entry + browse button
              _voucherRow(context),
              SizedBox(height: _Resp.s(context, 10)),
              _browseVouchersButton(context, subtotal),
            ] else ...[
              // Applied → show card with remove
              _appliedVoucherCard(context, subtotal),
            ],

            // ── Summary ──
            SizedBox(height: _Resp.s(context, 22)),
            _sectionTitle(
                context, 'Order Summary', Icons.receipt_long_outlined),
            SizedBox(height: _Resp.s(context, 10)),
            _summaryCard(context, subtotal, discount, deliveryFee, total),

            SizedBox(height: _Resp.s(context, 24)),
            CustomButton(
              label: 'Place Order',
              loading: _placing,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NEW: "View My Location" BUTTON (Delivery)
  // ============================================================
  Widget _viewMyLocationButton(BuildContext context) {
    return GestureDetector(
      onTap: _openCurrentLocationInMaps,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _Resp.s(context, 14),
          vertical: _Resp.s(context, 13),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
          border: Border.all(
            color: _Palette.accentBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _Palette.blackA04,
              blurRadius: _Resp.s(context, 8),
              offset: Offset(0, _Resp.s(context, 3)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: _Resp.s(context, 36),
              height: _Resp.s(context, 36),
              decoration: BoxDecoration(
                color: _Palette.accentA10,
                borderRadius: BorderRadius.circular(_Resp.s(context, 10)),
              ),
              child: Icon(
                Icons.map_outlined,
                color: _Palette.accent,
                size: _Resp.s(context, 18),
              ),
            ),
            SizedBox(width: _Resp.s(context, 12)),
            Expanded(
              child: Text(
                'View your location on Google Maps',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: _Resp.t(context, 13),
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: _Palette.accent,
              size: _Resp.s(context, 16),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NEW: "View Restaurant Location" BUTTON (Takeaway)
  // ============================================================
  Widget _viewRestaurantLocationButton(BuildContext context) {
    return GestureDetector(
      onTap: _openRestaurantLocationInMaps,
      child: Container(
        padding: EdgeInsets.all(_Resp.s(context, 14)),
        decoration: BoxDecoration(
          color: _Palette.accentA08,
          borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
          border: Border.all(color: _Palette.accentBorder),
        ),
        child: Row(
          children: [
            Container(
              width: _Resp.s(context, 44),
              height: _Resp.s(context, 44),
              decoration: BoxDecoration(
                color: _Palette.accentA15,
                borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
              ),
              child: Icon(
                Icons.restaurant_outlined,
                color: _Palette.accent,
                size: _Resp.s(context, 22),
              ),
            ),
            SizedBox(width: _Resp.s(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick More Restaurant',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: _Resp.t(context, 13.5),
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: _Resp.s(context, 3)),
                  Text(
                    'Tap to view the restaurant location on Google Maps',
                    style: TextStyle(
                      fontSize: _Resp.t(context, 11.5),
                      color: AppColors.textLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _Resp.s(context, 8)),
            Icon(
              Icons.open_in_new_rounded,
              color: _Palette.accent,
              size: _Resp.s(context, 18),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // THEMED APPBAR
  // ============================================================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final barHeight = _Resp.s(context, 62);
    final canPop = Navigator.of(context).canPop();

    return PreferredSize(
      preferredSize: Size.fromHeight(
        MediaQuery.of(context).padding.top + barHeight,
      ),
      child: Container(
        height: MediaQuery.of(context).padding.top + barHeight,
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
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _Resp.s(context, 8),
              vertical: _Resp.s(context, 4),
            ),
            child: Row(
              children: [
                if (canPop)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: _Resp.s(context, 20),
                    ),
                    splashRadius: _Resp.s(context, 22),
                  )
                else
                  SizedBox(width: _Resp.s(context, 8)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: canPop
                          ? _Resp.s(context, 4)
                          : _Resp.s(context, 12),
                    ),
                    child: Text(
                      'Checkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _Resp.t(context, 20),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: _Resp.s(context, 8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================
  Widget _sectionTitle(BuildContext context, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _Palette.accent, size: _Resp.s(context, 18)),
        SizedBox(width: _Resp.s(context, 8)),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: _Resp.t(context, 15),
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ORDER TYPE SELECTOR
  // ============================================================
  Widget _orderTypeSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _selectorCard(
            context,
            selected: _orderType == OrderType.delivery,
            icon: Icons.delivery_dining_outlined,
            label: 'Delivery',
            onTap: () => setState(() => _orderType = OrderType.delivery),
          ),
        ),
        SizedBox(width: _Resp.s(context, 10)),
        Expanded(
          child: _selectorCard(
            context,
            selected: _orderType == OrderType.takeaway,
            icon: Icons.storefront_outlined,
            label: 'Takeaway',
            onTap: () => setState(() => _orderType = OrderType.takeaway),
          ),
        ),
      ],
    );
  }

  Widget _selectorCard(
      BuildContext context, {
        required bool selected,
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: _Resp.s(context, 12),
          vertical: _Resp.s(context, 14),
        ),
        decoration: BoxDecoration(
          color: selected ? _Palette.accent : Colors.white,
          borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
          border: Border.all(
            color: selected ? _Palette.accent : AppColors.divider,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: _Palette.accentA30,
              blurRadius: _Resp.s(context, 12),
              offset: Offset(0, _Resp.s(context, 6)),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : _Palette.accent,
              size: _Resp.s(context, 20),
            ),
            SizedBox(width: _Resp.s(context, 10)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: _Resp.t(context, 13.5),
                ),
              ),
            ),
            Container(
              width: _Resp.s(context, 18),
              height: _Resp.s(context, 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.white : AppColors.divider,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                child: Container(
                  width: _Resp.s(context, 8),
                  height: _Resp.s(context, 8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT SELECTOR
  // ============================================================
  Widget _paymentSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA04,
            blurRadius: _Resp.s(context, 10),
            offset: Offset(0, _Resp.s(context, 4)),
          ),
        ],
      ),
      child: Column(
        children: [
          _paymentOption(
            context,
            selected: _payment == PaymentMethod.cod,
            icon: Icons.money_outlined,
            label: 'Cash on Delivery',
            subtitle: 'Pay when your order arrives',
            enabled: true,
            onTap: () => setState(() => _payment = PaymentMethod.cod),
          ),
          Divider(height: 1, color: AppColors.divider),
          _paymentOption(
            context,
            selected: false,
            icon: Icons.credit_card_outlined,
            label: 'Online Payment',
            subtitle: 'Card, wallet & more',
            enabled: false,
            badge: 'COMING SOON',
            onTap: _showOnlineComingSoon,
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(
      BuildContext context, {
        required bool selected,
        required IconData icon,
        required String label,
        required String subtitle,
        required bool enabled,
        required VoidCallback onTap,
        String? badge,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _Resp.s(context, 14),
            vertical: _Resp.s(context, 14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled ? _Palette.accent : AppColors.textLight,
                size: _Resp.s(context, 20),
              ),
              SizedBox(width: _Resp.s(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: enabled
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: _Resp.t(context, 13.5),
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          SizedBox(width: _Resp.s(context, 8)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _Resp.s(context, 6),
                              vertical: _Resp.s(context, 2),
                            ),
                            decoration: BoxDecoration(
                              color: _Palette.accentA10,
                              borderRadius: BorderRadius.circular(
                                  _Resp.s(context, 6)),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: _Palette.accent,
                                fontSize: _Resp.t(context, 8),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: _Resp.s(context, 2)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: _Resp.t(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: _Resp.s(context, 20),
                height: _Resp.s(context, 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? _Palette.accent
                        : AppColors.divider,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                  child: Container(
                    width: _Resp.s(context, 10),
                    height: _Resp.s(context, 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _Palette.accent,
                    ),
                  ),
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ONLINE PAYMENT SHEET
  // ============================================================
  void _showOnlineComingSoon() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
          _Resp.s(context, 20),
          _Resp.s(context, 16),
          _Resp.s(context, 20),
          _Resp.s(context, 24),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_Resp.s(context, 24)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _Resp.s(context, 44),
                height: _Resp.s(context, 4),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(_Resp.s(context, 2)),
                ),
              ),
              SizedBox(height: _Resp.s(context, 20)),
              Container(
                width: _Resp.s(context, 76),
                height: _Resp.s(context, 76),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Palette.accentA10,
                ),
                child: Icon(
                  Icons.credit_card_off_outlined,
                  color: _Palette.accent,
                  size: _Resp.s(context, 36),
                ),
              ),
              SizedBox(height: _Resp.s(context, 16)),
              Text(
                'Online payment coming soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _Resp.t(context, 17),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: _Resp.s(context, 8)),
              Text(
                "We're still building card & wallet payments. "
                    "For now, please select Cash on Delivery.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _Resp.t(context, 13),
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
              SizedBox(height: _Resp.s(context, 20)),
              SizedBox(
                width: double.infinity,
                height: _Resp.s(context, 50),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(_Resp.s(context, 14)),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: _Resp.t(context, 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT LOCATION CARD
  // ============================================================
  Widget _currentLocationCard(BuildContext context) {
    final hasError = _locationError != null;
    final dotColor = hasError
        ? Colors.orange
        : (_fetchingLocation ? Colors.amber : AppColors.success);

    return Container(
      padding: EdgeInsets.all(_Resp.s(context, 14)),
      decoration: BoxDecoration(
        color: _Palette.accentA08,
        borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
        border: Border.all(color: _Palette.accentBorder),
      ),
      child: Row(
        children: [
          Container(
            width: _Resp.s(context, 40),
            height: _Resp.s(context, 40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Palette.accentA15,
            ),
            child: _fetchingLocation
                ? Padding(
              padding: EdgeInsets.all(_Resp.s(context, 10)),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                AlwaysStoppedAnimation(Color(0xFFFF6B35)),
              ),
            )
                : Icon(
              hasError
                  ? Icons.location_off_outlined
                  : Icons.my_location_rounded,
              color: _Palette.accent,
              size: _Resp.s(context, 20),
            ),
          ),
          SizedBox(width: _Resp.s(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Current location',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: _Resp.t(context, 12.5),
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(width: _Resp.s(context, 6)),
                    Container(
                      width: _Resp.s(context, 6),
                      height: _Resp.s(context, 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _Resp.s(context, 3)),
                Text(
                  _fetchingLocation
                      ? 'Fetching your location…'
                      : _locationDisplay,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _Resp.t(context, 11.5),
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: _Resp.s(context, 8)),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_Resp.s(context, 10)),
            child: InkWell(
              borderRadius: BorderRadius.circular(_Resp.s(context, 10)),
              onTap: _fetchingLocation ? null : _fetchCurrentLocation,
              child: Padding(
                padding: EdgeInsets.all(_Resp.s(context, 8)),
                child: Icon(
                  Icons.refresh_rounded,
                  color: _Palette.accent,
                  size: _Resp.s(context, 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VOUCHER — manual entry row (unchanged layout)
  // ============================================================
  Widget _voucherRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomTextField(
            controller: _voucherCtrl,
            label: 'Voucher code',
          ),
        ),
        SizedBox(width: _Resp.s(context, 8)),
        Padding(
          padding: EdgeInsets.only(top: _Resp.s(context, 2)),
          child: SizedBox(
            height: _Resp.s(context, 52),
            child: ElevatedButton(
              onPressed: _applyVoucher,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: _Resp.s(context, 20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(_Resp.s(context, 12)),
                ),
              ),
              child: Text(
                'Apply',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: _Resp.t(context, 13.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VOUCHER — "Browse available" button
  // ============================================================
  Widget _browseVouchersButton(BuildContext context, double subtotal) {
    return GestureDetector(
      onTap: _loadingVouchers
          ? null
          : () => _showAvailableVouchers(subtotal),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _Resp.s(context, 14),
          vertical: _Resp.s(context, 14),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
          border: Border.all(
            color: _Palette.accentBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _Palette.blackA04,
              blurRadius: _Resp.s(context, 10),
              offset: Offset(0, _Resp.s(context, 4)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: _Resp.s(context, 40),
              height: _Resp.s(context, 40),
              decoration: BoxDecoration(
                color: _Palette.accentA10,
                borderRadius: BorderRadius.circular(_Resp.s(context, 10)),
              ),
              child: _loadingVouchers
                  ? Padding(
                padding: EdgeInsets.all(_Resp.s(context, 10)),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation(Color(0xFFFF6B35)),
                ),
              )
                  : Icon(
                Icons.local_activity_rounded,
                color: _Palette.accent,
                size: _Resp.s(context, 20),
              ),
            ),
            SizedBox(width: _Resp.s(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse available vouchers',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: _Resp.t(context, 13.5),
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: _Resp.s(context, 2)),
                  Text(
                    'See active deals and apply instantly',
                    style: TextStyle(
                      fontSize: _Resp.t(context, 11.5),
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _Palette.accent,
              size: _Resp.s(context, 14),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VOUCHER — applied card with remove option
  // ============================================================
  Widget _appliedVoucherCard(BuildContext context, double subtotal) {
    final saving = _appliedVoucher!.compute(subtotal);

    return Container(
      padding: EdgeInsets.all(_Resp.s(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
        border: Border.all(
          color: AppColors.success.withOpacity(0.45),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.10),
            blurRadius: _Resp.s(context, 12),
            offset: Offset(0, _Resp.s(context, 4)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: _Resp.s(context, 46),
            height: _Resp.s(context, 46),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: _Resp.s(context, 24),
            ),
          ),
          SizedBox(width: _Resp.s(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _appliedVoucher!.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: _Resp.t(context, 15),
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    SizedBox(width: _Resp.s(context, 8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _Resp.s(context, 6),
                        vertical: _Resp.s(context, 2),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius:
                        BorderRadius.circular(_Resp.s(context, 6)),
                      ),
                      child: Text(
                        'APPLIED',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: _Resp.t(context, 8),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _Resp.s(context, 4)),
                Text(
                  saving > 0
                      ? 'You save ${Formatters.price(saving)} on this order'
                      : 'Voucher applied to your order',
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: _Resp.t(context, 11.5),
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: _Resp.s(context, 8)),
          // Remove button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_Resp.s(context, 10)),
            child: InkWell(
              borderRadius: BorderRadius.circular(_Resp.s(context, 10)),
              onTap: _removeVoucher,
              child: Container(
                padding: EdgeInsets.all(_Resp.s(context, 8)),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(_Resp.s(context, 10)),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red.shade400,
                  size: _Resp.s(context, 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================
  Widget _summaryCard(
      BuildContext context,
      double subtotal,
      double discount,
      double deliveryFee,
      double total,
      ) {
    return Container(
      padding: EdgeInsets.all(_Resp.s(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA05,
            blurRadius: _Resp.s(context, 12),
            offset: Offset(0, _Resp.s(context, 4)),
          ),
        ],
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal', Formatters.price(subtotal)),
          SizedBox(height: _Resp.s(context, 8)),
          _row(
            context,
            'Discount',
            '- ${Formatters.price(discount)}',
            valueColor: discount > 0 ? AppColors.success : null,
          ),
          SizedBox(height: _Resp.s(context, 8)),
          _row(context, 'Delivery fee', Formatters.price(deliveryFee)),
          Padding(
            padding: EdgeInsets.symmetric(vertical: _Resp.s(context, 12)),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _row(
            context,
            'Total',
            Formatters.price(total),
            bold: true,
            valueColor: _Palette.accent,
          ),
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context,
      String k,
      String v, {
        bool bold = false,
        Color? valueColor,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          k,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: _Resp.t(context, bold ? 15 : 13.5),
            color: bold ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        Text(
          v,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            fontSize: _Resp.t(context, bold ? 17 : 13.5),
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}