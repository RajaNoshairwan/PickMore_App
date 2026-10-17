import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
}

// ============================================================
// LOCAL PALETTE (mirrors HomeScreen)
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF6B35);
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _vm = HomeViewModel();
  List<ProductModel> _results = [];

  /// Live suggestion chips — computed once per keystroke, not per build.
  List<String> _suggestions = const [];

  /// Snapshot of top products taken once after first load.
  /// Avoids re-reading `_vm.products` on every rebuild.
  List<ProductModel> _popular = const [];

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onVmChanged);
    _vm.loadAll();
  }

  void _onVmChanged() {
    // Take one snapshot after the initial load, then stop.
    if (!_vm.loading && _popular.isEmpty && _vm.products.isNotEmpty) {
      _popular = _vm.products.take(5).toList(growable: false);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _controller.dispose();
    _vm.dispose();
    super.dispose();
  }

  // ============================================================
  // QUERY → suggestions + results in one pass
  // ============================================================
  void _onQueryChanged(String v) {
    final trimmed = v.trim();
    final results = _vm.search(trimmed);

    // Suggestions: product names that start with the query (max 6).
    List<String> sug = const [];
    if (trimmed.isNotEmpty) {
      final q = trimmed.toLowerCase();
      final seen = <String>{};
      final out = <String>[];
      for (final p in _vm.products) {
        final name = p.name;
        if (name.toLowerCase().startsWith(q) && seen.add(name)) {
          out.add(name);
          if (out.length == 6) break;
        }
      }
      sug = out;
    }

    setState(() {
      _results = results;
      _suggestions = sug;
    });
  }

  void _applySuggestion(String text) {
    _controller.text = text;
    _controller.selection =
        TextSelection.collapsed(offset: text.length);
    _onQueryChanged(text);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _results = [];
      _suggestions = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).padding.top + _Resp.s(context, 72),
        ),
        child: Container(
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
              padding: EdgeInsets.fromLTRB(
                _Resp.s(context, 8),
                _Resp.s(context, 6),
                _Resp.s(context, 16),
                _Resp.s(context, 12),
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
                  Expanded(child: _searchBar(context)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _controller.text.trim().isEmpty
          ? _suggestionsEmptyState(context)
          : _resultsView(context),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================
  Widget _searchBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _Resp.s(context, 14),
        vertical: _Resp.s(context, 2),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.textLight,
            size: _Resp.s(context, 20),
          ),
          SizedBox(width: _Resp.s(context, 10)),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              // Perf: avoid rebuilding the whole tree on every keystroke.
              // The setState happens inside _onQueryChanged, once per change.
              style: TextStyle(
                fontSize: _Resp.t(context, 14),
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search menu...',
                hintStyle: TextStyle(
                  fontSize: _Resp.t(context, 14),
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: _Resp.s(context, 14),
                ),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _clear,
              child: Icon(
                Icons.close,
                color: AppColors.textLight,
                size: _Resp.s(context, 18),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE — suggestions
  // ============================================================
  Widget _suggestionsEmptyState(BuildContext context) {
    final categories = _vm.categories;
    final popular = _popular;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        _Resp.s(context, 20),
        _Resp.s(context, 20),
        _Resp.s(context, 20),
        _Resp.s(context, 24),
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: _Palette.accent,
              size: _Resp.s(context, 18),
            ),
            SizedBox(width: _Resp.s(context, 6)),
            Text(
              'Popular searches',
              style: TextStyle(
                fontSize: _Resp.t(context, 15),
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        SizedBox(height: _Resp.s(context, 12)),
        Wrap(
          spacing: _Resp.s(context, 8),
          runSpacing: _Resp.s(context, 8),
          children: categories.map((cat) {
            return GestureDetector(
              onTap: () => _applySuggestion(cat),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _Resp.s(context, 14),
                  vertical: _Resp.s(context, 8),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_Resp.s(context, 20)),
                  border: Border.all(
                    color: _Palette.accent.withOpacity(0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: _Resp.s(context, 8),
                      offset: Offset(0, _Resp.s(context, 3)),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search,
                      color: _Palette.accent,
                      size: _Resp.s(context, 13),
                    ),
                    SizedBox(width: _Resp.s(context, 6)),
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: _Resp.t(context, 12.5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: _Resp.s(context, 26)),

        if (popular.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: _Palette.accent,
                size: _Resp.s(context, 18),
              ),
              SizedBox(width: _Resp.s(context, 6)),
              Text(
                'Trending now',
                style: TextStyle(
                  fontSize: _Resp.t(context, 15),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: _Resp.s(context, 12)),
          ...popular.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return FadeSlideIn(
              delay: Duration(milliseconds: 40 * i),
              child: _suggestionTile(context, p),
            );
          }),
        ],
      ],
    );
  }

  // ============================================================
  // SUGGESTION TILE — now with product image
  // ============================================================
  Widget _suggestionTile(BuildContext context, ProductModel p) {
    final price = p.hasVariants ? p.minPrice : p.effectivePrice;
    final thumb = _Resp.s(context, 44);

    return Padding(
      padding: EdgeInsets.only(bottom: _Resp.s(context, 10)),
      child: PressableScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: p),
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(_Resp.s(context, 8)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: _Resp.s(context, 10),
                offset: Offset(0, _Resp.s(context, 4)),
              ),
            ],
          ),
          child: Row(
            children: [
              _thumb(context, p, thumb),
              SizedBox(width: _Resp.s(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _Resp.t(context, 13.5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 2)),
                    Text(
                      p.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _Resp.t(context, 11),
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _Resp.s(context, 8)),
              Text(
                Formatters.price(price),
                style: TextStyle(
                  color: _Palette.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: _Resp.t(context, 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESULTS VIEW — suggestion strip + list
  // ============================================================
  Widget _resultsView(BuildContext context) {
    final sug = _suggestions;
    final hasResults = _results.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sug.isNotEmpty) ...[
          SizedBox(height: _Resp.s(context, 12)),
          SizedBox(
            height: _Resp.s(context, 36),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: _Resp.s(context, 16),
              ),
              itemCount: sug.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: _Resp.s(context, 8)),
              itemBuilder: (_, i) {
                final s = sug[i];
                return GestureDetector(
                  onTap: () => _applySuggestion(s),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _Resp.s(context, 14),
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(_Resp.s(context, 20)),
                      border: Border.all(
                        color: _Palette.accent.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.north_west_rounded,
                          color: _Palette.accent,
                          size: _Resp.s(context, 12),
                        ),
                        SizedBox(width: _Resp.s(context, 6)),
                        Text(
                          s,
                          style: TextStyle(
                            fontSize: _Resp.t(context, 12),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: _Resp.s(context, 10)),
        ],

        Expanded(
          child: !hasResults
              ? _noResults(context)
              : ListView.builder(
            // Perf: reuse existing list items when possible.
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            padding: EdgeInsets.fromLTRB(
              _Resp.s(context, 16),
              _Resp.s(context, 4),
              _Resp.s(context, 16),
              _Resp.s(context, 24),
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: _results.length,
            itemBuilder: (_, i) => FadeSlideIn(
              delay: Duration(milliseconds: 30 * (i % 8)),
              child: _resultTile(context, _results[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESULT TILE — now with product image
  // ============================================================
  Widget _resultTile(BuildContext context, ProductModel p) {
    final price = p.hasVariants ? p.minPrice : p.effectivePrice;
    final thumb = _Resp.s(context, 52);

    return Padding(
      padding: EdgeInsets.only(bottom: _Resp.s(context, 10)),
      child: PressableScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: p),
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(_Resp.s(context, 8)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: _Resp.s(context, 10),
                offset: Offset(0, _Resp.s(context, 4)),
              ),
            ],
          ),
          child: Row(
            children: [
              _thumb(context, p, thumb),
              SizedBox(width: _Resp.s(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: _Resp.t(context, 13.5),
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 3)),
                    Text(
                      p.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _Resp.t(context, 11.5),
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _Resp.s(context, 8)),
              Text(
                Formatters.price(price),
                style: TextStyle(
                  color: _Palette.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: _Resp.t(context, 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHARED THUMBNAIL
  // ------------------------------------------------------------
  // • Detects whether the URL is a LOCAL ASSET or a NETWORK URL.
  // • Decodes the image at exactly the size it will be painted,
  //   so the GPU never uploads a full-res photo for a 44 px tile.
  // • Uses CachedNetworkImage for network URLs (future Cloudinary).
  // • Falls back to a themed icon if the URL is empty or fails.
  // ============================================================
  Widget _thumb(BuildContext context, ProductModel p, double size) {
    final radius = BorderRadius.circular(_Resp.s(context, 10));
    final url = p.imageUrl;

    if (url.isEmpty) {
      return _thumbPlaceholder(context, size, radius);
    }

    // Decode at device pixel ratio × display size for crisp but cheap paint.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final px = (size * dpr).round();

    // Network image (future Cloudinary URLs)
    if (url.startsWith('http')) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: px,
          memCacheHeight: px,
          fadeInDuration: const Duration(milliseconds: 120),
          fadeOutDuration: Duration.zero,
          placeholder: (_, __) => Container(
            width: size,
            height: size,
            color: _Palette.accent.withOpacity(0.08),
          ),
          errorWidget: (_, __, ___) =>
              _thumbPlaceholder(context, size, radius),
        ),
      );
    }

    // Local asset (current setup)
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: px,
        cacheHeight: px,
        errorBuilder: (_, __, ___) =>
            _thumbPlaceholder(context, size, radius),
      ),
    );
  }

  Widget _thumbPlaceholder(
      BuildContext context, double size, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _Palette.accent.withOpacity(0.10),
        borderRadius: radius,
      ),
      child: Icon(
        Icons.fastfood_outlined,
        color: _Palette.accent,
        size: size * 0.5,
      ),
    );
  }

  // ============================================================
  // NO RESULTS
  // ============================================================
  Widget _noResults(BuildContext context) {
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
                color: _Palette.accent.withOpacity(0.10),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: _Resp.s(context, 40),
                color: _Palette.accent,
              ),
            ),
            SizedBox(height: _Resp.s(context, 18)),
            Text(
              'No matches found',
              style: TextStyle(
                fontSize: _Resp.t(context, 15),
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: _Resp.s(context, 6)),
            Text(
              'Try a different keyword or tap a suggestion above.',
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
}