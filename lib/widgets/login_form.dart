import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'custom_input.dart';
import 'loading_indicator.dart';
import '../config/theme.dart';
import 'mixins/form_validation_mixin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'form/form_spacing.dart';
import 'form/password_field.dart';
import 'custom_button.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool isLoggingOut;
  final VoidCallback? onClearFields;

  const LoginForm({
    super.key,
    required this.onLoginSuccess,
    this.isLoggingOut = false,
    this.onClearFields,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with FormValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Always clear fields by default
    _clearFields();

    // Load saved credentials if not logging out
    if (!widget.isLoggingOut) {
      _loadSavedCredentials();
    }
  }

  @override
  void didUpdateWidget(LoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear fields if we're not logging out and the widget was updated
    if (!widget.isLoggingOut && oldWidget.isLoggingOut != widget.isLoggingOut) {
      _clearFields();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    // Only load credentials if remember me is true AND we're not logging out
    if (rememberMe && !widget.isLoggingOut) {
      setState(() {
        _rememberMe = true;
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      });
    }
  }

  void _clearFields() {
    setState(() {
      _emailController.clear();
      _passwordController.clear();
      _rememberMe = false;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard before login
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        if (e is AuthException) {
          if (e.message.toLowerCase().contains('email not confirmed') ||
              e.message.toLowerCase().contains('email_not_verified')) {
            _showVerificationDialog();
          } else if (e.message.toLowerCase().contains('invalid') ||
              e.message.toLowerCase().contains('credentials')) {
            _showInvalidCredentialsDialog(e.message);
          } else {
            _showErrorDialog(e.message);
          }
        } else {
          _showErrorDialog('An unexpected error occurred. Please try again.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _VerificationDialog(),
    );
  }

  void _showInvalidCredentialsDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Credentials'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Input
            CustomInput(
              label: 'Email',
              controller: _emailController,
              hint: 'Enter your email',
              prefixIcon: const Icon(Icons.email),
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              autofillHints: const [AutofillHints.email],
            ),
            const FormSpacing(height: 5),

            // Password Input
            PasswordField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              validator: validatePassword,
              autofillHints: const [AutofillHints.password],
            ),
            const FormSpacing(height: 5),

            // Remember Me
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: AppTheme.primaryColor,
                  checkColor: Colors.white,
                  side:
                      const BorderSide(color: AppTheme.primaryColor, width: 1),
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                Text('Remember me',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                const Spacer(),
              ],
            ),
            const FormSpacing(height: 5),

            // Login Button
            CustomButton(
              onPressed: _isLoading ? null : _login,
              height: 48,
              child: _isLoading
                  ? const LoadingIndicator()
                  : const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Separate widget for verification dialog to prevent timer leaks
class _VerificationDialog extends StatefulWidget {
  const _VerificationDialog();

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  int _countdown = 120; // 2 minutes in seconds
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Properly cancel timer to prevent leak
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Email Not Verified'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Please check your email for a verification link. If you haven\'t received it, you can request a new one.',
          ),
          if (!_canResend) ...[
            const SizedBox(height: 16),
            Text(
              'You can request a new verification email in ${_countdown ~/ 60}:${(_countdown % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: _canResend
              ? () {
                  Navigator.pop(context);
                  Provider.of<AuthService>(context, listen: false)
                      .sendVerificationEmail();
                }
              : null,
          child: const Text('Resend Email'),
        ),
      ],
    );
  }
}
