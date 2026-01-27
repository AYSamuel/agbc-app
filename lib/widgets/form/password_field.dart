import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../custom_input.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool isConfirmField;
  final TextEditingController? confirmController;
  final List<String>? autofillHints;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
    this.isConfirmField = false,
    this.confirmController,
    this.autofillHints,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() async {
    await _animationController.forward();
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
    await _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return CustomInput(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      obscureText: _obscurePassword,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      suffixIcon: GestureDetector(
        onTap: _togglePasswordVisibility,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                key: ValueKey<bool>(_obscurePassword),
                color: AppTheme.primary(context),
                size: 20,
              ),
            ),
          ),
        ),
      ),
      validator: widget.isConfirmField
          ? (value) {
              // First check basic password requirements
              final basicValidation = widget.validator?.call(value);
              if (basicValidation != null) {
                return basicValidation;
              }
              // Then check if passwords match
              if (value != widget.confirmController?.text) {
                return 'Passwords do not match';
              }
              return null;
            }
          : widget.validator,
    );
  }
}
