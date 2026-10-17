import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animations.dart';
import '../../../models/product_model.dart';
import '../../../models/product_variant.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../../../viewmodels/customer/home_viewmodel.dart';
import '../cart/cart_screen.dart';

// ============================================================
// RESPONSIVE SCALING HELPERS
// ============================================================
class _Resp {
  static const double _base = 390.0;

  static double _w(BuildContext c) => MediaQuery.of(c).size.width;
  static double _h(BuildContext c) => MediaQuery.of(c).size.height;

  static double scale(BuildContext c) => (_w(c) / _base).clamp(0.82, 1.30);
  static double textScale(BuildContext c) =>
      (_w(c) / _base).clamp(0.88, 1.18);

  static double s(BuildContext c, double v) => v * scale(c);
  static double t(BuildContext c, double v) => v * textScale(c);

  static double headerHeight(BuildContext c) {
    final h = _h(c);
    final w = _w(c);
    final base = w * 0.72;
    return base.clamp(220.0, h * 0.45).toDouble();
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

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductVariant? _selected;
  late final HomeViewModel _relatedVm;

  @override
  void initState() {
    super.initState();
    if (widget.product.hasVariants) {
      _selected = widget.product.variants.first;
    }
    _relatedVm = HomeViewModel();
    _relatedVm.loadAll();
  }

  @override
  void dispose() {
    _relatedVm.dispose();
    super.dispose();
  }

  double get _unitPrice =>
      _selected?.price ?? widget.product.effectivePrice;

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
    final cart = context.watch<CartViewModel>();
    final product = widget.product;
    final line = cart.getLine(product.id, _selected?.id);

    return ChangeNotifierProvider.value(
      value: _relatedVm,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // -------- Collapsing image header --------
            SliverAppBar(
              expandedHeight: _Resp.headerHeight(context),
              pinned: true,
              backgroundColor: _Palette.headerEnd,
              elevation: 0,
              leading: Padding(
                padding: EdgeInsets.all(_Resp.s(context, 8)),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: _Resp.s(context, 20),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_back,
                        size: _Resp.s(context, 20)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'product_${product.id}',
                  child: _buildSmartImage(
                    context,
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: AppColors.divider,
                      child: Icon(
                        Icons.fastfood,
                        size: _Resp.s(context, 80),
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // -------- Details --------
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_Resp.s(context, 28)),
                  ),
                ),
                transform: Matrix4.translationValues(
                    0, -_Resp.s(context, 22), 0),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _Resp.s(context, 20),
                    _Resp.s(context, 44),
                    _Resp.s(context, 20),
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                fontSize: _Resp.t(context, 22),
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _Resp.s(context, 6)),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _Resp.s(context, 8),
                              vertical: _Resp.s(context, 3),
                            ),
                            decoration: BoxDecoration(
                              color: _Palette.accent.withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(_Resp.s(context, 8)),
                            ),
                            child: Text(
                              product.category,
                              style: TextStyle(
                                color: _Palette.accent,
                                fontSize: _Resp.t(context, 11),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Formatters.price(_unitPrice),
                            style: TextStyle(
                              color: _Palette.accent,
                              fontSize: _Resp.t(context, 22),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      if (product.description.isNotEmpty) ...[
                        SizedBox(height: _Resp.s(context, 14)),
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: _Resp.t(context, 14),
                            height: 1.5,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                      if (product.hasVariants) ...[
                        SizedBox(height: _Resp.s(context, 22)),
                        Text(
                          'Choose size',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: _Resp.t(context, 15),
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: _Resp.s(context, 10)),
                        Wrap(
                          spacing: _Resp.s(context, 10),
                          runSpacing: _Resp.s(context, 10),
                          children: product.variants.map((v) {
                            final active = _selected?.id == v.id;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selected = v),
                              child: AnimatedContainer(
                                duration:
                                const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(
                                  horizontal: _Resp.s(context, 16),
                                  vertical: _Resp.s(context, 12),
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? _Palette.accent
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      _Resp.s(context, 14)),
                                  border: Border.all(
                                    color: active
                                        ? _Palette.accent
                                        : AppColors.divider,
                                  ),
                                  boxShadow: active
                                      ? [
                                    BoxShadow(
                                      color: _Palette.accent
                                          .withOpacity(0.30),
                                      blurRadius:
                                      _Resp.s(context, 12),
                                      offset: Offset(
                                          0, _Resp.s(context, 6)),
                                    ),
                                  ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      v.name,
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : AppColors.textDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: _Resp.t(context, 13),
                                      ),
                                    ),
                                    SizedBox(
                                        height: _Resp.s(context, 2)),
                                    Text(
                                      Formatters.price(v.price),
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white70
                                            : AppColors.textLight,
                                        fontSize:
                                        _Resp.t(context, 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // -------- You may also like --------
            SliverToBoxAdapter(
              child: Consumer<HomeViewModel>(
                builder: (context, vm, _) {
                  final related = vm.related(product, limit: 8);
                  if (related.isEmpty) {
                    return SizedBox(height: _Resp.s(context, 100));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          _Resp.s(context, 20),
                          _Resp.s(context, 8),
                          _Resp.s(context, 20),
                          _Resp.s(context, 12),
                        ),
                        child: Text(
                          'You may also like',
                          style: TextStyle(
                            fontSize: _Resp.t(context, 18),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: _Resp.s(context, 200),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                              horizontal: _Resp.s(context, 16)),
                          itemCount: related.length,
                          itemBuilder: (_, i) => FadeSlideIn(
                            delay: Duration(milliseconds: 60 * i),
                            child: _relatedCard(related[i]),
                          ),
                        ),
                      ),
                      SizedBox(height: _Resp.s(context, 100)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        // -------- Bottom action --------
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              _Resp.s(context, 16),
              _Resp.s(context, 12),
              _Resp.s(context, 16),
              _Resp.s(context, 12),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: _Resp.s(context, 20),
                  offset: Offset(0, -_Resp.s(context, 6)),
                ),
              ],
            ),
            child: line != null
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Existing qty row (unchanged) ──
                Row(
                  children: [
                    _qtyBtn(
                      Icons.remove,
                          () => cart.decrementLine(line),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: _Resp.s(context, 24)),
                      child: Text(
                        '${line.quantity}',
                        style: TextStyle(
                          fontSize: _Resp.t(context, 20),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    _qtyBtn(
                      Icons.add,
                          () => cart.addVariant(product, _selected),
                    ),
                    SizedBox(width: _Resp.s(context, 16)),
                    Expanded(
                      child: Text(
                        Formatters.price(line.lineTotal),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: _Resp.t(context, 20),
                          fontWeight: FontWeight.w800,
                          color: _Palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _Resp.s(context, 10)),
                // ── NEW: View Cart button ──
                SizedBox(
                  height: _Resp.s(context, 48),
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          _Palette.accent,
                          _Palette.accentDeep,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius:
                      BorderRadius.circular(_Resp.s(context, 14)),
                      boxShadow: [
                        BoxShadow(
                          color: _Palette.accent.withOpacity(0.35),
                          blurRadius: _Resp.s(context, 16),
                          offset: Offset(0, _Resp.s(context, 8)),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                        ),
                      ),
                      icon: Icon(
                        Icons.shopping_cart_outlined,
                        size: _Resp.s(context, 20),
                      ),
                      label: Text(
                        'View Cart',
                        style: TextStyle(
                          fontSize: _Resp.t(context, 15),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              _Resp.s(context, 14)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
                : SizedBox(
              height: _Resp.s(context, 54),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _Palette.accent,
                      _Palette.accentDeep,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius:
                  BorderRadius.circular(_Resp.s(context, 14)),
                  boxShadow: [
                    BoxShadow(
                      color: _Palette.accent.withOpacity(0.35),
                      blurRadius: _Resp.s(context, 16),
                      offset: Offset(0, _Resp.s(context, 8)),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      cart.addVariant(product, _selected),
                  icon: Icon(
                    Icons.shopping_bag_outlined,
                    size: _Resp.s(context, 20),
                  ),
                  label: Text(
                    'Add to cart • ${Formatters.price(_unitPrice)}',
                    style: TextStyle(
                      fontSize: _Resp.t(context, 15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          _Resp.s(context, 14)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    final size = _Resp.s(context, 46);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _Palette.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
        child: Icon(icon,
            color: _Palette.accent, size: _Resp.s(context, 22)),
      ),
    );
  }

  Widget _relatedCard(ProductModel p) {
    final cardWidth = _Resp.s(context, 150);
    final imageHeight = _Resp.s(context, 110);

    return PressableScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
      ),
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: _Resp.s(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: _Resp.s(context, 10),
              offset: Offset(0, _Resp.s(context, 4)),
            ),
          ],
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
              padding: EdgeInsets.all(_Resp.s(context, 10)),
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
                  SizedBox(height: _Resp.s(context, 4)),
                  Text(
                    p.hasVariants
                        ? 'From ${Formatters.price(p.minPrice)}'
                        : Formatters.price(p.effectivePrice),
                    style: TextStyle(
                      color: _Palette.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: _Resp.t(context, 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}