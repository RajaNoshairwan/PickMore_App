import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        height: 50,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}