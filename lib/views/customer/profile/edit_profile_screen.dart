import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../models/address_model.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/customer/profile_viewmodel.dart';

// ============================================================
// RESPONSIVE SCALING HELPERS
// ============================================================
class _Resp {
  static const double _base = 390.0;
  static const double _maxContentWidth = 640.0;

  static Size _size(BuildContext c) => MediaQuery.sizeOf(c);

  static double _w(BuildContext c) => _size(c).width;
  static double _h(BuildContext c) => _size(c).height;

  static double scale(BuildContext c) {
    final w = _w(c);
    final h = _h(c);
    final byWidth = (w / _base).clamp(0.82, 1.30);
    final byHeight = h < 480 ? 0.90 : 1.0;
    return byWidth * byHeight;
  }

  static double textScale(BuildContext c) {
    final w = _w(c);
    final s = (w / _base).clamp(0.88, 1.18);
    final system = MediaQuery.textScalerOf(c).scale(1.0);
    return s * system.clamp(0.85, 1.25);
  }

  static double s(BuildContext c, double v) => v * scale(c);
  static double t(BuildContext c, double v) => v * textScale(c);

  static double contentWidth(BuildContext c) {
    final w = _w(c);
    return w > _maxContentWidth ? _maxContentWidth : w;
  }
}

// ============================================================
// LOCAL PALETTE (mirrors HomeScreen)
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF6B35);

  static final accentA10 = accent.withOpacity(0.10);
  static final accentA08 = accent.withOpacity(0.08);
  static final headerEndA35 = headerEnd.withOpacity(0.35);
  static final blackA04 = Colors.black.withOpacity(0.04);
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser!;
    _name = TextEditingController(text: user.name);
    _phone = TextEditingController(text: user.phone);
    _address =
        TextEditingController(text: user.defaultAddress?.fullAddress ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  // ============================================================
  // SAVE — writes to Firestore AND updates AuthViewModel in memory
  // so all screens (home greeting, profile, etc.) refresh instantly.
  // ============================================================
  Future<void> _save() async {
    setState(() => _saving = true);

    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser!;
    final vm = ProfileViewModel();

    final updated = user.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      defaultAddress: AddressModel(
        label: 'Home',
        fullAddress: _address.text.trim(),
        lat: user.defaultAddress?.lat ?? 0,
        lng: user.defaultAddress?.lng ?? 0,
        isDefault: true,
      ),
    );

    final ok = await vm.updateProfile(updated);

    if (!mounted) return;

    setState(() => _saving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ⭐ THE FIX: push the fresh user into AuthViewModel so every
    // screen reading `auth.currentUser` updates immediately.
    auth.updateLocalUser(updated);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _Resp.contentWidth(context),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                _Resp.s(context, 16),
                _Resp.s(context, 20),
                _Resp.s(context, 16),
                _Resp.s(context, 32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatarHeader(context),
                  SizedBox(height: _Resp.s(context, 24)),
                  _sectionHeader(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Personal Information',
                  ),
                  SizedBox(height: _Resp.s(context, 10)),
                  _sectionCard(
                    context,
                    children: [
                      CustomTextField(
                        controller: _name,
                        label: 'Full name',
                      ),
                      SizedBox(height: _Resp.s(context, 12)),
                      CustomTextField(
                        controller: _phone,
                        label: 'Phone',
                        keyboard: TextInputType.phone,
                      ),
                    ],
                  ),
                  SizedBox(height: _Resp.s(context, 22)),
                  _sectionHeader(
                    context,
                    icon: Icons.location_on_outlined,
                    label: 'Default Address',
                  ),
                  SizedBox(height: _Resp.s(context, 10)),
                  _sectionCard(
                    context,
                    children: [
                      CustomTextField(
                        controller: _address,
                        label: 'Default address',
                        maxLines: 2,
                      ),
                    ],
                  ),
                  SizedBox(height: _Resp.s(context, 28)),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: 'Save',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final titleRowH = _Resp.s(context, 56);
    final totalH = topPad + titleRowH;

    return PreferredSize(
      preferredSize: Size.fromHeight(totalH),
      child: Container(
        height: totalH,
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
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _Resp.contentWidth(context),
              ),
              child: SizedBox(
                height: titleRowH,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _Resp.s(context, 8),
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
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: _Resp.s(context, 4),
                            right: _Resp.s(context, 8),
                          ),
                          child: Text(
                            'Edit profile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _Resp.t(context, 18),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarHeader(BuildContext context) {
    final initial = _name.text.trim().isEmpty
        ? '?'
        : _name.text.trim()[0].toUpperCase();
    final size = _Resp.s(context, 88);

    return Center(
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Palette.accentA10,
              border: Border.all(
                color: _Palette.accent.withOpacity(0.25),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: _Palette.accent,
                fontSize: _Resp.t(context, 34),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: _Resp.s(context, 12)),
          Text(
            'Update your details',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: _Resp.t(context, 13),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, {
        required IconData icon,
        required String label,
      }) {
    return Padding(
      padding: EdgeInsets.only(left: _Resp.s(context, 4)),
      child: Row(
        children: [
          Container(
            width: _Resp.s(context, 28),
            height: _Resp.s(context, 28),
            decoration: BoxDecoration(
              color: _Palette.accentA08,
              borderRadius: BorderRadius.circular(_Resp.s(context, 8)),
            ),
            child: Icon(
              icon,
              size: _Resp.s(context, 16),
              color: _Palette.accent,
            ),
          ),
          SizedBox(width: _Resp.s(context, 8)),
          Text(
            label,
            style: TextStyle(
              fontSize: _Resp.t(context, 13.5),
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(_Resp.s(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 16)),
        boxShadow: [
          BoxShadow(
            color: _Palette.blackA04,
            blurRadius: _Resp.s(context, 10),
            offset: Offset(0, _Resp.s(context, 4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}