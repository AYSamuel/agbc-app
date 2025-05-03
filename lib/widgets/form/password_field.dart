import 'package:flutter/material.dart';
import '../../utils/theme.dart';
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
      prefixIcon: Icon(Icons.lock, color: AppTheme.primaryColor),
      obscureText: _obscurePassword,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: AppTheme.primaryColor,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      validator: widget.isConfirmField
          ? (value) {
              if (value != widget.confirmController?.text) {
                return 'Passwords do not match';
              }
              return widget.validator?.call(value);
            }
          : widget.validator,
    );
  }
}
