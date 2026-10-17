import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../viewmodels/admin/admin_offers_viewmodel.dart';
import 'admin_voucher_form_screen.dart';

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});
  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOffersViewModel>().load();
    });
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
                Icons.local_offer_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Vouchers & Offers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
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
              builder: (_) => const AdminVoucherFormScreen()),
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Voucher',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<AdminOffersViewModel>(
        builder: (context, vm, _) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.vouchers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No vouchers yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap "Add Voucher" to create your first offer',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1000
                  ? 3
                  : constraints.maxWidth >= 640
                  ? 2
                  : 1;

              if (crossAxisCount == 1) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  cacheExtent: 500,
                  addAutomaticKeepAlives: false,
                  itemCount: vm.vouchers.length,
                  itemBuilder: (_, i) =>
                      _voucherCard(context, vm, vm.vouchers[i], constraints),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                cacheExtent: 500,
                addAutomaticKeepAlives: false,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 168,
                ),
                itemCount: vm.vouchers.length,
                itemBuilder: (_, i) =>
                    _voucherCard(context, vm, vm.vouchers[i], constraints),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // SINGLE VOUCHER CARD
  // ============================================================
  Widget _voucherCard(
      BuildContext context,
      AdminOffersViewModel vm,
      dynamic v,
      BoxConstraints constraints,
      ) {
    final isActive = v.isActive as bool;
    final accent = isActive ? Colors.green : Colors.grey;

    // Nicely format the voucher value
    final typeLabel = (v.type as String).toString().toUpperCase();
    final rawValue = v.value;
    final valueLabel = rawValue is num
        ? '${typeLabel == "PERCENT" ? "" : "Rs. "}${rawValue.toStringAsFixed(0)}${typeLabel == "PERCENT" ? "%" : ""}'
        : rawValue.toString();

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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminVoucherFormScreen(voucher: v),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // -------- Top: ticket icon + code + delete --------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.confirmation_number_outlined,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.code as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$valueLabel off',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _iconAction(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        onTap: () => _confirmDelete(context, vm, v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 8),

                  // -------- Bottom: pills --------
                  Row(
                    children: [
                      _pill(
                        label: isActive ? 'ACTIVE' : 'INACTIVE',
                        color: accent,
                      ),
                      const SizedBox(width: 6),
                      _pill(
                        label: typeLabel,
                        color: Colors.blue,
                      ),
                      const Spacer(),
                      Icon(Icons.shopping_cart_outlined,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Min ${Formatters.price(v.minOrder as num)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELETE — confirmation + empty-code guard
  // ============================================================
  Future<void> _confirmDelete(
      BuildContext context,
      AdminOffersViewModel vm,
      dynamic v,
      ) async {
    final code = (v.code as String?)?.trim() ?? '';

    if (code.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete: this voucher has no valid code.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete voucher?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'You are about to delete '),
              TextSpan(
                text: '"$code"',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '.\nThis cannot be undone.'),
            ],
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await vm.deleteVoucher(code);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$code" deleted.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Widget _pill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          // color: color.shade700,
          letterSpacing: 0.4,
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