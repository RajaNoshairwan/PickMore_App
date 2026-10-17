import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/animations.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'admin_login_screen.dart';

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});
  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  // ── UI state ──
  bool _showPassword = false;
  bool _showFormError = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _showFormError = true);
      return;
    }
    setState(() => _showFormError = false);

    final auth = context.read<AuthViewModel>();
    final ok = await auth.signUpCustomer(
      name: _name.text,
      phone: _phone.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error ?? 'Signup failed')));
    } else {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Gradient background (same as login) ──
          Container(
            height: size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF7A59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Admin access ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen()),
                      ),
                      icon: const Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Admin',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const FadeSlideIn(
                    child: Text(
                      'Create account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 100),
                    child: Text(
                      'Join us and start ordering in seconds',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── White card with form ──
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // ── Modern animated error banner ──
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, anim) =>
                                  SizeTransition(
                                    sizeFactor: anim,
                                    axisAlignment: -1,
                                    child: FadeTransition(
                                        opacity: anim, child: child),
                                  ),
                              child: _showFormError
                                  ? _errorBanner()
                                  : const SizedBox.shrink(
                                  key: ValueKey('no-error')),
                            ),

                            CustomTextField(
                              controller: _name,
                              label: 'Full name',
                              icon: Icons.person_outline,
                              validator: (v) =>
                                  Validators.required(v, 'Name'),
                            ),
                            CustomTextField(
                              controller: _phone,
                              label: 'Phone',
                              keyboard: TextInputType.phone,
                              icon: Icons.phone_outlined,
                              validator: Validators.phone,
                            ),
                            CustomTextField(
                              controller: _email,
                              label: 'Email',
                              keyboard: TextInputType.emailAddress,
                              icon: Icons.email_outlined,
                              validator: Validators.email,
                            ),

                            // ── Password with eye toggle ──
                            Stack(
                              children: [
                                CustomTextField(
                                  controller: _password,
                                  label: 'Password',
                                  obscure: !_showPassword,
                                  icon: Icons.lock_outline,
                                  validator: Validators.password,
                                ),
                                Positioned(
                                  top: 0,
                                  right: 4,
                                  child: SizedBox(
                                    width: 44,
                                    height: 56,
                                    child: Center(
                                      child: IconButton(
                                        onPressed: () => setState(() =>
                                        _showPassword = !_showPassword),
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppColors.textLight,
                                          size: 20,
                                        ),
                                        splashRadius: 20,
                                        tooltip: _showPassword
                                            ? 'Hide password'
                                            : 'Show password',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            CustomButton(
                              label: 'Create account',
                              loading: auth.loading,
                              onPressed: _signup,
                            ),

                            const SizedBox(height: 12),

                            // ── Or divider ──
                            // Row(
                            //   children: const [
                            //     Expanded(child: Divider()),
                            //     Padding(
                            //       padding:
                            //       EdgeInsets.symmetric(horizontal: 10),
                            //       child: Text('or',
                            //           style: TextStyle(
                            //               color: AppColors.textLight)),
                            //     ),
                            //     Expanded(child: Divider()),
                            //   ],
                            // ),
                            //
                            // const SizedBox(height: 12),

                            // ── Continue as Guest ──
                            // SizedBox(
                            //   width: double.infinity,
                            //   child: OutlinedButton.icon(
                            //     onPressed: () {
                            //       context
                            //           .read<AuthViewModel>()
                            //           .continueAsGuest();
                            //     },
                            //     icon: const Icon(Icons.person_outline),
                            //     label: const Text('Continue as Guest'),
                            //     style: OutlinedButton.styleFrom(
                            //       padding: const EdgeInsets.symmetric(
                            //           vertical: 14),
                            //       foregroundColor: AppColors.textDark,
                            //       side: const BorderSide(
                            //           color: AppColors.divider),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(10),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Already have an account? Login ──
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 350),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODERN ERROR BANNER
  // ============================================================
  Widget _errorBanner() {
    return Container(
      key: const ValueKey('error'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE53935),
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Please fill in all fields correctly to continue.',
              style: TextStyle(
                color: Color(0xFFC62828),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}