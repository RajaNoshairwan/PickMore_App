import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../viewmodels/cart_viewmodel.dart';
import 'home/home_screen.dart';
import 'menu/menu_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  /// Only Orders needs to rebuild when the user returns — so that a newly
  /// placed order (or a status change) shows up immediately.
  /// Home / Menu / Cart keep their state — no shimmer on return.
  int _ordersKey = 0;

  void _goTo(int i) {
    setState(() {
      _index = i;
      if (i == 3) _ordersKey++; // refresh Orders only
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

    final pages = [
      HomeScreen(onOpenMenu: () => _goTo(1)),
      const MenuScreen(),
      CartScreen(onBrowseMenu: () => _goTo(1)),
      OrdersScreen(key: ValueKey('orders_$_ordersKey')),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                _tab(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _tab(1, Icons.restaurant_menu_rounded,
                    Icons.restaurant_menu_outlined, 'Menu'),
                _tabWithBadge(2, Icons.shopping_bag_rounded,
                    Icons.shopping_bag_outlined, 'Cart', cart.itemCount),
                _tab(3, Icons.receipt_long_rounded,
                    Icons.receipt_long_outlined, 'Orders'),
                _tab(4, Icons.person_rounded, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData active, IconData inactive, String label) {
    final selected = _index == i;
    final color = selected ? AppColors.primary : AppColors.textLight;
    return Expanded(
      child: InkWell(
        onTap: () => _goTo(i),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(selected ? active : inactive, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabWithBadge(int i, IconData active, IconData inactive,
      String label, int badge) {
    final selected = _index == i;
    final color = selected ? AppColors.primary : AppColors.textLight;
    return Expanded(
      child: InkWell(
        onTap: () => _goTo(i),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: selected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(selected ? active : inactive, color: color),
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}