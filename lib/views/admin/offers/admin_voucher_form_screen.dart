import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../models/voucher_model.dart';
import '../../../viewmodels/admin/admin_offers_viewmodel.dart';

class AdminVoucherFormScreen extends StatefulWidget {
  final VoucherModel? voucher;
  const AdminVoucherFormScreen({super.key, this.voucher});
  @override
  State<AdminVoucherFormScreen> createState() =>
      _AdminVoucherFormScreenState();
}

class _AdminVoucherFormScreenState extends State<AdminVoucherFormScreen> {
  late final TextEditingController _code;
  late final TextEditingController _value;
  late final TextEditingController _minOrder;
  late final TextEditingController _maxDiscount;
  String _type = 'flat';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    _code = TextEditingController(text: v?.code ?? '');
    _value = TextEditingController(
        text: v != null ? v.value.toStringAsFixed(0) : '');
    _minOrder = TextEditingController(
        text: v != null ? v.minOrder.toStringAsFixed(0) : '0');
    _maxDiscount = TextEditingController(
        text: v?.maxDiscount != null
            ? v!.maxDiscount!.toStringAsFixed(0)
            : '');
    _type = v?.type ?? 'flat';
  }

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    _minOrder.dispose();
    _maxDiscount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_code.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher code is required')),
      );
      return;
    }
    if (_value.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Value is required')),
      );
      return;
    }

    setState(() => _saving = true);
    final v = VoucherModel(
      code: _code.text.trim().toUpperCase(),
      type: _type,
      value: double.tryParse(_value.text) ?? 0,
      minOrder: double.tryParse(_minOrder.text) ?? 0,
      maxDiscount: _maxDiscount.text.trim().isEmpty
          ? null
          : double.tryParse(_maxDiscount.text),
      usageLimit: widget.voucher?.usageLimit ?? 0,
      usedCount: widget.voucher?.usedCount ?? 0,
      isActive: true,
      expiresAt: widget.voucher?.expiresAt,
    );

    final vm = context.read<AdminOffersViewModel>();
    final ok = await vm.saveVoucher(v);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Failed to save voucher')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.voucher != null;

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
                isEdit
                    ? Icons.edit_outlined
                    : Icons.confirmation_number_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? 'Edit Voucher' : 'Add Voucher',
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
      body: LayoutBuilder(
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
                    // SECTION 1 — VOUCHER DETAILS
                    // ============================================================
                    _sectionCard(
                      icon: Icons.local_offer_outlined,
                      title: 'Voucher Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _code,
                            label: 'Code',
                            hint: 'e.g. SAVE10',
                          ),
                          const SizedBox(height: 16),

                          // ---------- Type chips ----------
                          Row(
                            children: [
                              Icon(Icons.tune_outlined,
                                  size: 15,
                                  color: AppColors.secondary),
                              const SizedBox(width: 8),
                              Text(
                                'Discount Type',
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
                          Row(
                            children: [
                              Expanded(
                                child: _typeChip(
                                  label: 'Flat Rs. off',
                                  value: 'flat',
                                  icon: Icons.currency_rupee,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _typeChip(
                                  label: 'Percent % off',
                                  value: 'percent',
                                  icon: Icons.percent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ============================================================
                    // SECTION 2 — VALUE & LIMITS
                    // ============================================================
                    _sectionCard(
                      icon: Icons.calculate_outlined,
                      title: 'Value & Limits',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _value,
                            label: _type == 'percent'
                                ? 'Value (%)'
                                : 'Value (Rs.)',
                            keyboard: TextInputType.number,
                            hint: _type == 'percent'
                                ? 'e.g. 20'
                                : 'e.g. 200',
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _minOrder,
                            label: 'Minimum order',
                            keyboard: TextInputType.number,
                            hint: 'Order amount required to use this code',
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _maxDiscount,
                            label: 'Max discount (optional)',
                            keyboard: TextInputType.number,
                            hint:
                            'Cap the discount — useful for % vouchers',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ============================================================
                    // SAVE
                    // ============================================================
                    CustomButton(
                      label: isEdit ? 'Save Changes' : 'Create Voucher',
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
      ),
    );
  }

  // ============================================================
  // TYPE CHIP
  // ============================================================
  Widget _typeChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : const Color(0xFFF4F5F9),
          borderRadius: BorderRadius.circular(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
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
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}