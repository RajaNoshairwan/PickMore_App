import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animations.dart';
import '../../../models/product_model.dart';
import '../../../viewmodels/customer/home_viewmodel.dart';
import '../home/product_detail_screen.dart';
import '../home/search_screen.dart';

// ============================================================
// RESPONSIVE SCALING HELPERS
// ------------------------------------------------------------
// Uses MediaQuery.sizeOf (not .of(context).size) — it only
// rebuilds dependents when the *size* changes, which is far
// cheaper inside hot list-item paths.
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
// ------------------------------------------------------------
// Precomputed alpha variants — building `withOpacity()` in a
// hot list-item build is unnecessary GC churn.
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF6B35);
  static const accentDeep = Color(0xFFE85A2B);

  static final accentA30 = accent.withOpacity(0.30);
  static final accentA10 = accent.withOpacity(0.10);
  static final headerEndA35 = headerEnd.withOpacity(0.35);
  static final blackA05 = Colors.black.withOpacity(0.05);
  static final accentBorder25 = accent.withOpacity(0.25);
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final HomeViewModel _vm;
  String _selected = 'All';

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
        int? cachePx,
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

    // Network image (future Cloudinary URLs)
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: width,
        fit: fit,
        memCacheWidth: cachePx,
        memCacheHeight: cachePx,
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
    }

    // Local asset
    return Image.asset(
      url,
      height: height,
      width: width,
      fit: fit,
      cacheWidth: cachePx,
      cacheHeight: cachePx,
      errorBuilder: (_, __, ___) =>
      errorWidget ??
          Container(
            color: Colors.white10,
            child: const Icon(Icons.fastfood),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          final all = ['All', ...vm.categories];
          final items = _selected == 'All'
              ? vm.products
              : vm.byCategory(_selected);

          // ── Precompute per-screen layout values ONCE per rebuild.
          //    itemBuilder used to call _Resp on every item, which
          //    triggers a MediaQuery lookup per item per frame.
          final metrics = _ListMetrics.of(context);

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(
                MediaQuery.of(context).padding.top + _Resp.s(context, 62),
              ),
              child: _buildAppBar(context),
            ),
            body: Column(
              children: [
                _buildCategoryChips(context, all),
                SizedBox(height: _Resp.s(context, 4)),
                Expanded(
                  child: vm.loading
                      ? _skeleton(context, metrics)
                      : items.isEmpty
                      ? _emptyState(context)
                      : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      _Resp.s(context, 16),
                      _Resp.s(context, 8),
                      _Resp.s(context, 16),
                      _Resp.s(context, 24),
                    ),
                    physics: const BouncingScrollPhysics(),
                    // Perf: keep only visible tiles alive.
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final tile =
                      _menuTile(context, items[i], metrics);
                      // ── THE FIX ──
                      // Only the first ~6 items animate in.
                      // Items scrolling into view later appear
                      // instantly — animating on every re-entry
                      // is what caused the scroll lag.
                      if (i < 6) {
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 30 * i),
                          child: tile,
                        );
                      }
                      return tile;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // APPBAR — gradient + search icon
  // ============================================================
  Widget _buildAppBar(BuildContext context) {
    final barHeight = _Resp.s(context, 62);
    final canPop = Navigator.of(context).canPop();

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
                    left: canPop ? _Resp.s(context, 4) : _Resp.s(context, 12),
                  ),
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _Resp.t(context, 20),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                icon: Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: _Resp.s(context, 22),
                ),
                splashRadius: _Resp.s(context, 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY CHIPS
  // ============================================================
  Widget _buildCategoryChips(BuildContext context, List<String> all) {
    return SizedBox(
      height: _Resp.s(context, 56),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: _Resp.s(context, 16)),
        itemCount: all.length,
        separatorBuilder: (_, __) => SizedBox(width: _Resp.s(context, 8)),
        itemBuilder: (_, i) {
          final cat = all[i];
          final selected = cat == _selected;
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: selected ? _Palette.accent : Colors.white,
                borderRadius: BorderRadius.circular(_Resp.s(context, 30)),
                border: Border.all(
                  color: selected ? _Palette.accent : AppColors.divider,
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(_Resp.s(context, 30)),
                  onTap: () => setState(() => _selected = cat),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _Resp.s(context, 18),
                      vertical: _Resp.s(context, 10),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: _Resp.t(context, 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // MENU TILE
  // ------------------------------------------------------------
  // Now takes a precomputed _ListMetrics — no MediaQuery lookups
  // inside the hot scroll path.
  // ============================================================
  Widget _menuTile(
      BuildContext context,
      ProductModel p,
      _ListMetrics m,
      ) {
    return Padding(
      padding: EdgeInsets.only(bottom: m.itemBottomPad),
      child: PressableScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(m.radius16),
            boxShadow: [
              BoxShadow(
                color: _Palette.blackA05,
                blurRadius: m.shadowBlur,
                offset: Offset(0, m.shadowOffsetY),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(m.radius16),
                ),
                child: Hero(
                  tag: 'product_${p.id}',
                  child: _buildSmartImage(
                    context,
                    p.imageUrl,
                    width: m.thumb,
                    height: m.thumb,
                    cachePx: m.thumbPx,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      width: m.thumb,
                      height: m.thumb,
                      color: AppColors.divider,
                      child: Icon(
                        Icons.fastfood,
                        size: m.icon30,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(m.innerPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: m.titleFs,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: m.gap4),
                      if (p.description.isNotEmpty)
                        Text(
                          p.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: m.descFs,
                          ),
                        ),
                      SizedBox(height: m.gap8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.hasVariants
                                  ? 'From ${Formatters.price(p.minPrice)}'
                                  : Formatters.price(p.effectivePrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _Palette.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: m.priceFs,
                              ),
                            ),
                          ),
                          SizedBox(width: m.gap6),
                          Container(
                            width: m.arrowBox,
                            height: m.arrowBox,
                            decoration: BoxDecoration(
                              color: _Palette.accent,
                              borderRadius: BorderRadius.circular(m.radius10),
                              boxShadow: [
                                BoxShadow(
                                  color: _Palette.accentA30,
                                  blurRadius: m.shadowBlurSmall,
                                  offset: Offset(0, m.shadowOffsetYSmall),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: m.icon18,
                            ),
                          ),
                        ],
                      ),
                    ],
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
  // EMPTY STATE
  // ============================================================
  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_Resp.s(context, 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _Resp.s(context, 88),
              height: _Resp.s(context, 88),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Palette.accentA10,
              ),
              child: Icon(
                Icons.fastfood_outlined,
                size: _Resp.s(context, 40),
                color: _Palette.accent,
              ),
            ),
            SizedBox(height: _Resp.s(context, 18)),
            Text(
              'No items found',
              style: TextStyle(
                fontSize: _Resp.t(context, 15),
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: _Resp.s(context, 6)),
            Text(
              'Try a different category.',
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
  Widget _skeleton(BuildContext context, _ListMetrics m) {
    return ListView.builder(
      padding: EdgeInsets.all(_Resp.s(context, 16)),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(bottom: m.itemBottomPad),
        child: Row(
          children: [
            ShimmerBox(
              height: m.thumb,
              width: m.thumb,
              radius: BorderRadius.all(Radius.circular(m.radius16)),
            ),
            SizedBox(width: _Resp.s(context, 12)),
            Expanded(
              child: ShimmerBox(height: _Resp.s(context, 80)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRE-COMPUTED LIST METRICS
// ------------------------------------------------------------
// All the layout numbers a menu tile needs, calculated once per
// build instead of once per item. This is what removes the
// per-item MediaQuery lookups from the scroll hot path.
// ============================================================
class _ListMetrics {
  final double thumb;
  final int thumbPx;
  final double itemBottomPad;
  final double innerPad;
  final double radius16;
  final double radius10;
  final double arrowBox;
  final double icon30;
  final double icon18;
  final double titleFs;
  final double descFs;
  final double priceFs;
  final double gap4;
  final double gap6;
  final double gap8;
  final double shadowBlur;
  final double shadowOffsetY;
  final double shadowBlurSmall;
  final double shadowOffsetYSmall;

  const _ListMetrics({
    required this.thumb,
    required this.thumbPx,
    required this.itemBottomPad,
    required this.innerPad,
    required this.radius16,
    required this.radius10,
    required this.arrowBox,
    required this.icon30,
    required this.icon18,
    required this.titleFs,
    required this.descFs,
    required this.priceFs,
    required this.gap4,
    required this.gap6,
    required this.gap8,
    required this.shadowBlur,
    required this.shadowOffsetY,
    required this.shadowBlurSmall,
    required this.shadowOffsetYSmall,
  });

  factory _ListMetrics.of(BuildContext c) {
    final thumb = _Resp.s(c, 96);
    final dpr = MediaQuery.devicePixelRatioOf(c);
    return _ListMetrics(
      thumb: thumb,
      thumbPx: (thumb * dpr).round(),
      itemBottomPad: _Resp.s(c, 12),
      innerPad: _Resp.s(c, 12),
      radius16: _Resp.s(c, 16),
      radius10: _Resp.s(c, 10),
      arrowBox: _Resp.s(c, 32),
      icon30: _Resp.s(c, 30),
      icon18: _Resp.s(c, 18),
      titleFs: _Resp.t(c, 14),
      descFs: _Resp.t(c, 11),
      priceFs: _Resp.t(c, 14),
      gap4: _Resp.s(c, 4),
      gap6: _Resp.s(c, 6),
      gap8: _Resp.s(c, 8),
      shadowBlur: _Resp.s(c, 12),
      shadowOffsetY: _Resp.s(c, 6),
      shadowBlurSmall: _Resp.s(c, 8),
      shadowOffsetYSmall: _Resp.s(c, 4),
    );
  }
}