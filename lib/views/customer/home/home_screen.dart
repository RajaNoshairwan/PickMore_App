import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animations.dart';
import '../../../models/product_model.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../../../viewmodels/customer/home_viewmodel.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/store_locator_screen.dart';
import 'category_products_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';

// ============================================================
// RESPONSIVE SCALING HELPERS
// ------------------------------------------------------------
// Everything is laid out against a 390 dp baseline (a common
// modern phone width). Values are multiplied by a scale factor
// that is clamped so that:
//   • tiny phones (≈320 dp) shrink proportionally but stay usable
//   • tablets / foldables (≈800 dp+) grow proportionally but
//     never blow the layout out of proportion.
// Fonts use a slightly tighter clamp so text never becomes
// unreadably small or comically large.
// ============================================================
class _Resp {
  static const double _base = 390.0;

  static double _w(BuildContext c) => MediaQuery.of(c).size.width;

  /// Layout scale for sizes, paddings, radii, icons.
  static double scale(BuildContext c) => (_w(c) / _base).clamp(0.82, 1.30);

  /// Text scale — tighter clamp keeps fonts readable everywhere.
  static double textScale(BuildContext c) =>
      (_w(c) / _base).clamp(0.88, 1.18);

  /// Scale a layout value.
  static double s(BuildContext c, double v) => v * scale(c);

  /// Scale a font / text-driven value.
  static double t(BuildContext c, double v) => v * textScale(c);
}

// ============================================================
// LOCAL PALETTE
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const announcement = Color(0xFF7C3AED);
  static const announcementEnd = Color(0xFF9333EA);
  static const dealBg = Color(0xFF0F172A);
  static const dealBg2 = Color(0xFF1E293B);
  static const accent = Color(0xFFFF6B35);
  static const openGreen = Color(0xFF10B981);
  static const closedRed = Color(0xFFEF4444);
  static const specialYellow = Color(0xFFFCD34D);
}

class HomeScreen extends StatefulWidget {
  /// Called when user taps "See all" on Popular or "Browse Full Menu".
  final VoidCallback? onOpenMenu;

  const HomeScreen({super.key, this.onOpenMenu});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _vm;
  final _dealPageController = PageController(viewportFraction: 0.92);
  int _dealPage = 0;
  Timer? _dealTimer;
  int _lastPizzaCount = 0;

  @override
  void initState() {
    super.initState();
    _vm = HomeViewModel();
    _vm.addListener(_onVmChanged);
    _vm.loadAll();
  }

  void _onVmChanged() {
    final count = _pizzaDeals.length;
    if (count != _lastPizzaCount) {
      _lastPizzaCount = count;
      _restartAutoSlide(count);
    }
  }

  void _restartAutoSlide(int count) {
    _dealTimer?.cancel();
    if (count <= 1) return;
    _dealTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_dealPage + 1) % count;
      if (_dealPageController.hasClients) {
        _dealPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// 4 pizza deals — category contains "Pizza Deal".
  /// Fallback: any `isDeal` product.
  List<ProductModel> get _pizzaDeals {
    final pizza = _vm.products
        .where((p) => p.category.toLowerCase().contains('pizza deal'))
        .take(4)
        .toList();
    if (pizza.isNotEmpty) return pizza;
    return _vm.products.where((p) => p.isDeal).take(4).toList();
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _dealTimer?.cancel();
    _dealPageController.dispose();
    super.dispose();
  }

  // ============================================================
  // SMART IMAGE HELPER (Handles both Local Assets and Network)
  // ============================================================
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

    // Calculate exact pixel size needed on this device
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    int? cacheWidth = width != null ? (width * pixelRatio).round() : null;
    int? cacheHeight = height != null ? (height * pixelRatio).round() : null;

    // Check if it's a local asset or a network image
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: width,
        fit: fit,
        // Resizes network images in memory too
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
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
        // 🚀 THIS IS THE KEY: Resizes the image in memory before drawing
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
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<HomeViewModel, AuthViewModel>(
        builder: (context, vm, auth, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: RefreshIndicator(
              onRefresh: vm.loadAll,
              color: _Palette.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(context, vm, auth),
                  SizedBox(height: _Resp.s(context, 16)),
                  _buildAnnouncement(context),
                  SizedBox(height: _Resp.s(context, 18)),
                  if (vm.loading)
                    _loadingSkeleton(context)
                  else ...[
                    // ── Pizza Deals Carousel (4) ──
                    if (_pizzaDeals.isNotEmpty) ...[
                      _buildPizzaDealsCarousel(context),
                      SizedBox(height: _Resp.s(context, 28)),
                    ],
                    _buildCraving(context, vm),
                    SizedBox(height: _Resp.s(context, 26)),
                    _buildPopularSection(context, vm),
                    SizedBox(height: _Resp.s(context, 26)),
                    _buildStudentDeals(context, vm),
                    SizedBox(height: _Resp.s(context, 24)),
                    _buildBrowseMenuButton(context),
                    SizedBox(height: _Resp.s(context, 30)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 1. HEADER
  // ============================================================
  Widget _buildHeader(
      BuildContext context, HomeViewModel vm, AuthViewModel auth) {
    final firstName = auth.currentUser == null
        ? 'Guest'
        : (auth.currentUser!.name.trim().isEmpty
        ? 'Guest'
        : auth.currentUser!.name.trim().split(' ').first);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_Palette.headerStart, _Palette.headerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(_Resp.s(context, 28)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _Resp.s(context, 20),
            _Resp.s(context, 10),
            _Resp.s(context, 20),
            _Resp.s(context, 20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      onTap: () => _onLocationTap(context, auth, vm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $firstName! 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _Resp.t(context, 13),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: _Resp.s(context, 4)),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: Colors.white,
                                  size: _Resp.s(context, 15)),
                              SizedBox(width: _Resp.s(context, 4)),
                              Flexible(
                                child: Text(
                                  _locationLabel(auth),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _Resp.t(context, 14),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: _Resp.s(context, 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: _Resp.s(context, 8)),
                  _openBadge(context, vm.isStoreOpen),
                  SizedBox(width: _Resp.s(context, 4)),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: _Resp.s(context, 36),
                      minHeight: _Resp.s(context, 36),
                    ),
                    onPressed: () => _showNotifications(context),
                    icon: Icon(Icons.notifications_none_rounded,
                        color: Colors.white, size: _Resp.s(context, 24)),
                  ),
                ],
              ),
              SizedBox(height: _Resp.s(context, 16)),
              _searchBar(context),
            ],
          ),
        ),
      ),
    );
  }

  String _locationLabel(AuthViewModel auth) {
    if (auth.currentUser == null) return 'Set delivery location';
    final addr = auth.currentUser!.defaultAddress;
    if (addr == null || addr.fullAddress.trim().isEmpty) {
      return 'Set delivery location';
    }
    return addr.fullAddress.split(',').first.trim();
  }

  Widget _openBadge(BuildContext context, bool open) {
    final color = open ? _Palette.openGreen : _Palette.closedRed;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _Resp.s(context, 10),
        vertical: _Resp.s(context, 5),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_Resp.s(context, 20)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: _Resp.s(context, 8),
            offset: Offset(0, _Resp.s(context, 2)),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: _Resp.s(context, 6), color: Colors.white),
          SizedBox(width: _Resp.s(context, 5)),
          Text(
            open ? 'Open' : 'Closed',
            style: TextStyle(
              color: Colors.white,
              fontSize: _Resp.t(context, 11),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return PressableScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _Resp.s(context, 16),
          vertical: _Resp.s(context, 4),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
        ),
        child: Row(
          children: [
            Icon(Icons.search,
                color: AppColors.textLight, size: _Resp.s(context, 20)),
            SizedBox(width: _Resp.s(context, 10)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: _Resp.s(context, 12)),
                child: Text(
                  'Search pizza, burgers, deals...',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: _Resp.t(context, 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 2. ANNOUNCEMENT — SEAMLESS MARQUEE
  // ============================================================
  Widget _buildAnnouncement(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _Resp.s(context, 20)),
      padding: EdgeInsets.symmetric(
        horizontal: _Resp.s(context, 12),
        vertical: _Resp.s(context, 11),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_Palette.announcement, _Palette.announcementEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
        boxShadow: [
          BoxShadow(
            color: _Palette.announcement.withOpacity(0.3),
            blurRadius: _Resp.s(context, 12),
            offset: Offset(0, _Resp.s(context, 6)),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_rounded,
              color: Colors.white, size: _Resp.s(context, 18)),
          SizedBox(width: _Resp.s(context, 8)),
          Expanded(
            child: SizedBox(
              height: _Resp.t(context, 16),
              child: _MarqueeText(
                text:
                'Announcement: Free Delivery on orders above 1000   •   '
                    'Freshly baked pizzas starting at Rs. 649   •   '
                    'Student Deals now live!   •   ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _Resp.t(context, 12),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. PIZZA DEALS CAROUSEL — 4 ITEMS, AUTO-SLIDE
  // ============================================================
  Widget _buildPizzaDealsCarousel(BuildContext context) {
    final deals = _pizzaDeals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _Resp.s(context, 20)),
          child: Row(
            children: [
              Text(
                'Pizza Deals 🍕',
                style: TextStyle(
                  fontSize: _Resp.t(context, 18),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(width: _Resp.s(context, 8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _Resp.s(context, 8),
                  vertical: _Resp.s(context, 3),
                ),
                decoration: BoxDecoration(
                  color: _Palette.specialYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(_Resp.s(context, 20)),
                ),
                child: Text(
                  'HOT',
                  style: TextStyle(
                    color: const Color(0xFF92400E),
                    fontSize: _Resp.t(context, 9),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _Resp.s(context, 14)),

        // Carousel
        SizedBox(
          height: _Resp.s(context, 175),
          child: PageView.builder(
            controller: _dealPageController,
            itemCount: deals.length,
            onPageChanged: (i) => setState(() => _dealPage = i),
            itemBuilder: (_, i) => _pizzaDealCard(context, deals[i], i),
          ),
        ),

        SizedBox(height: _Resp.s(context, 12)),

        // Pagination dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            deals.length,
                (i) {
              final active = _dealPage == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: _Resp.s(context, 3)),
                width: active ? _Resp.s(context, 22) : _Resp.s(context, 8),
                height: _Resp.s(context, 8),
                decoration: BoxDecoration(
                  color: active ? _Palette.accent : AppColors.divider,
                  borderRadius: BorderRadius.circular(_Resp.s(context, 4)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pizzaDealCard(BuildContext context, ProductModel p, int index) {
    final price = p.hasVariants ? p.minPrice : p.effectivePrice;
    final description = p.description.isNotEmpty
        ? p.description
        : (p.hasVariants
        ? '${p.variants.length} options • ${p.category}'
        : p.category);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _Resp.s(context, 6)),
      child: PressableScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.fromLTRB(
            _Resp.s(context, 18),
            _Resp.s(context, 16),
            0,
            _Resp.s(context, 16),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_Palette.dealBg, _Palette.dealBg2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_Resp.s(context, 22)),
            boxShadow: [
              BoxShadow(
                color: _Palette.dealBg.withOpacity(0.35),
                blurRadius: _Resp.s(context, 18),
                offset: Offset(0, _Resp.s(context, 10)),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _Resp.s(context, 10),
                        vertical: _Resp.s(context, 4),
                      ),
                      decoration: BoxDecoration(
                        color: _Palette.specialYellow,
                        borderRadius:
                        BorderRadius.circular(_Resp.s(context, 20)),
                      ),
                      child: Text(
                        'SPECIAL OFFER',
                        style: TextStyle(
                          color: const Color(0xFF7C2D12),
                          fontSize: _Resp.t(context, 9),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 12)),
                    Text(
                      'Deal # ${(index + 1).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _Resp.t(context, 22),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 6)),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: _Resp.t(context, 11),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 10)),
                    Text(
                      'Rs. ${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _Resp.t(context, 20),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Transform.translate(
                  offset: Offset(_Resp.s(context, 14), 0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _Palette.accent.withOpacity(0.5),
                            blurRadius: _Resp.s(context, 22),
                            spreadRadius: _Resp.s(context, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _buildSmartImage(
                          context,
                          p.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: Colors.white10,
                            child: Icon(Icons.fastfood,
                                color: Colors.white,
                                size: _Resp.s(context, 50)),
                          ),
                        ),
                      ),
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
  // 4. WHAT ARE YOU CRAVING?
  // ============================================================
  Widget _buildCraving(BuildContext context, HomeViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _Resp.s(context, 20)),
          child: Text(
            'What are you craving?',
            style: TextStyle(
              fontSize: _Resp.t(context, 18),
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        SizedBox(height: _Resp.s(context, 14)),
        SizedBox(
          height: _Resp.s(context, 108),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: _Resp.s(context, 20)),
            itemCount: vm.categories.length,
            itemBuilder: (_, i) {
              final cat = vm.categories[i];
              return FadeSlideIn(
                delay: Duration(milliseconds: 40 * i),
                child: _cravingItem(context, cat, vm),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _cravingItem(
      BuildContext context, String category, HomeViewModel vm) {
    final items = vm.byCategory(category);
    final img = items.isNotEmpty ? items.first.imageUrl : '';

    return Padding(
      padding: EdgeInsets.only(right: _Resp.s(context, 14)),
      child: PressableScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsScreen(category: category),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: _Resp.s(context, 68),
              height: _Resp.s(context, 68),
              padding: EdgeInsets.all(_Resp.s(context, 2)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _Palette.accent.withOpacity(0.4),
                  width: _Resp.s(context, 2),
                ),
              ),
              child: ClipOval(
                child: _buildSmartImage(
                  context,
                  img,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: _Palette.accent.withOpacity(0.1),
                    child: Icon(Icons.fastfood,
                        color: _Palette.accent,
                        size: _Resp.s(context, 26)),
                  ),
                ),
              ),
            ),
            SizedBox(height: _Resp.s(context, 8)),
            SizedBox(
              width: _Resp.s(context, 76),
              child: Text(
                category,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _Resp.t(context, 10),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 5. POPULAR RIGHT NOW (See all → Menu tab)
  // ============================================================
  Widget _buildPopularSection(BuildContext context, HomeViewModel vm) {
    final items = vm.products.take(12).toList();
    return _buildHorizontalProducts(
      context,
      title: 'Popular right now',
      items: items,
      actionLabel: 'See all',
      onAction: widget.onOpenMenu,
    );
  }

  // ============================================================
  // 6. STUDENT DEALS — NO SEE ALL
  // ============================================================
  Widget _buildStudentDeals(BuildContext context, HomeViewModel vm) {
    final students = vm.products
        .where((p) =>
    p.category.toLowerCase().contains('student') ||
        p.name.toLowerCase().contains('student'))
        .toList();

    if (students.isEmpty) return const SizedBox.shrink();

    return _buildHorizontalProducts(
      context,
      title: 'Student deals 🎓',
      items: students,
      // No See all, no onAction
    );
  }

  // ============================================================
  // 7. BROWSE FULL MENU BUTTON
  // ============================================================
  Widget _buildBrowseMenuButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _Resp.s(context, 20)),
      child: PressableScale(
        onTap: widget.onOpenMenu,
        child: Container(
          height: _Resp.s(context, 58),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_Palette.accent, Color(0xFFE85A2B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
            boxShadow: [
              BoxShadow(
                color: _Palette.accent.withOpacity(0.35),
                blurRadius: _Resp.s(context, 16),
                offset: Offset(0, _Resp.s(context, 8)),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu,
                  color: Colors.white, size: _Resp.s(context, 20)),
              SizedBox(width: _Resp.s(context, 10)),
              Text(
                'Browse Full Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _Resp.t(context, 15),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: _Resp.s(context, 8)),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: _Resp.s(context, 18)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHARED: HORIZONTAL PRODUCTS ROW
  // ============================================================
  Widget _buildHorizontalProducts(
      BuildContext context, {
        required String title,
        required List<ProductModel> items,
        String? actionLabel,
        VoidCallback? onAction,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _Resp.s(context, 20)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: _Resp.t(context, 18),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: _Palette.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: _Resp.t(context, 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: _Resp.s(context, 12)),
        SizedBox(
          height: _Resp.s(context, 235),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: _Resp.s(context, 20)),
            itemCount: items.length,
            itemBuilder: (_, i) => FadeSlideIn(
              delay: Duration(milliseconds: 40 * (i % 6)),
              child: _productHorizontalCard(context, items[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _productHorizontalCard(BuildContext context, ProductModel p) {
    final price = p.hasVariants ? p.minPrice : p.effectivePrice;
    final cardWidth = _Resp.s(context, 165);
    final imageHeight = _Resp.s(context, 120);

    return PressableScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
      ),
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: _Resp.s(context, 14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: _Resp.s(context, 12),
              offset: Offset(0, _Resp.s(context, 6)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_Resp.s(context, 16)),
                  ),
                  child: Hero(
                    tag: 'product_${p.id}',
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
                        child: Icon(Icons.fastfood,
                            size: _Resp.s(context, 40)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: _Resp.s(context, 8),
                  right: _Resp.s(context, 8),
                  child: Row(
                    children: [
                      _miniChip(context, 'DINE IN'),
                      SizedBox(width: _Resp.s(context, 4)),
                      _miniChip(context, 'TAKEAWAY'),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                _Resp.s(context, 10),
                _Resp.s(context, 10),
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
                      fontSize: _Resp.t(context, 13),
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: _Resp.s(context, 10)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: TextStyle(
                                fontSize: _Resp.t(context, 9),
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Rs. ${price.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: _Resp.t(context, 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: _Resp.s(context, 32),
                        height: _Resp.s(context, 32),
                        decoration: BoxDecoration(
                          color: _Palette.accent,
                          borderRadius:
                          BorderRadius.circular(_Resp.s(context, 10)),
                          boxShadow: [
                            BoxShadow(
                              color: _Palette.accent.withOpacity(0.3),
                              blurRadius: _Resp.s(context, 8),
                              offset: Offset(0, _Resp.s(context, 4)),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            if (p.hasVariants) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: p),
                                ),
                              );
                            } else {
                              context.read<CartViewModel>().add(p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${p.name} added to cart'),
                                  duration:
                                  const Duration(milliseconds: 900),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          borderRadius:
                          BorderRadius.circular(_Resp.s(context, 10)),
                          child: Icon(Icons.add,
                              color: Colors.white,
                              size: _Resp.s(context, 18)),
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
    );
  }

  Widget _miniChip(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _Resp.s(context, 5),
        vertical: _Resp.s(context, 2),
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(_Resp.s(context, 4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: _Resp.t(context, 7),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION / NOTIFICATIONS SHEETS
  // ============================================================
  void _onLocationTap(
      BuildContext context,
      AuthViewModel auth,
      HomeViewModel vm,
      ) {
    if (auth.currentUser == null) {
      _showGuestSignInDialog(context);
      return;
    }

    final user = auth.currentUser!;
    final addr = user.defaultAddress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // <--- FIX: Allows the sheet to expand if content is tall
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
          _Resp.s(context, 20),
          _Resp.s(context, 12),
          _Resp.s(context, 20),
          _Resp.s(context, 24),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_Resp.s(context, 28)),
          ),
        ),
        child: SingleChildScrollView( // <--- FIX: Makes content scrollable if it overflows
          child: SafeArea( // <--- FIX: Handles bottom system navigation bars
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: _Resp.s(context, 44),
                    height: _Resp.s(context, 4),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius:
                      BorderRadius.circular(_Resp.s(context, 2)),
                    ),
                  ),
                ),
                SizedBox(height: _Resp.s(context, 20)),
                Text(
                  'Your delivery location',
                  style: TextStyle(
                    fontSize: _Resp.t(context, 18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: _Resp.s(context, 14)),
                Container(
                  padding: EdgeInsets.all(_Resp.s(context, 14)),
                  decoration: BoxDecoration(
                    color: _Palette.accent.withOpacity(0.06),
                    borderRadius:
                    BorderRadius.circular(_Resp.s(context, 14)),
                    border: Border.all(
                      color: _Palette.accent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.home_outlined,
                          color: _Palette.accent,
                          size: _Resp.s(context, 24)),
                      SizedBox(width: _Resp.s(context, 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr?.label ?? 'Home',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: _Resp.t(context, 13),
                              ),
                            ),
                            SizedBox(height: _Resp.s(context, 2)),
                            Text(
                              (addr?.fullAddress.trim().isNotEmpty ??
                                  false)
                                  ? addr!.fullAddress
                                  : 'No address saved yet',
                              style: TextStyle(
                                fontSize: _Resp.t(context, 12),
                                color: AppColors.textLight,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _Resp.s(context, 14)),
                _sheetAction(
                  context,
                  icon: Icons.edit_outlined,
                  title: 'Change address',
                  subtitle: 'Update your default delivery address',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
                // _sheetAction(
                //   context,
                //   icon: Icons.storefront_outlined,
                //   title: 'View store on map',
                //   subtitle: 'See the restaurant location',
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //           builder: (_) => const StoreLocatorScreen()),
                //     );
                //   },
                // ),
                // _sheetAction(
                //   context,
                //   icon: Icons.my_location_outlined,
                //   title: 'Use current location',
                //   subtitle: 'Locate me automatically',
                //   onTap: () {
                //     Navigator.pop(context);
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(
                //         content: Text(
                //             'Location capture is available on the Edit Profile screen'),
                //       ),
                //     );
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetAction(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Padding(
      padding: EdgeInsets.only(top: _Resp.s(context, 8)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: _Resp.s(context, 10),
              horizontal: _Resp.s(context, 4),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_Resp.s(context, 10)),
                  decoration: BoxDecoration(
                    color: _Palette.accent.withOpacity(0.08),
                    borderRadius:
                    BorderRadius.circular(_Resp.s(context, 12)),
                  ),
                  child: Icon(icon,
                      size: _Resp.s(context, 20),
                      color: _Palette.accent),
                ),
                SizedBox(width: _Resp.s(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: _Resp.t(context, 14),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: _Resp.t(context, 11),
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: _Resp.s(context, 20),
                    color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGuestSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Resp.s(context, 20)),
        ),
        icon: Icon(Icons.location_off_outlined,
            color: _Palette.accent, size: _Resp.s(context, 40)),
        title: Text(
          'Location locked',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: _Resp.t(context, 20),
          ),
        ),
        content: Text(
          'Sign in to view your saved addresses and set your delivery location.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textLight,
            height: 1.5,
            fontSize: _Resp.t(context, 14),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.accent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: _Resp.s(context, 22),
                vertical: _Resp.s(context, 12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthViewModel>().signOut();
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: _Resp.s(context, 32),
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            _Resp.s(context, 24),
            _Resp.s(context, 28),
            _Resp.s(context, 24),
            _Resp.s(context, 20),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_Resp.s(context, 28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: _Resp.s(context, 30),
                offset: Offset(0, _Resp.s(context, 10)),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon with soft circular background ──
              Container(
                width: _Resp.s(context, 90),
                height: _Resp.s(context, 90),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _Palette.accent.withOpacity(0.15),
                      _Palette.accent.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: _Resp.s(context, 46),
                  color: _Palette.accent,
                ),
              ),
              SizedBox(height: _Resp.s(context, 20)),

              // ── Title ──
              Text(
                'No new notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _Resp.t(context, 18),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: _Resp.s(context, 10)),

              // ── Subtitle ──
              Text(
                "We'll let you know when something new arrives!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: _Resp.t(context, 13),
                  height: 1.5,
                ),
              ),
              SizedBox(height: _Resp.s(context, 24)),

              // ── Close button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      vertical: _Resp.s(context, 14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(_Resp.s(context, 14)),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: _Resp.t(context, 14),
                      letterSpacing: 0.3,
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
  // LOADING SKELETON
  // ============================================================
  Widget _loadingSkeleton(BuildContext context) {
    final bigCircle = _Resp.s(context, 68);
    final circleRadius =
    BorderRadius.all(Radius.circular(_Resp.s(context, 40)));

    return Padding(
      padding: EdgeInsets.all(_Resp.s(context, 20)),
      child: Column(
        children: [
          ShimmerBox(height: _Resp.s(context, 175)),
          SizedBox(height: _Resp.s(context, 20)),
          Row(
            children: [
              ShimmerBox(
                height: bigCircle,
                width: bigCircle,
                radius: circleRadius,
              ),
              SizedBox(width: _Resp.s(context, 14)),
              ShimmerBox(
                height: bigCircle,
                width: bigCircle,
                radius: circleRadius,
              ),
              SizedBox(width: _Resp.s(context, 14)),
              ShimmerBox(
                height: bigCircle,
                width: bigCircle,
                radius: circleRadius,
              ),
              SizedBox(width: _Resp.s(context, 14)),
              ShimmerBox(
                height: bigCircle,
                width: bigCircle,
                radius: circleRadius,
              ),
            ],
          ),
          SizedBox(height: _Resp.s(context, 24)),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: _Resp.s(context, 200))),
              SizedBox(width: _Resp.s(context, 14)),
              Expanded(child: ShimmerBox(height: _Resp.s(context, 200))),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SEAMLESS MARQUEE
// Measures text width and loops with no empty gap.
// ============================================================
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late double _textWidth;
  bool _started = false;
  TextStyle _measuredStyle = const TextStyle();

  @override
  void initState() {
    super.initState();
    _measure();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  void _measure() {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    _textWidth = tp.width;
    _measuredStyle = widget.style;
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Font size changes when the screen size / orientation changes —
    // re-measure so the loop stays seamless.
    if (widget.text != oldWidget.text ||
        widget.style.fontSize != oldWidget.style.fontSize) {
      _measure();
    }
  }

  void _ensureStarted(double containerWidth) {
    if (_started) return;
    _started = true;

    // Total travel distance = container + text width.
    final totalDistance = containerWidth + _textWidth;

    // 80 px/sec → feels smooth without being too fast.
    final ms = (totalDistance / 80 * 1000).round();
    _ctrl.duration = Duration(milliseconds: ms);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        _ensureStarted(width);

        return ClipRect(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final totalDistance = width + _textWidth;
              final dx = width - (_ctrl.value * totalDistance);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.text,
                    style: _measuredStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}