import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../viewmodels/admin/admin_feedback_viewmodel.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});
  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminFeedbackViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Feedback',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<AdminFeedbackViewModel>(
        builder: (context, vm, _) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.feedbacks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rate_review_outlined,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No feedback yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Customer feedback will appear here',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: vm.load,
            color: AppColors.secondary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              cacheExtent: 500,
              addAutomaticKeepAlives: false,
              itemCount: vm.feedbacks.length,
              itemBuilder: (_, i) => _feedbackCard(vm.feedbacks[i]),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FEEDBACK CARD
  // ============================================================
  Widget _feedbackCard(dynamic f) {
    final rating = (f.rating is num) ? (f.rating as num).toInt() : 0;
    final name = (f.customerName ?? '').toString().trim();
    final initial =
    name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final comment = (f.comment ?? '').toString().trim();

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- Header: avatar + name + stars --------
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Anonymous' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        Formatters.date(f.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _starRow(rating),
              ],
            ),

            // -------- Comment --------
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 10),
              Text(
                comment,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],

            // -------- Rating badge --------
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _ratingColor(rating).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$rating / 5',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      // color: _ratingColor(rating).shade700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _ratingLabel(rating),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAR ROW
  // ============================================================
  Widget _starRow(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: filled ? Colors.amber.shade600 : Colors.grey.shade300,
        );
      }),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Color _ratingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }

  String _ratingLabel(int rating) {
    if (rating >= 5) return 'Excellent';
    if (rating == 4) return 'Good';
    if (rating == 3) return 'Average';
    if (rating == 2) return 'Poor';
    if (rating == 1) return 'Very poor';
    return 'No rating';
  }
}