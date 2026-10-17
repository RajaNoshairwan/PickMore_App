import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../menu/menu_screen.dart';   // ← add this
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animations.dart';
import '../../../models/product_model.dart';
import '../../../viewmodels/customer/home_viewmodel.dart';
import 'product_detail_screen.dart';

// ============================================================
// RESPONSIVE SCALING HELPERS
// ============================================================
class _Resp {
  static const double _base = 390.0;

  static double _w(BuildContext c) => MediaQuery.of(c).size.width;

  static double scale(BuildContext c) => (_w(c) / _base).clamp(0.82, 1.30);
  static double textScale(BuildContext c) =>
      (_w(c) / _base).clamp(0.88, 1.18);

  static double s(BuildContext c, double v) => v * scale(c);
  static double t(BuildContext c, double v) => v * textScale(c);

  static int columns(BuildContext c) {
    final w = _w(c);
    if (w < 600) return 2;
    if (w < 900) return 3;
    if (w < 1200) return 4;
    return 5;
  }

  static double cardAspect(BuildContext c) {
    final w = _w(c);
    if (w < 380) return 0.78;
    if (w < 600) return 0.80;
    if (w < 900) return 0.86;
    return 0.90;
  }
}

// ============================================================
// LOCAL PALETTE (mirrors HomeScreen)
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF6B35);
  static const accentDeep = Color(0xFFE85A2B);
}

class CategoryProductsScreen extends StatefulWidget {
  final String category;

  /// Optional callback — mirrors HomeScreen.onOpenMenu.
  /// Wire this to your main-shell tab switcher (e.g. `() => shell.switchTab(1)`).
  /// If null, tapping "Browse Full Menu" simply pops back to the root.
  final VoidCallback? onOpenMenu;

  const CategoryProductsScreen({
    super.key,
    required this.category,
    this.onOpenMenu,
  });

  @override
  State<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  late final HomeViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = HomeViewModel();
    _vm.loadAll();
  }

  @override
  void dispose() {
    _vm.dispose();
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
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        fadeInDuration: const Duration(milliseconds: 180),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).padding.top + _Resp.s(context, 60),
        ),
        child: AnimatedBuilder(
          animation: _vm,
          builder: (context, _) => _buildAppBarContent(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (context, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _vm.loading
                ? _loadingSkeleton(context)
                : _buildBody(context),
          );
        },
      ),
      // ── Pinned CTA bar — same design language as HomeScreen ──
      bottomNavigationBar: _buildBrowseMenuBar(context),
    );
  }

  // ============================================================
  // BROWSE FULL MENU BAR
  // ------------------------------------------------------------
  // Matches HomeScreen's button exactly (gradient, radius, shadow,
  // icon, typography) but lives in a persistent bottom bar so it's
  // always reachable regardless of scroll position.
  // ============================================================
  Widget _buildBrowseMenuBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: _Resp.s(context, 12),
            offset: Offset(0, -_Resp.s(context, 4)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _Resp.s(context, 20),
            _Resp.s(context, 10),
            _Resp.s(context, 20),
            _Resp.s(context, 12),
          ),
          child: PressableScale(
            onTap: _onBrowseMenuTap,
            child: Container(
              height: _Resp.s(context, 58),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_Palette.accent, _Palette.accentDeep],
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
                  Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: _Resp.s(context, 20),
                  ),
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
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: _Resp.s(context, 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pops this screen and hands off to the shell's menu tab.
  /// Falls back to popping to root if no callback was provided.
  void _onBrowseMenuTap() {
    final cb = widget.onOpenMenu;
    if (cb != null) {
      Navigator.of(context).pop();
      cb();
    } else {
      // Direct navigation to the Menu screen.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    }
  }

  // ============================================================
  // APPBAR
  // ============================================================
  Widget _buildAppBarContent(BuildContext context) {
    final barHeight = _Resp.s(context, 60);

    return Container(
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
            color: _Palette.headerEnd.withOpacity(0.35),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _Resp.t(context, 18),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 2)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        _vm.loading
                            ? 'Loading…'
                            : '${_vm.byCategory(widget.category).length} items',
                        key: ValueKey(_vm.loading),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: _Resp.t(context, 11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _Resp.s(context, 8)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================
  Widget _buildBody(BuildContext context) {
    final items = _vm.byCategory(widget.category);
    if (items.isEmpty) return _emptyState(context);
    return _buildGrid(context, items);
  }

  // ============================================================
  // GRID
  // ============================================================
  Widget _buildGrid(BuildContext context, List<ProductModel> items) {
    final cols = _Resp.columns(context);
    return GridView.builder(
      key: const ValueKey('grid'),
      padding: EdgeInsets.fromLTRB(
        _Resp.s(context, 16),
        _Resp.s(context, 18),
        _Resp.s(context, 16),
        _Resp.s(context, 24),
      ),
      itemCount: items.length,
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: _Resp.cardAspect(context),
        crossAxisSpacing: _Resp.s(context, 12),
        mainAxisSpacing: _Resp.s(context, 12),
      ),
      itemBuilder: (_, i) => FadeSlideIn(
        delay: Duration(milliseconds: 40 * (i % 6)),
        child: _productCard(context, items[i]),
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================
  Widget _productCard(BuildContext context, ProductModel p) {
    final price = p.hasVariants ? p.minPrice : p.effectivePrice;

    return PressableScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: p),
        ),
      ),
      child: Container(
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
            // ── IMAGE — takes all leftover height ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_Resp.s(context, 16)),
                    ),
                    child: Hero(
                      tag: 'product_${p.id}',
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return _buildSmartImage(
                            context,
                            p.imageUrl,
                            height: constraints.maxHeight,
                            width: constraints.maxWidth,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: AppColors.divider,
                              child: Icon(
                                Icons.fastfood,
                                size: _Resp.s(context, 40),
                                color: AppColors.textLight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (p.isDeal)
                    Positioned(
                      top: _Resp.s(context, 8),
                      left: _Resp.s(context, 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _Resp.s(context, 7),
                          vertical: _Resp.s(context, 3),
                        ),
                        decoration: BoxDecoration(
                          color: _Palette.accent,
                          borderRadius:
                          BorderRadius.circular(_Resp.s(context, 6)),
                        ),
                        child: Text(
                          'DEAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _Resp.t(context, 8),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── DETAILS — sized to content only ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                _Resp.s(context, 10),
                _Resp.s(context, 8),
                _Resp.s(context, 8),
                _Resp.s(context, 8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: _Resp.t(context, 12.5),
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: _Resp.s(context, 6)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: TextStyle(
                                fontSize: _Resp.t(context, 9),
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: _Resp.s(context, 2)),
                            Text(
                              Formatters.price(price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _Palette.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: _Resp.t(context, 13),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: _Resp.s(context, 6)),
                      Container(
                        width: _Resp.s(context, 30),
                        height: _Resp.s(context, 30),
                        decoration: BoxDecoration(
                          color: _Palette.accent,
                          borderRadius:
                          BorderRadius.circular(_Resp.s(context, 9)),
                          boxShadow: [
                            BoxShadow(
                              color: _Palette.accent.withOpacity(0.3),
                              blurRadius: _Resp.s(context, 8),
                              offset: Offset(0, _Resp.s(context, 4)),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: _Resp.s(context, 16),
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

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _emptyState(BuildContext context) {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: EdgeInsets.all(_Resp.s(context, 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _Resp.s(context, 96),
              height: _Resp.s(context, 96),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Palette.accent.withOpacity(0.1),
              ),
              child: Icon(
                Icons.fastfood_outlined,
                size: _Resp.s(context, 44),
                color: _Palette.accent,
              ),
            ),
            SizedBox(height: _Resp.s(context, 20)),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: _Resp.t(context, 16),
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: _Resp.s(context, 6)),
            Text(
              "We couldn't find anything in ${widget.category} right now.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _Resp.t(context, 12.5),
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING SKELETON
  // ============================================================
  Widget _loadingSkeleton(BuildContext context) {
    final cols = _Resp.columns(context);
    return GridView.builder(
      key: const ValueKey('skeleton'),
      padding: EdgeInsets.fromLTRB(
        _Resp.s(context, 16),
        _Resp.s(context, 18),
        _Resp.s(context, 16),
        _Resp.s(context, 24),
      ),
      itemCount: cols * 2,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: _Resp.cardAspect(context),
        crossAxisSpacing: _Resp.s(context, 12),
        mainAxisSpacing: _Resp.s(context, 12),
      ),
      itemBuilder: (_, __) => LayoutBuilder(
        builder: (context, constraints) => ShimmerBox(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          radius: const BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}