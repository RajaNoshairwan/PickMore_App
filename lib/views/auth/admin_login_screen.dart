import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../viewmodels/auth_viewmodel.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.signInAdmin(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (!ok) {
      _showError(auth.error ?? 'Login failed. Please try again.');
    } else {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      backgroundColor: AppColors.secondary,
      // appBar: AppBar(
      //   title: const Text(
      //     'Admin Login',
      //     style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.4),
      //   ),
      //   backgroundColor: AppColors.secondary,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   centerTitle: true,
      // ),
      body: SafeArea(
        child: Column(
          children: [
            // Header banner
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Administrator Access',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in with your admin credentials to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),

            // Form card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your details to log in',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        CustomTextField(
                          controller: _email,
                          label: 'Admin Email',
                          keyboard: TextInputType.emailAddress,
                          icon: Icons.email_outlined,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 4),

                        CustomTextField(
                          controller: _password,
                          label: 'Password',
                          obscure: _obscurePassword,
                          icon: Icons.lock_outline,
                          validator: Validators.password,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey.shade600,
                            ),
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        CustomButton(
                          label: 'Login',
                          loading: auth.loading,
                          onPressed: _login,
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'Restricted area • Authorized admins only',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.2,
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
          ],
        ),
      ),
    );
  }
}