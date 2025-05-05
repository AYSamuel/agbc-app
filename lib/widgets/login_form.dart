import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:agbc_app/services/preferences_service.dart';
import 'package:agbc_app/widgets/custom_input.dart';
import 'package:agbc_app/widgets/loading_indicator.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/widgets/mixins/form_validation_mixin.dart';

import 'form/form_spacing.dart';
import 'form/password_field.dart';
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
      builder: (context) => AlertDialog(
        title: const Text('Email Not Verified'),
        content: const Text(
          'Please check your email for a verification link. If you haven\'t received it, you can request a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthService>(context, listen: false)
                  .sendVerificationEmail();
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
