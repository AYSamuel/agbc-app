import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed ?? () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(size / 2),
          child: Center(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: size * 0.5,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
} 