import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/launchers.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/customer/profile_viewmodel.dart';
import 'edit_profile_screen.dart';
import 'info_screen.dart';

// ============================================================
// RESPONSIVE SCALING HELPERS
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
// LOCAL PALETTE (mirrors HomeScreen / CartScreen)
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF6B35);

  static final headerEndA35 = headerEnd.withOpacity(0.35);
}

// ============================================================
// RESTAURANT CONTACT DETAILS (hardcoded)
// ------------------------------------------------------------
// WhatsApp uses international format WITHOUT the "+".
// Call keeps the local format (dialer handles it).
// ============================================================
const String _whatsappNumber = '923066902221'; // 0306-6902221 → +92 306 690 2221
const String _callNumber = '03366902221';       // 0336-6902221

// Restaurant coordinates (from Google Maps share link)
const double _storeLat = 30.6731918;
const double _storeLng = 73.0920935;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ProfileViewModel();
    _vm.loadStore();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;

    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: user == null ? _guestView(context) : _userView(context, user),
      ),
    );
  }

  // ============================================================
  // APPBAR — identical structure to CartScreen
  // ============================================================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final barHeight = _Resp.s(context, 62);
    final canPop = Navigator.of(context).canPop();

    return PreferredSize(
      preferredSize: Size.fromHeight(
        MediaQuery.of(context).padding.top + barHeight,
      ),
      child: Container(
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
                      left: canPop
                          ? _Resp.s(context, 4)
                          : _Resp.s(context, 12),
                    ),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _Resp.t(context, 20),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: _Resp.s(context, 8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Guest view ----------
  Widget _guestView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 30),
        FadeSlideIn(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                size: 60, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'You\'re browsing as a guest',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to place orders, track deliveries\nand unlock exclusive deals.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textLight, height: 1.5),
        ),
        const SizedBox(height: 30),
        CustomButton(
          label: 'Sign in',
          icon: Icons.login,
          onPressed: () => context.read<AuthViewModel>().signOut(),
        ),
        const SizedBox(height: 12),
        CustomButton(
          label: 'Create account',
          icon: Icons.person_add_alt,
          outlined: true,
          onPressed: () => context.read<AuthViewModel>().signOut(),
        ),
        const SizedBox(height: 30),
        const Divider(),
        const SizedBox(height: 20),

        // ── Account / Info ──
        _sectionTitle('Info'),
        _tile(Icons.location_on_outlined, 'Store locator', () {
          Launchers.map(_storeLat, _storeLng);
        }),
        _tile(Icons.info_outline, 'About us', () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const InfoScreen(
                    title: 'About us', key_: 'about')),
          );
        }),

        const SizedBox(height: 12),

        // ── Get in touch ──
        _sectionTitle('Get in touch'),
        _tile(Icons.chat_bubble_outline, 'Chat on WhatsApp', () {
          Launchers.whatsapp(_whatsappNumber);
        }),
        _tile(Icons.phone_outlined, 'Call store', () {
          Launchers.call(_callNumber);
        }),

        const SizedBox(height: 30),
        _footer(),
      ],
    );
  }

  // ---------- User view ----------
  Widget _userView(BuildContext context, dynamic user) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        // Header
        FadeSlideIn(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF7A59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Text(user.phone,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
        _sectionTitle('Account'),
        _tile(Icons.person_outline, 'Edit profile', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          );
        }),
        _tile(Icons.location_on_outlined, 'Store locator', () {
          Launchers.map(_storeLat, _storeLng);
        }),

        const SizedBox(height: 12),
        _sectionTitle('Get in touch'),
        _tile(Icons.chat_bubble_outline, 'Chat on WhatsApp', () {
          Launchers.whatsapp(_whatsappNumber);
        }),
        _tile(Icons.phone_outlined, 'Call store', () {
          Launchers.call(_callNumber);
        }),

        const SizedBox(height: 12),
        _sectionTitle('About'),
        _tile(Icons.info_outline, 'About us', () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                const InfoScreen(title: 'About us', key_: 'about')),
          );
        }),
        _tile(Icons.privacy_tip_outlined, 'Privacy policy', () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const InfoScreen(
                    title: 'Privacy Policy', key_: 'privacy')),
          );
        }),
        _tile(Icons.description_outlined, 'Terms & Conditions', () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                const InfoScreen(title: 'Terms', key_: 'terms')),
          );
        }),

        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomButton(
            label: 'Log out',
            icon: Icons.logout,
            outlined: true,
            onPressed: () => context.read<AuthViewModel>().signOut(),
          ),
        ),

        const SizedBox(height: 30),
        _footer(),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
    child: Text(t,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: 0.8)),
  );

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textLight, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, VoidCallback onTap) =>
      _tile(icon, label, onTap);

  Widget _footer() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const SizedBox(height: 4),
        Text(
          'Version 1.0.0',
          style: TextStyle(
              fontSize: 12, color: AppColors.textLight.withOpacity(0.7)),
        ),
        const SizedBox(height: 6),
        Text(
          'Developed by: Raja Noshairwan',
          style: TextStyle(
              fontSize: 12, color: AppColors.textLight.withOpacity(0.7)),
        ),
        Text(
          'noshairwan.kamal03@gmail.com',
          style: TextStyle(
              fontSize: 12, color: AppColors.textLight.withOpacity(0.7)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}