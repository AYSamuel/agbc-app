import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:agbc_app/services/preferences_service.dart';
import 'package:agbc_app/widgets/custom_input.dart';
import 'package:agbc_app/widgets/loading_indicator.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/widgets/mixins/form_validation_mixin.dart';
import 'form/password_field.dart';
import 'form/form_spacing.dart';
import 'custom_button.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool isLoggingOut;

  const LoginForm({
    super.key,
    required this.onLoginSuccess,
    this.isLoggingOut = false,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with FormValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    if (widget.isLoggingOut) {
      return;
    }

    final isRememberMeEnabled = await PreferencesService.isRememberMeEnabled();
    if (isRememberMeEnabled) {
      final savedEmail = await PreferencesService.getSavedEmail();
      final savedPassword = await PreferencesService.getSavedPassword();

      if (savedEmail != null && savedPassword != null) {
        setState(() {
          _rememberMe = true;
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
        });
      }
    } else {
      await PreferencesService.clearLoginCredentials();
    }
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_email_unread,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'We need to verify your email address before you can log in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We sent a verification link to your email when you registered. Please check your inbox and click the link to verify your email address.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you haven\'t received the email or the link has expired, you can request a new one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthService>(context, listen: false)
                  .sendVerificationEmailTo(_emailController.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'A new verification email has been sent to your inbox'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  void _showInvalidCredentialsDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
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
        title: const Text('Login Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
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
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: validateEmail,
            backgroundColor: Colors.white,
            labelColor: Colors.black87,
          ),
          const FormSpacing(height: 18),

          // Password Input
          PasswordField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            validator: validatePassword,
          ),
          const FormSpacing(height: 10),

          // Remember Me
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              Text('Remember me', style: AppTheme.regularTextStyle),
              const Spacer(),
            ],
          ),
          const FormSpacing(height: 20),

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
