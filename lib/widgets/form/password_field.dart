import 'package:flutter/material.dart';

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

class _PasswordFieldState extends State<PasswordField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return CustomInput(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      prefixIcon: const Icon(Icons.lock),
      obscureText: _obscurePassword,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
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
