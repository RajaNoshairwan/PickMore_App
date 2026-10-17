import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../models/store_settings.dart';
import '../../../viewmodels/admin/admin_settings_viewmodel.dart';

class AdminEditSettingsScreen extends StatefulWidget {
  const AdminEditSettingsScreen({super.key});
  @override
  State<AdminEditSettingsScreen> createState() =>
      _AdminEditSettingsScreenState();
}

class _AdminEditSettingsScreenState extends State<AdminEditSettingsScreen> {
  late final AdminSettingsViewModel _vm;
  final _delivery = TextEditingController();
  final _takeaway = TextEditingController();
  final _whatsapp = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _hours = TextEditingController();
  final _about = TextEditingController();

  bool _saving = false;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _vm = AdminSettingsViewModel();
    _vm.addListener(_fill);
    _vm.load();
  }

  void _fill() {
    final s = _vm.store;
    if (s == null || _filled) return;
    _filled = true;
    _delivery.text = s.deliveryFee.toStringAsFixed(0);
    _takeaway.text = s.takeawayFee.toStringAsFixed(0);
    _whatsapp.text = s.whatsappNumber;
    _phone.text = s.phoneNumber;
    _address.text = s.storeAddress;
    _lat.text = s.storeLat.toString();
    _lng.text = s.storeLng.toString();
    _hours.text = s.openingHours;
    _about.text = s.aboutText;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_fill);
    _vm.dispose();
    _delivery.dispose();
    _takeaway.dispose();
    _whatsapp.dispose();
    _phone.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _hours.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final s = StoreSettings(
      deliveryFee: double.tryParse(_delivery.text) ?? 0,
      takeawayFee: double.tryParse(_takeaway.text) ?? 0,
      whatsappNumber: _whatsapp.text.trim(),
      phoneNumber: _phone.text.trim(),
      storeAddress: _address.text.trim(),
      storeLat: double.tryParse(_lat.text) ?? 0,
      storeLng: double.tryParse(_lng.text) ?? 0,
      openingHours: _hours.text.trim(),
      aboutText: _about.text.trim(),
    );
    final ok = await _vm.save(s);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Settings saved' : (_vm.error ?? 'Save failed')),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok) Navigator.pop(context);
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
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Settings',
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
            body: vm.loading && !_filled
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
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
                          _sectionCard(
                            icon: Icons.payments_outlined,
                            title: 'Fees',
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  controller: _delivery,
                                  label: 'Delivery fee',
                                  keyboard: TextInputType.number,
                                  hint: 'e.g. 100',
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: _takeaway,
                                  label: 'Takeaway fee',
                                  keyboard: TextInputType.number,
                                  hint: 'e.g. 0',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionCard(
                            icon: Icons.contact_phone_outlined,
                            title: 'Contact',
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  controller: _phone,
                                  label: 'Phone number',
                                  hint: 'e.g. 0300 0000000',
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: _whatsapp,
                                  label: 'WhatsApp number',
                                  hint: 'e.g. 0300 0000000',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionCard(
                            icon: Icons.location_on_outlined,
                            title: 'Location',
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  controller: _address,
                                  label: 'Store address',
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _lat,
                                        label: 'Latitude',
                                        keyboard:
                                        TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _lng,
                                        label: 'Longitude',
                                        keyboard:
                                        TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionCard(
                            icon: Icons.info_outline,
                            title: 'Store Info',
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  controller: _hours,
                                  label: 'Opening hours',
                                  hint: 'e.g. 11:00 AM - 2:00 AM',
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: _about,
                                  label: 'About text',
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            label: 'Save changes',
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
        },
      ),
    );
  }

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
          child,
        ],
      ),
    );
  }
}