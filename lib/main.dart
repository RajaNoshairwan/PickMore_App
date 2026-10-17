// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import 'app.dart';
// import 'firebase_options.dart';
// import 'viewmodels/auth_viewmodel.dart';
// import 'viewmodels/cart_viewmodel.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const FoodApp());
// }
//
// class FoodApp extends StatelessWidget {
//   const FoodApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthViewModel()..bootstrap()),
//         ChangeNotifierProvider(create: (_) => CartViewModel()),
//       ],
//       child: const AppRoot(),
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/admin/admin_orders_viewmodel.dart';
import 'viewmodels/admin/admin_products_viewmodel.dart';
import 'viewmodels/admin/admin_offers_viewmodel.dart';
import 'viewmodels/admin/admin_feedback_viewmodel.dart';
import 'viewmodels/admin/admin_settings_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FoodApp());
}

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..bootstrap()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),

        // ── ADMIN VMs — GLOBAL (so pushed routes can access them) ──
        ChangeNotifierProvider(create: (_) => AdminOrdersViewModel()),
        ChangeNotifierProvider(create: (_) => AdminProductsViewModel()),
        ChangeNotifierProvider(create: (_) => AdminOffersViewModel()),
        ChangeNotifierProvider(create: (_) => AdminFeedbackViewModel()),
        ChangeNotifierProvider(create: (_) => AdminSettingsViewModel()),
      ],
      child: const AppRoot(),
    );
  }
}