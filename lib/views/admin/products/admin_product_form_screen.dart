import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../models/product_model.dart';
import '../../../models/product_variant.dart';
import '../../../viewmodels/admin/admin_products_viewmodel.dart';

class AdminProductFormScreen extends StatefulWidget {
  final ProductModel? product;
  const AdminProductFormScreen({super.key, this.product});
  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _image;
  late final TextEditingController _category;
  late final TextEditingController _deal;

  bool _available = true;
  bool _isDeal = false;
  bool _saving = false;

  final List<_VariantRow> _variants = [];

  /// Fallback defaults so the chip list is never empty.
  static const List<String> _defaultCategories = [
    'Pizza',
    'Burger',
    'Pasta',
    'Sandwich',
    'Deals',
    'Student Deals',
    'Drinks',
    'Sides',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _image = TextEditingController(text: p?.imageUrl ?? '');
    _category = TextEditingController(text: p?.category ?? '');

    _price = TextEditingController(
      text: (p?.price != null) ? p!.price!.toStringAsFixed(0) : '',
    );
    _deal = TextEditingController(
      text: (p?.dealPrice != null) ? p!.dealPrice!.toStringAsFixed(0) : '',
    );

    _available = p?.isAvailable ?? true;
    _isDeal = p?.isDeal ?? false;

    if (p != null && p.variants.isNotEmpty) {
      for (final v in p.variants) {
        _variants.add(_VariantRow(
          id: v.id,
          name: v.name,
          price: v.price.toStringAsFixed(0),
        ));
      }
    }

    _image.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _image.dispose();
    _category.dispose();
    _deal.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // CATEGORY LIST — merges products + defaults + current
  // ============================================================
  List<String> _categoriesFor(AdminProductsViewModel vm) {
    final set = <String>{
      ..._defaultCategories,
      ...vm.products
          .map((p) => p.category.trim())
          .where((c) => c.isNotEmpty),
    };
    final current = _category.text.trim();
    if (current.isNotEmpty) set.add(current);
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  void _addVariant() {
    setState(() {
      _variants.add(_VariantRow(
        id: 'v${DateTime.now().millisecondsSinceEpoch}',
        name: '',
        price: '',
      ));
    });
  }

  void _removeVariant(int i) {
    setState(() {
      _variants[i].dispose();
      _variants.removeAt(i);
    });
  }

  Future<void> _save() async {
    final nameTrim = _name.text.trim();
    final categoryTrim = _category.text.trim();

    if (nameTrim.isEmpty) return _toast('Name is required');
    if (categoryTrim.isEmpty) return _toast('Category is required');

    final hasVariants = _variants.isNotEmpty;

    if (!hasVariants && _price.text.trim().isEmpty) {
      return _toast('Either add a price or add at least one variant');
    }

    final builtVariants = <ProductVariant>[];
    for (int i = 0; i < _variants.length; i++) {
      final row = _variants[i];
      final vName = row.nameCtrl.text.trim();
      final vPrice = double.tryParse(row.priceCtrl.text.trim());
      if (vName.isEmpty || vPrice == null || vPrice <= 0) {
        return _toast('Variant ${i + 1} needs a name and a valid price');
      }
      builtVariants.add(ProductVariant(
        id: row.id,
        name: vName,
        price: vPrice,
      ));
    }

    setState(() => _saving = true);

    final keywords = <String>{
      ...nameTrim
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty),
      ...categoryTrim
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty),
    }.toList();

    final product = ProductModel(
      id: widget.product?.id ?? '',
      name: nameTrim,
      description: _desc.text.trim(),
      category: categoryTrim,
      imageUrl: _image.text.trim(),
      variants: builtVariants,
      price: hasVariants ? null : double.tryParse(_price.text.trim()),
      isAvailable: _available,
      isDeal: _isDeal,
      dealPrice: _isDeal ? double.tryParse(_deal.text.trim()) : null,
      searchKeywords: keywords,
    );

    final vm = context.read<AdminProductsViewModel>();
    final ok = await vm.saveProduct(product, docId: widget.product?.id);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved')),
      );
    } else {
      _toast(vm.error ?? 'Failed to save product');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

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
              child: Icon(
                isEdit ? Icons.edit_outlined : Icons.add_box_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? 'Edit Product' : 'Add Product',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<AdminProductsViewModel>(
        builder: (context, vm, _) {
          final hasVariants = _variants.isNotEmpty;
          final categories = _categoriesFor(vm);
          final selectedCategory = _category.text.trim();

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
              constraints.maxWidth >= 720 ? 640.0 : double.infinity;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ============================================================
                        // SECTION 1 — BASIC INFO
                        // ============================================================
                        _sectionCard(
                          icon: Icons.info_outline,
                          title: 'Basic Information',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomTextField(
                                controller: _name,
                                label: 'Name',
                                hint: 'e.g. Behari Kabab Pizza',
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                controller: _desc,
                                label: 'Description (optional)',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),

                              // ---------- Category chips ----------
                              Row(
                                children: [
                                  Icon(Icons.category_outlined,
                                      size: 15,
                                      color: AppColors.secondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Category',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _categoryChips(categories, selectedCategory),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      selectedCategory.isEmpty
                                          ? 'Tap a category to select it.'
                                          : 'Selected: $selectedCategory',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: selectedCategory.isEmpty
                                            ? Colors.grey.shade600
                                            : AppColors.secondary,
                                        fontWeight: selectedCategory.isEmpty
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ============================================================
                        // SECTION 2 — IMAGE
                        // ============================================================
                        _sectionCard(
                          icon: Icons.image_outlined,
                          title: 'Product Image',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 84,
                                      height: 84,
                                      color: const Color(0xFFF1F2F6),
                                      alignment: Alignment.center,
                                      child: _imagePreview(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _image,
                                      label: 'Image URL (Cloudinary)',
                                      hint: 'https://...',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Paste a Cloudinary URL or an assets/ path. Leave empty to use the default placeholder.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ============================================================
                        // SECTION 3 — PRICING
                        // ============================================================
                        _sectionCard(
                          icon: Icons.local_offer_outlined,
                          title: 'Pricing',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasVariants)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary
                                        .withOpacity(0.1),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_variants.length} variant${_variants.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: _addVariant,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  'Add variant',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.secondary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (hasVariants) ...[
                                ...List.generate(
                                    _variants.length, (i) => _variantCard(i)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 14,
                                          color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Single price field is hidden while variants exist.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.blue.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else
                                CustomTextField(
                                  controller: _price,
                                  label: 'Price',
                                  keyboard: TextInputType.number,
                                  hint:
                                  'Required when there are no variants',
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ============================================================
                        // SECTION 4 — AVAILABILITY & DEALS
                        // ============================================================
                        _sectionCard(
                          icon: Icons.tune_outlined,
                          title: 'Availability & Deals',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _switchRow(
                                icon: Icons.visibility_outlined,
                                title: 'Available',
                                subtitle:
                                'Show this product in the customer menu',
                                value: _available,
                                onChanged: (v) =>
                                    setState(() => _available = v),
                              ),
                              Divider(
                                  height: 1, color: Colors.grey.shade200),
                              _switchRow(
                                icon: Icons
                                    .local_fire_department_outlined,
                                title: 'Is deal',
                                subtitle:
                                'Mark this product as a special deal',
                                value: _isDeal,
                                onChanged: (v) =>
                                    setState(() => _isDeal = v),
                              ),
                              if (_isDeal) ...[
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: _deal,
                                  label: 'Deal price',
                                  keyboard: TextInputType.number,
                                  hint: 'Discounted price',
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ============================================================
                        // SAVE
                        // ============================================================
                        CustomButton(
                          label: isEdit ? 'Save Changes' : 'Create Product',
                          loading: _saving,
                          onPressed: _save,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // CATEGORY CHIPS
  // ============================================================
  Widget _categoryChips(List<String> categories, String selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () {
            setState(() {
              _category.text = c;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondary
                  : const Color(0xFFF4F5F9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? AppColors.secondary
                    : Colors.grey.shade300,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  c,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================
  Widget _imagePreview() {
    final url = _image.text.trim();
    if (url.isEmpty) {
      return Icon(Icons.image_outlined,
          size: 32, color: Colors.grey.shade400);
    }

    final bool isAsset =
        url.startsWith('assets/') || url.startsWith('packages/');

    if (isAsset) {
      return Image.asset(
        url,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined,
            size: 28, color: Colors.grey.shade400),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: 84,
      height: 84,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Icon(Icons.broken_image_outlined,
          size: 28, color: Colors.grey.shade400),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // VARIANT CARD
  // ============================================================
  Widget _variantCard(int i) {
    final row = _variants[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Small / Medium / Large',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            tooltip: 'Remove variant',
            icon: Icon(Icons.delete_outline,
                color: Colors.red.shade600, size: 20),
            onPressed: () => _removeVariant(i),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SWITCH ROW
  // ============================================================
  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color:
              (value ? Colors.green : Colors.grey).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color:
              value ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ---------- Variant row helper (unchanged) ----------
class _VariantRow {
  final String id;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;

  _VariantRow({
    required this.id,
    required String name,
    required String price,
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(text: price);

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}