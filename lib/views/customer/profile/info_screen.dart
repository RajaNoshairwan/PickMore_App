import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/launchers.dart';

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
// LOCAL PALETTE
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF6B35);

  // Brand red — matches the logo circle in the reference
  static const brandRed = Color(0xFFE53935);

  static final accentA10 = accent.withOpacity(0.10);
  static final accentA08 = accent.withOpacity(0.08);
  static final redA10 = brandRed.withOpacity(0.10);
  static final headerEndA35 = headerEnd.withOpacity(0.35);
  static final blackA04 = Colors.black.withOpacity(0.04);
}

// ============================================================
// RESTAURANT CONTACT DETAILS (hardcoded)
// ------------------------------------------------------------
// WhatsApp uses international format WITHOUT the "+".
// Call keeps the local format (dialer handles it).
// ============================================================
const String _whatsappNumber = '923066902221'; // 0306-6902221 → +92 306 690 2221
const String _callNumber = '03366902221';       // 0336-6902221

// ============================================================
// SECTION MODEL
// ============================================================
class _Section {
  final String heading;
  final String body;
  const _Section(this.heading, this.body);
}

class InfoScreen extends StatelessWidget {
  final String title;
  final String key_;
  const InfoScreen({super.key, required this.title, required this.key_});

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
              // ── About page gets its own custom layout ──
              child: key_ == 'about'
                  ? _buildAbout(context)
                  : _buildLegalPage(context),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APPBAR — gradient, matches Home / Cart / Orders
  // ============================================================
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
                            title,
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

  // ============================================================
  // ABOUT PAGE — logo, name, tagline, contact list, version
  // ============================================================
  Widget _buildAbout(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: _Resp.s(context, 8)),

        // ── Logo ──
        Container(
          width: _Resp.s(context, 110),
          height: _Resp.s(context, 110),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _Palette.brandRed,
            boxShadow: [
              BoxShadow(
                color: _Palette.brandRed.withOpacity(0.30),
                blurRadius: _Resp.s(context, 20),
                offset: Offset(0, _Resp.s(context, 8)),
              ),
            ],
          ),
          child: Icon(
            Icons.local_pizza_rounded,
            color: Colors.white,
            size: _Resp.s(context, 58),
          ),
        ),
        SizedBox(height: _Resp.s(context, 18)),

        // ── Restaurant name ──
        Text(
          'PickMore',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _Resp.t(context, 24),
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: _Resp.s(context, 4)),

        // ── Tagline ──
        Text(
          'Family Restaurant',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _Resp.t(context, 13),
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),

        SizedBox(height: _Resp.s(context, 32)),

        // ── Contact card ──
        Container(
          padding: EdgeInsets.all(_Resp.s(context, 16)),
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
            children: [
              _contactRow(
                context,
                icon: Icons.location_on_rounded,
                text: 'College Chowk, Sahiwal',
              ),
              _divider(context),
              _contactRow(
                context,
                icon: Icons.phone_rounded,
                text: '0336-6902221',
              ),
              _divider(context),
              _contactRow(
                context,
                icon: Icons.chat_rounded,
                text: 'WhatsApp\n0306-6902221',
              ),
            ],
          ),
        ),

        SizedBox(height: _Resp.s(context, 28)),

        // ── Get in touch ──
        _sectionTitle(context, 'Get in touch'),
        SizedBox(height: _Resp.s(context, 10)),

        _tile(Icons.chat_bubble_outline, 'Chat on WhatsApp', () {
          Launchers.whatsapp(_whatsappNumber);
        }),
        SizedBox(height: _Resp.s(context, 10)),
        _tile(Icons.phone_outlined, 'Call store', () {
          Launchers.call(_callNumber);
        }),

        SizedBox(height: _Resp.s(context, 28)),

        // ── Version ──
        Text(
          'Version 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _Resp.t(context, 11.5),
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================
  Widget _sectionTitle(BuildContext context, String label) {
    return Row(
      children: [
        Container(
          width: _Resp.s(context, 4),
          height: _Resp.s(context, 16),
          decoration: BoxDecoration(
            color: _Palette.accent,
            borderRadius: BorderRadius.circular(_Resp.s(context, 2)),
          ),
        ),
        SizedBox(width: _Resp.s(context, 8)),
        Text(
          label,
          style: TextStyle(
            fontSize: _Resp.t(context, 14),
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION TILE — tappable row with icon + label
  // ============================================================
  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return Builder(
      builder: (context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _Resp.s(context, 14),
              vertical: _Resp.s(context, 14),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_Resp.s(context, 14)),
              boxShadow: [
                BoxShadow(
                  color: _Palette.blackA04,
                  blurRadius: _Resp.s(context, 10),
                  offset: Offset(0, _Resp.s(context, 4)),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: _Resp.s(context, 40),
                  height: _Resp.s(context, 40),
                  decoration: BoxDecoration(
                    color: _Palette.redA10,
                    borderRadius:
                    BorderRadius.circular(_Resp.s(context, 12)),
                  ),
                  child: Icon(
                    icon,
                    color: _Palette.brandRed,
                    size: _Resp.s(context, 20),
                  ),
                ),
                SizedBox(width: _Resp.s(context, 14)),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: _Resp.t(context, 13.5),
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textLight,
                  size: _Resp.s(context, 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Contact row — icon + text
  // ============================================================
  Widget _contactRow(
      BuildContext context, {
        required IconData icon,
        required String text,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _Resp.s(context, 4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: _Resp.s(context, 40),
            height: _Resp.s(context, 40),
            decoration: BoxDecoration(
              color: _Palette.redA10,
              borderRadius: BorderRadius.circular(_Resp.s(context, 12)),
            ),
            child: Icon(
              icon,
              color: _Palette.brandRed,
              size: _Resp.s(context, 20),
            ),
          ),
          SizedBox(width: _Resp.s(context, 14)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: _Resp.t(context, 13.5),
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _Resp.s(context, 6)),
      child: Divider(
        height: 1,
        color: AppColors.divider,
      ),
    );
  }

  // ============================================================
  // LEGAL PAGES — Privacy Policy & Terms & Conditions
  // ============================================================
  Widget _buildLegalPage(BuildContext context) {
    final sections = _sectionsFor(key_);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Content card ──
        Container(
          padding: EdgeInsets.all(_Resp.s(context, 18)),
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
            children: [
              for (int i = 0; i < sections.length; i++) ...[
                _sectionBlock(context, sections[i]),
                if (i != sections.length - 1)
                  SizedBox(height: _Resp.s(context, 20)),
              ],
            ],
          ),
        ),

        SizedBox(height: _Resp.s(context, 20)),

        // ── Last updated ──
        Center(
          child: Text(
            'Last updated: 2025',
            style: TextStyle(
              fontSize: _Resp.t(context, 11.5),
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT — exact text from the reference
  // ============================================================
  List<_Section> _sectionsFor(String key) {
    if (key == 'privacy') {
      return const [
        _Section(
          'Information we collect',
          'We collect your name, phone number, email address, delivery '
              'addresses (including the map location you choose) and '
              'your order history.',
        ),
        _Section(
          'How we use it',
          'We use this information only to take and deliver your '
              'orders, contact you about them and improve our service.',
        ),
        _Section(
          'Location',
          'Your location is used only when you choose to pin a '
              'delivery address or tap "My location". We do not track '
              'you in the background.',
        ),
        _Section(
          'Sharing',
          'We do not sell your data. Your name, phone number and '
              'address are shared only with the staff who prepare and '
              'deliver your order.',
        ),
        _Section(
          'Storage and security',
          'Your data is stored securely using Google Firebase. You can '
              'ask us to delete your account and data at any time.',
        ),
        _Section(
          'Contact',
          'For any privacy questions, call or message us using the '
              'details in the About screen.',
        ),
      ];
    }

    // Default → Terms & Conditions
    return const [
      _Section(
        'Using the app',
        'By placing an order you confirm that the details you provide '
            '(name, phone number and address) are correct.',
      ),
      _Section(
        'Orders and pricing',
        'Prices shown in the app are in Pakistan Rupees and may change '
            'without notice. The total at checkout is the final amount '
            'payable.',
      ),
      _Section(
        'Delivery',
        'Delivery times are estimates. We deliver only within our '
            'service areas and may refuse orders outside it.',
      ),
      _Section(
        'Cancellations',
        'You can cancel an order by calling us directly. Once '
            'preparation starts, cancellation is at our discretion.',
      ),
      _Section(
        'Payment',
        'Payment is currently Cash on Delivery. Please pay the rider '
            'the exact order total.',
      ),
      _Section(
        'Changes',
        'We may update these terms from time to time. Continued use of '
            'the app means you accept the updated terms.',
      ),
    ];
  }

  // ============================================================
  // SECTION BLOCK — accent bar + heading + body
  // ============================================================
  Widget _sectionBlock(BuildContext context, _Section section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: _Resp.s(context, 4),
              height: _Resp.s(context, 16),
              decoration: BoxDecoration(
                color: _Palette.accent,
                borderRadius: BorderRadius.circular(_Resp.s(context, 2)),
              ),
            ),
            SizedBox(width: _Resp.s(context, 8)),
            Expanded(
              child: Text(
                section.heading,
                style: TextStyle(
                  fontSize: _Resp.t(context, 14),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _Resp.s(context, 8)),
        Text(
          section.body,
          style: TextStyle(
            fontSize: _Resp.t(context, 13.5),
            height: 1.6,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}