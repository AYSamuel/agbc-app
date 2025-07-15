import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:grace_portal/widgets/custom_input.dart';
import 'package:grace_portal/widgets/loading_indicator.dart';
import 'package:grace_portal/utils/theme.dart';
import 'package:grace_portal/widgets/mixins/form_validation_mixin.dart';
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

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.signIn(
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
          if (e.code == 'email_not_verified') {
            _showVerificationDialog();
          } else if (e.code == 'invalid_credentials') {
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
    int countdown = 120; // 2 minutes in seconds
    bool canResend = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!canResend) {
              Future.delayed(const Duration(seconds: 1), () {
                if (countdown > 0) {
                  setState(() {
                    countdown--;
                  });
                } else {
                  setState(() {
                    canResend = true;
                  });
                }
              });
            }

            return AlertDialog(
              title: const Text('Email Not Verified'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please check your email for a verification link. If you haven\'t received it, you can request a new one.',
                  ),
                  if (!canResend) ...[
                    const SizedBox(height: 16),
                    Text(
                      'You can request a new verification email in ${countdown ~/ 60}:${(countdown % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.grey,
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
                  onPressed: canResend
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
          },
        );
      },
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Input
          CustomInput(
            label: 'Email',
            controller: _emailController,
            hint: 'Enter your email',
            prefixIcon: Icon(Icons.email, color: AppTheme.primaryColor),
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          const FormSpacing(height: 5),

          // Password Input
          PasswordField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            validator: validatePassword,
          ),
          const FormSpacing(height: 5),

          // Remember Me
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                activeColor: AppTheme.primaryColor,
                checkColor: Colors.white,
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              Text('Remember me', style: AppTheme.subtitleStyle),
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
    );
  }
}
