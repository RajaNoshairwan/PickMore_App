// import 'package:flutter/material.dart';
//
// import 'orders/admin_orders_screen.dart';
// import 'products/admin_products_screen.dart';
// import 'offers/admin_offers_screen.dart';
// import 'settings/admin_settings_screen.dart';
//
// class AdminShell extends StatefulWidget {
//   const AdminShell({super.key});
//   @override
//   State<AdminShell> createState() => _AdminShellState();
// }
//
// class _AdminShellState extends State<AdminShell> {
//   int _index = 0;
//   final _pages = const [
//     AdminOrdersScreen(),
//     AdminProductsScreen(),
//     AdminOffersScreen(),
//     AdminSettingsScreen(),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(index: _index, children: _pages),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _index,
//         onTap: (i) => setState(() => _index = i),
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: Theme.of(context).colorScheme.primary,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
//           BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Products'),
//           BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Offers'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/admin/admin_orders_viewmodel.dart';
import '../../viewmodels/admin/admin_products_viewmodel.dart';
import '../../viewmodels/admin/admin_offers_viewmodel.dart';
import '../../viewmodels/admin/admin_settings_viewmodel.dart';
import 'orders/admin_orders_screen.dart';
import 'products/admin_products_screen.dart';
import 'offers/admin_offers_screen.dart';
import 'settings/admin_settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _pages = const [
    AdminOrdersScreen(),
    AdminProductsScreen(),
    AdminOffersScreen(),
    AdminSettingsScreen(),
  ];

  void _goTo(int i) {
    setState(() => _index = i);
    // Refresh the selected tab's VM so data is current
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (i) {
        case 0:
          context.read<AdminOrdersViewModel>().loadAll();
          break;
        case 1:
          context.read<AdminProductsViewModel>().load();
          break;
        case 2:
          context.read<AdminOffersViewModel>().load();
          break;
        case 3:
          context.read<AdminSettingsViewModel>().load();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _goTo,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fastfood), label: 'Products'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer), label: 'Offers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}