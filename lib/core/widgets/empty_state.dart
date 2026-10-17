import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textLight)),
        ],
      ),
    );
  }
}