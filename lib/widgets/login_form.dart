import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agbc_app/services/auth_service.dart';
import 'package:agbc_app/widgets/custom_input.dart';
import 'package:agbc_app/widgets/custom_button.dart';
import 'package:agbc_app/widgets/loading_indicator.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/widgets/mixins/form_validation_mixin.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginForm({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with FormValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    if (!_emailFocusNode.hasFocus) {
      _formKey.currentState?.validate();
    }
  }

  void _onPasswordFocusChange() {
    if (!_passwordFocusNode.hasFocus) {
      _formKey.currentState?.validate();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _login() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'No account found with this email. Please register first.';
              break;
            case 'wrong-password':
              errorMessage = 'Incorrect password. Please try again.';
              break;
            case 'invalid-email':
              errorMessage = 'The email address is invalid.';
              break;
            case 'user-disabled':
              errorMessage = 'This account has been disabled.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many failed login attempts. Please try again later.';
              break;
            default:
              errorMessage = 'An error occurred during login. Please try again.';
          }
        } else {
          errorMessage = 'An unexpected error occurred. Please try again.';
        }

        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          CustomInput(
            label: 'Email',
            controller: _emailController,
            hint: 'Enter your email',
            prefixIcon: Icon(Icons.email, color: AppTheme.neutralColor),
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            validator: validateEmail,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),

          // Password Field
          CustomInput(
            label: 'Password',
            controller: _passwordController,
            hint: 'Enter your password',
            prefixIcon: Icon(Icons.lock, color: AppTheme.neutralColor),
            obscureText: _obscurePassword,
            focusNode: _passwordFocusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.neutralColor,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: validatePassword,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 24),

          // Login Button
          CustomButton(
            onPressed: _isLoading ? null : _login,
            backgroundColor: AppTheme.accentColor,
            child: _isLoading
                ? const LoadingIndicator()
                : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 