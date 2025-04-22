import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/supabase_provider.dart';
import 'package:agbc_app/services/preferences_service.dart';
import 'package:agbc_app/widgets/custom_input.dart';
import 'package:agbc_app/widgets/custom_button.dart';
import 'package:agbc_app/widgets/loading_indicator.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/widgets/mixins/form_validation_mixin.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

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
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    // Check if we're coming from a logout
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
        // Auto-login if credentials are available
        _login();
      }
    } else {
      // Clear any saved credentials if remember me is not enabled
      await PreferencesService.clearLoginCredentials();
    }
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
      
      // Set remember me preference before login
      await authService.setRememberMe(_rememberMe);
      
      final user = await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user == null) {
        throw AuthException('Invalid email or password');
      }

      // Save credentials if remember me is enabled
      if (_rememberMe) {
        await PreferencesService.saveLoginCredentials(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
      }

      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        
        if (e is PostgrestException) {
          errorMessage = 'Database error: ${e.message}';
        } else if (e is AuthException) {
          errorMessage = 'Authentication error: ${e.message}';
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
            backgroundColor: Colors.white,
            elevation: 2,
            labelColor: Colors.black87,
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
            backgroundColor: Colors.white,
            elevation: 2,
            labelColor: Colors.black87,
          ),
          const SizedBox(height: 16),

          // Remember Me Checkbox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                Text(
                  'Remember Me',
                  style: TextStyle(
                    color: AppTheme.neutralColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Login Button
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: CustomButton(
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
          ),
        ],
      ),
    );
  }
} 