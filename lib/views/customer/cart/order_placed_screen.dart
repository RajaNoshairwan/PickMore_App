import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/order_model.dart';

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
// LOCAL PALETTE — uses the exact Home header gradient
// ============================================================
class _Palette {
  static const headerStart = Color(0xFFFF8A4C);
  static const headerEnd = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF6B35);
  static const success = Color(0xFF10B981);

  // ── Corner glow — 3-stop so the orange stays visible ──
  static final cornerA = headerEnd.withOpacity(0.66);   // center
  static final cornerMid = headerEnd.withOpacity(0.35); // plateau
  static final cornerB = headerEnd.withOpacity(0.00);   // edge

  static final successA20 = success.withOpacity(0.20);
  static final successA12 = success.withOpacity(0.12);
  static final successA06 = success.withOpacity(0.06);

  static final accentA15 = accent.withOpacity(0.15);
  static final accentA10 = accent.withOpacity(0.10);
}

class OrderPlacedScreen extends StatelessWidget {
  final OrderModel order;
  const OrderPlacedScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // ── One shared size for all four corners ──
    final cornerSize = _Resp.s(context, 180);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ─────────── 4 IDENTICAL ORANGE CORNERS ───────────
          _cornerGlow(
            top: -cornerSize * 0.5,
            left: -cornerSize * 0.5,
            size: cornerSize,
          ),
          _cornerGlow(
            top: -cornerSize * 0.5,
            right: -cornerSize * 0.5,
            size: cornerSize,
          ),
          _cornerGlow(
            bottom: -cornerSize * 0.5,
            left: -cornerSize * 0.5,
            size: cornerSize,
          ),
          _cornerGlow(
            bottom: -cornerSize * 0.5,
            right: -cornerSize * 0.5,
            size: cornerSize,
          ),

          // ─────────── MAIN CONTENT ───────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                _Resp.s(context, 24),
                _Resp.s(context, 24),
                _Resp.s(context, 24),
                _Resp.s(context, 32),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      _Resp.s(context, 56),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: _Resp.s(context, 20)),

                    // ── 1. Success icon ──
                    FadeSlideIn(
                      child: _successIcon(context),
                    ),
                    SizedBox(height: _Resp.s(context, 28)),

                    // ── 2. Title ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        'Order placed!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _Resp.t(context, 28),
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.1,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 12)),

                    // ── 3. Order number ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _Resp.s(context, 14),
                          vertical: _Resp.s(context, 8),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(_Resp.s(context, 20)),
                          border: Border.all(
                            color: _Palette.accentA15,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _Palette.accentA10,
                              blurRadius: _Resp.s(context, 12),
                              offset: Offset(0, _Resp.s(context, 4)),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: _Palette.accent,
                              size: _Resp.s(context, 14),
                            ),
                            SizedBox(width: _Resp.s(context, 6)),
                            Text(
                              'Order ${order.orderNo}',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w800,
                                fontSize: _Resp.t(context, 13),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 22)),

                    // ── 4. Subtitle ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 280),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _Resp.s(context, 12),
                        ),
                        child: Text(
                          'We\'ve received your order and the restaurant will start preparing it shortly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textLight,
                            height: 1.55,
                            fontSize: _Resp.t(context, 13.5),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 40)),

                    // ── 5. Back to home ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 360),
                      child: SizedBox(
                        width: _Resp.s(context, 240),
                        child: CustomButton(
                          label: 'Back to home',
                          icon: Icons.home_outlined,
                          onPressed: () =>
                              Navigator.popUntil(context, (r) => r.isFirst),
                        ),
                      ),
                    ),
                    SizedBox(height: _Resp.s(context, 20)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CORNER GLOW — identical for all four corners
  // 3-stop gradient keeps the orange visible before fading out.
  // ============================================================
  Widget _cornerGlow({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _Palette.cornerA,
                _Palette.cornerMid,
                _Palette.cornerB,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS ICON
  // ============================================================
  Widget _successIcon(BuildContext context) {
    final size = _Resp.s(context, 140);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _Palette.successA20,
                  _Palette.successA06,
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
          Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Palette.successA12,
            ),
          ),
          Container(
            width: size * 0.66,
            height: size * 0.66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Palette.success,
              boxShadow: [
                BoxShadow(
                  color: _Palette.successA20,
                  blurRadius: _Resp.s(context, 24),
                  spreadRadius: _Resp.s(context, 2),
                  offset: Offset(0, _Resp.s(context, 8)),
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              size: size * 0.36,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}