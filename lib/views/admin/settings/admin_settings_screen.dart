import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/store_settings.dart';
import '../../../viewmodels/admin/admin_settings_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../feedback/admin_feedback_screen.dart';
import 'admin_edit_settings_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late final AdminSettingsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AdminSettingsViewModel();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminEditSettingsScreen()),
    );
    // Reload after returning so the display reflects edits
    if (!mounted) return;
    _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminSettingsViewModel>.value(
      value: _vm,
      child: Consumer<AdminSettingsViewModel>(
        builder: (context, vm, _) {
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
                    child: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Edit settings',
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: _openEdit,
                ),
              ],
            ),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: () => vm.load(),
              color: AppColors.secondary,
              child: vm.store == null
                  ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_outlined,
                              size: 56,
                              color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No store settings found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap the edit icon to add details',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
                  : _buildContent(context, vm.store!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, StoreSettings s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        // -------- CONTACT --------
        _sectionCard(
          icon: Icons.contact_phone_outlined,
          title: 'Contact',
          children: [
            _infoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: s.phoneNumber.isEmpty ? '—' : s.phoneNumber,
            ),
            _infoRow(
              icon: Icons.chat_outlined,
              label: 'WhatsApp',
              value: s.whatsappNumber.isEmpty ? '—' : s.whatsappNumber,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // -------- LOCATION --------
        _sectionCard(
          icon: Icons.location_on_outlined,
          title: 'Location',
          children: [
            _infoRow(
              icon: Icons.store_mall_directory_outlined,
              label: 'Store address',
              value: s.storeAddress.isEmpty ? '—' : s.storeAddress,
              multiline: true,
            ),
            _infoRow(
              icon: Icons.my_location_outlined,
              label: 'Coordinates',
              value: (s.storeLat == 0 && s.storeLng == 0)
                  ? '—'
                  : '${s.storeLat.toStringAsFixed(5)}, '
                  '${s.storeLng.toStringAsFixed(5)}',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // -------- FEES --------
        _sectionCard(
          icon: Icons.payments_outlined,
          title: 'Fees',
          children: [
            _infoRow(
              icon: Icons.delivery_dining_outlined,
              label: 'Delivery fee',
              value: 'Rs. ${s.deliveryFee.toStringAsFixed(0)}',
            ),
            _infoRow(
              icon: Icons.shopping_bag_outlined,
              label: 'Takeaway fee',
              value: 'Rs. ${s.takeawayFee.toStringAsFixed(0)}',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // -------- STORE INFO --------
        _sectionCard(
          icon: Icons.info_outline,
          title: 'Store Info',
          children: [
            _infoRow(
              icon: Icons.access_time,
              label: 'Opening hours',
              value: s.openingHours.isEmpty ? '—' : s.openingHours,
            ),
            _infoRow(
              icon: Icons.description_outlined,
              label: 'About',
              value: s.aboutText.isEmpty ? '—' : s.aboutText,
              multiline: true,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // -------- ACCOUNT ACTIONS --------
        Container(
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
          child: Column(
            children: [
              _actionTile(
                icon: Icons.feedback_outlined,
                title: 'View customer feedback',
                iconColor: AppColors.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminFeedbackScreen(),
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              _actionTile(
                icon: Icons.lock_outline,
                title: 'Change password',
                iconColor: AppColors.secondary,
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.hourglass_top_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Change password is coming soon',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.secondary,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              _actionTile(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => context.read<AuthViewModel>().signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
        multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // -------- CHANGE PASSWORD (unchanged logic) --------
  void _changePassword(BuildContext context) {
    final current = TextEditingController();
    final next = TextEditingController();
    final rootContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Change password',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final cur = current.text.trim();
              final nxt = next.text.trim();

              if (cur.isEmpty || nxt.isEmpty) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                      content: Text('Both fields are required')),
                );
                return;
              }
              if (nxt.length < 6) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'New password must be at least 6 characters')),
                );
                return;
              }

              final auth = rootContext.read<AuthViewModel>();
              final ok = await auth.changePassword(
                currentPassword: cur,
                newPassword: nxt,
              );
              if (!rootContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(rootContext).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Password updated'
                      : (auth.error ?? 'Update failed')),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}