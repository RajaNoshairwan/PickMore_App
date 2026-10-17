import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/splash_screen.dart';
import 'views/auth/customer_login_screen.dart';
import 'views/customer/customer_shell.dart';
import 'views/admin/admin_shell.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    Widget home;
    if (auth.status == AuthStatus.unknown) {
      home = const SplashScreen();
    } else if (auth.status == AuthStatus.authenticated) {
      home = auth.currentUser?.role == 'admin'
          ? const AdminShell()
          : const CustomerShell();
    } else if (auth.isGuest) {
      home = const CustomerShell();
    } else {
      home = const CustomerLoginScreen();
    }

    return MaterialApp(
      title: 'Pick More',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textDark),
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: KeyedSubtree(
          key: ValueKey('${auth.status}_${auth.isGuest}_${auth.currentUser?.role}'),
          child: home,
        ),
      ),
    );
  }
}