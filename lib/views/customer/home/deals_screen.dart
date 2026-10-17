import 'package:flutter/material.dart';

import '../../../models/product_model.dart';
import '../../../viewmodels/customer/home_viewmodel.dart';
import 'product_detail_screen.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});
  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final _vm = HomeViewModel();

  @override
  void initState() {
    super.initState();
    _vm.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deals')),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (context, _) {
          if (_vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final deals = _vm.deals;
          if (deals.isEmpty) {
            return const Center(child: Text('No deals right now'));
          }
          return ListView.builder(
            itemCount: deals.length,
            itemBuilder: (_, i) {
              final ProductModel p = deals[i];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('₹${p.effectivePrice.toStringAsFixed(0)}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}