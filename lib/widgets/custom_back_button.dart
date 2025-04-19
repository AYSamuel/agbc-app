import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? color;

  const CustomBackButton({
    super.key,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: color ?? AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
} 