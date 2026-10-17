import 'package:flutter/material.dart';

import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../models/order_model.dart';
import '../../../viewmodels/customer/orders_viewmodel.dart';

class FeedbackScreen extends StatefulWidget {
  final OrderModel order;
  const FeedbackScreen({super.key, required this.order});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final vm = OrdersViewModel();
    final ok = await vm.submitFeedback(
      orderId: widget.order.id,
      customerId: widget.order.customerId,
      customerName: widget.order.customerName,
      rating: _rating,
      comment: _comment.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Thanks for your feedback!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate your order'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
            CustomTextField(
              controller: _comment,
              label: 'Comment (optional)',
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Submit',
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}