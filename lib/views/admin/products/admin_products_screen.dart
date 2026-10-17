import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animations.dart';
import '../../../models/product_model.dart';
import '../../../viewmodels/admin/admin_products_viewmodel.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  String _query = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProductsViewModel>().load();
    });
  }

  // ============================================================
  // DELETE — with confirmation + empty-id guard
  // ============================================================
  Future<void> _confirmDelete(ProductModel p, AdminProductsViewModel vm) async {
    // Guard #1: never delete a doc with no ID
    if (p.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: product has no ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Guard #2: explicit user confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete product?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'This cannot be undone.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Guard #3: capture context safely before async
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.deleteProduct(p.id);

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? '${p.name} deleted' : 'Delete failed'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  // ============================================================
  // SMART IMAGE HELPER
  // ============================================================
  Widget _buildSmartImage(
      BuildContext context,
      String url, {
        double? height,
        double? width,
        BoxFit fit = BoxFit.cover,
        Widget? errorWidget,
      }) {
    final trimmed = url.trim();

    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int? cacheWidth =
    (width != null && width > 0) ? (width * pixelRatio).round() : null;
    final int? cacheHeight =
    (height != null && height > 0) ? (height * pixelRatio).round() : null;

    final fallback = errorWidget ??
        Container(
          height: height,
          width: width,
          color: const Color(0xFFF1F2F6),
          alignment: Alignment.center,
          child: Icon(Icons.fastfood_outlined,
              size: (height ?? 40) * 0.45, color: Colors.black26),
        );

    if (trimmed.isEmpty) return fallback;

    final bool isAsset =
        trimmed.startsWith('assets/') || trimmed.startsWith('packages/');

    if (isAsset) {
      return Image.asset(
        trimmed,
        height: height,
        width: width,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      height: height,
      width: width,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 80),
      useOldImageOnUrlChange: true,
      placeholder: (_, __) => ShimmerBox(
        height: height ?? 60,
        width: width,
      ),
      errorWidget: (_, __, ___) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Products',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminProductFormScreen(),
          ),
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<AdminProductsViewModel>(
        builder: (context, vm, _) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = <String>{
            'All',
            ...vm.products.map((p) => p.category).where((c) => c.isNotEmpty),
          }.toList();

          final list = vm.products.where((p) {
            final matchesQuery =
                _query.isEmpty || p.name.toLowerCase().contains(_query);
            final matchesCategory =
                _selectedCategory == 'All' || p.category == _selectedCategory;
            return matchesQuery && matchesCategory;
          }).toList();

          return Column(
            children: [
              // Search bar
              Container(
                color: AppColors.secondary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: TextField(
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.grey.shade600, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase().trim()),
                ),
              ),

              // Category slider
              Container(
                color: AppColors.secondary,
                padding: const EdgeInsets.only(bottom: 14),
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = categories[i];
                      final selected = c == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              c,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.secondary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // List / Grid
              Expanded(
                child: list.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _query.isEmpty && _selectedCategory == 'All'
                            ? 'No products yet'
                            : 'No matching products',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_query.isNotEmpty ||
                          _selectedCategory != 'All') ...[
                        const SizedBox(height: 6),
                        Text(
                          'Try a different search or category',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                    : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                    constraints.maxWidth >= 1000
                        ? 3
                        : constraints.maxWidth >= 640
                        ? 2
                        : 1;

                    if (crossAxisCount == 1) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            12, 12, 12, 100),
                        cacheExtent: 500,
                        addAutomaticKeepAlives: false,
                        itemCount: list.length,
                        itemBuilder: (_, i) => _productCard(
                            context, list[i], vm, constraints),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          12, 12, 12, 100),
                      cacheExtent: 500,
                      addAutomaticKeepAlives: false,
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 148,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _productCard(
                          context, list[i], vm, constraints),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // -------- Single product card --------
  Widget _productCard(
      BuildContext context,
      ProductModel p,
      AdminProductsViewModel vm,
      BoxConstraints constraints,
      ) {
    final priceLabel = p.hasVariants
        ? 'From ${Formatters.price(p.minPrice)}'
        : Formatters.price(p.effectivePrice);

    final isAvailable = p.isAvailable;
    final accentColor = isAvailable ? Colors.green : Colors.grey;

    return RepaintBoundary(
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFFF1F2F6),
                      child: Hero(
                        tag: 'admin_product_${p.id}',
                        child: _buildSmartImage(
                          context,
                          p.imageUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            width: 52,
                            height: 52,
                            color: accentColor.withOpacity(0.12),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.fastfood_outlined,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              priceLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                            if (p.category.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  p.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (p.hasVariants) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${p.variants.length} variant${p.variants.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: isAvailable,
                      activeColor: Colors.green,
                      onChanged: (v) => vm.toggleAvailable(p, v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAvailable ? 'AVAILABLE' : 'HIDDEN',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isAvailable
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  if (p.isDeal) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DEAL',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  _iconAction(
                    icon: Icons.edit_outlined,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminProductFormScreen(product: p),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _iconAction(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    // ⭐ NEW: goes through confirmation + ID guard
                    onTap: () => _confirmDelete(p, vm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}