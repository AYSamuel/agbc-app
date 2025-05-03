import 'package:flutter/material.dart';

class FormSpacing extends StatelessWidget {
  final double height;
  final Widget? child;

  const FormSpacing({
    super.key,
    this.height = 16.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: child,
    );
  }
}
