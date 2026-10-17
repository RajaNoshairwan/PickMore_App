import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/product_model.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../../../viewmodels/customer/home_viewmodel.dart';
import '../../auth/customer_login_screen.dart';
import '../home/product_detail_screen.dart';
import 'checkout_screen.dart';

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
  static final accentA10 = accent.withOpacity(0.10);
  static final accentA08 = accent.withOpacity(0.08);
  static final headerEndA35 = headerEnd.withOpacity(0.35);
  static final blackA04 = Colors.black.withOpacity(0.04);
  static final blackA05 = Colors.black.withOpacity(0.05);
  static final blackA06 = Colors.black.withOpacity(0.06);
}

class CartScreen extends StatefulWidget {
  final VoidCallback? onBrowseMenu;
  const CartScreen({super.key, this.onBrowseMenu});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final HomeViewModel _homeVm;

  @override
  void initState() {
    super.initState();
    _homeVm = HomeViewModel();
    _homeVm.loadAll();
  }

  @override
  void dispose() {
    _homeVm.dispose();
    super.dispose();
  }

  // ============================================================
  // SMART IMAGE HELPER (Handles both Local Assets and Network)
  // ============================================================
  Widget _buildSmartImage(
      BuildContext context,
      String url, {
        double? height,
        double? width,
        BoxFit fit = BoxFit.cover,
        Widget? errorWidget,
      }) {
    if (url.isEmpty) {
      return errorWidget ??
          Container(
            color: Colors.white10,
            child: const Icon(Icons.fastfood),
          );
    }

    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    int? cacheWidth = width != null ? (width * pixelRatio).round() : null;
    int? cacheHeight = height != null ? (height * pixelRatio).round() : null;

    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: width,
        fit: fit,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => ShimmerBox(
          height: height ?? 100,
          width: width,
        ),
        errorWidget: (_, __, ___) =>
        errorWidget ??
            Container(
              color: Colors.white10,
              child: const Icon(Icons.fastfood),
            ),
      );
    } else {
      return Image.asset(
        url,
        height: height,
        width: width,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (_, __, ___) =>
        errorWidget ??
            Container(
              color: Colors.white10,
              child: const Icon(Icons.fastfood),
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final auth = context.watch<AuthViewModel>();

    // ── EMPTY STATE ──
    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(_Resp.s(context, 24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeSlideIn(
                    child: Container(
                      width: _Resp.s(context, 140),
                      height: _Resp.s(context, 140),
                      decoration: BoxDecoration(
                        color: _Palette.accentA08,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: _Resp.s(context, 70),
                        color: _Palette.accent,
                      ),
                    ),
                  ),
                  SizedBox(height: _Resp.s(context, 24)),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Your cart is empty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _Resp.t(context, 20),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  SizedBox(height: _Resp.s(context, 8)),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: Text(
                      'Add some delicious items from our menu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: _Resp.t(context, 13.5),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _emptyBottomBar(context),
      );
    }

    // ── FILLED CART ──
    return ChangeNotifierProvider.value(
      value: _homeVm,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  _Resp.s(context, 16),
                  _Resp.s(context, 12),
                  _Resp.s(context, 16),
                  _Resp.s(context, 8),
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  ...cart.items.asMap().entries.map((e) {
                    final i = e.key;
                    final tile = _cartTile(context, cart, e.value);
                    if (i < 6) {
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 30 * i),
                        child: tile,
                      );
                    }
                    return tile;
                  }),
                  _youMayAlsoLike(context, cart),
                ],
              ),
            ),
            _summaryBar(context, cart, auth),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APPBAR
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
                      'Your Cart',
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
  // EMPTY-STATE BOTTOM BAR
  // ============================================================
  Widget _emptyBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _Resp.s(context, 20),
        _Resp.s(context, 16),
        _Resp.s(context, 20),
        _Resp.s(context, 20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_Resp.s(context, 24)),
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA06,
            blurRadius: _Resp.s(context, 20),
            offset: Offset(0, -_Resp.s(context, 6)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: CustomButton(
            label: 'Browse Menu',
            icon: Icons.restaurant_menu,
            onPressed: widget.onBrowseMenu ??
                    () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CART TILE
  // ============================================================
  Widget _cartTile(BuildContext context, CartViewModel cart, dynamic item) {
    final thumb = _Resp.s(context, 84);
    final imageUrl = (item.imageUrl ?? '') as String;

    return Padding(
      padding: EdgeInsets.only(bottom: _Resp.s(context, 12)),
      child: Container(
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(_Resp.s(context, 16)),
              ),
              child: _buildSmartImage(
                context,
                imageUrl,
                width: thumb,
                height: thumb,
                fit: BoxFit.cover,
                errorWidget: Container(
                  width: thumb,
                  height: thumb,
                  color: AppColors.divider,
                  child: Icon(
                    Icons.fastfood,
                    size: _Resp.s(context, 30),
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _Resp.s(context, 12),
                  vertical: _Resp.s(context, 10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: _Resp.t(context, 14),
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 6)),
                    Text(
                      Formatters.price(item.unitPrice),
                      style: TextStyle(
                        color: _Palette.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: _Resp.t(context, 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: _Resp.s(context, 10)),
              child: Row(
                children: [
                  _qtyBtn(
                    context,
                    Icons.remove,
                        () => cart.decrementLine(item),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _Resp.s(context, 10),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: _Resp.t(context, 16),
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  _qtyBtn(
                    context,
                    Icons.add,
                        () => cart.incrementLine(item),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // YOU MAY ALSO LIKE
  // ============================================================
  Widget _youMayAlsoLike(BuildContext context, CartViewModel cart) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        if (vm.loading) return const SizedBox.shrink();

        final cartNames = cart.items
            .map((it) => (it.displayName as String).toLowerCase())
            .toSet();

        final suggestions = vm.products
            .where((p) => !cartNames.contains(p.name.toLowerCase()))
            .take(8)
            .toList();

        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: _Resp.s(context, 18)),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: _Palette.accent,
                  size: _Resp.s(context, 18),
                ),
                SizedBox(width: _Resp.s(context, 6)),
                Text(
                  'You may also like',
                  style: TextStyle(
                    fontSize: _Resp.t(context, 16),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: _Resp.s(context, 12)),
            SizedBox(
              height: _Resp.s(context, 180),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: suggestions.length,
                itemBuilder: (_, i) => FadeSlideIn(
                  delay: Duration(milliseconds: 40 * (i % 6)),
                  child: _suggestionCard(context, suggestions[i]),
                ),
              ),
            ),
            SizedBox(height: _Resp.s(context, 16)),
          ],
        );
      },
    );
  }

  Widget _suggestionCard(BuildContext context, ProductModel p) {
    final price = p.hasVariants ? p.minPrice : p.effectivePrice;
    final cardWidth = _Resp.s(context, 150);
    final imageHeight = _Resp.s(context, 110);

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: _Resp.s(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA05,
            blurRadius: _Resp.s(context, 10),
            offset: Offset(0, _Resp.s(context, 4)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: p),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_Resp.s(context, 16)),
                ),
                child: _buildSmartImage(
                  context,
                  p.imageUrl,
                  height: imageHeight,
                  width: cardWidth,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    height: imageHeight,
                    width: cardWidth,
                    color: AppColors.divider,
                    child: Icon(
                      Icons.fastfood,
                      size: _Resp.s(context, 30),
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _Resp.s(context, 10),
                  _Resp.s(context, 8),
                  _Resp.s(context, 10),
                  _Resp.s(context, 10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: _Resp.t(context, 12),
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 6)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            Formatters.price(price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _Palette.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: _Resp.t(context, 13),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addSuggestionToCart(context, p),
                          child: Container(
                            width: _Resp.s(context, 30),
                            height: _Resp.s(context, 30),
                            decoration: BoxDecoration(
                              color: _Palette.accent,
                              borderRadius: BorderRadius.circular(
                                  _Resp.s(context, 9)),
                              boxShadow: [
                                BoxShadow(
                                  color: _Palette.accentA30,
                                  blurRadius: _Resp.s(context, 8),
                                  offset:
                                  Offset(0, _Resp.s(context, 4)),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: _Resp.s(context, 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSuggestionToCart(BuildContext context, ProductModel p) {
    final cart = context.read<CartViewModel>();
    if (p.hasVariants) {
      cart.addVariant(p, p.variants.first);
    } else {
      cart.add(p);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.name} added to cart'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // SUMMARY BAR (filled cart)
  // ============================================================
  Widget _summaryBar(
      BuildContext context,
      CartViewModel cart,
      AuthViewModel auth,
      ) {
    final isSignedIn = auth.currentUser != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        _Resp.s(context, 20),
        _Resp.s(context, 16),
        _Resp.s(context, 20),
        _Resp.s(context, 20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_Resp.s(context, 24)),
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA06,
            blurRadius: _Resp.s(context, 20),
            offset: Offset(0, -_Resp.s(context, 6)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: _Resp.t(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  Formatters.price(cart.subtotal),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: _Resp.t(context, 18),
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            Text(
              'Vouchers May Apply',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: _Resp.t(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _Resp.s(context, 14)),
            CustomButton(
              label: isSignedIn ? 'Proceed to Checkout' : 'Login to Checkout',
              icon: isSignedIn ? null : Icons.login_rounded,
              onPressed: () {
                if (!isSignedIn) {
                  _showSignInDialog(context);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CheckoutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final size = _Resp.s(context, 34);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _Palette.accentA10,
        borderRadius: BorderRadius.circular(_Resp.s(context, 10)),
        border: Border.all(color: _Palette.accentA30, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Resp.s(context, 10)),
        child: Icon(
          icon,
          size: _Resp.s(context, 18),
          color: _Palette.accent,
        ),
      ),
    );
  }

  // ============================================================
  // SIGN IN DIALOG
  // ------------------------------------------------------------
  // "Login" button now pushes the LoginScreen directly, so the
  // user always lands on the login form regardless of how the
  // AuthViewModel handles signOut().
  // ============================================================
  void _showSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Resp.s(context, 20)),
        ),
        icon: Icon(
          Icons.login_rounded,
          color: _Palette.accent,
          size: _Resp.s(context, 40),
        ),
        title: const Text(
          'Login required',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Please login to place your order. Guests can browse and add items, but checkout needs an account.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerLoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
              ),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}