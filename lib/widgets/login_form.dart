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
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _emailVerified = false;
  String? _emailError;

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
        _verifyEmail();
      }
    } else {
      await PreferencesService.clearLoginCredentials();
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

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final email = _emailController.text.trim();
      
      print('Checking email: $email'); // Debug log
      
      // Check if email exists in the system
      final user = await authService.checkEmailExists(email);
      
      print('User found: ${user != null}'); // Debug log
      
      if (user != null) {
        setState(() {
          _emailVerified = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _emailError = 'This email is not registered. Please register first.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _verifyEmail: $e'); // Debug log
      setState(() {
        if (e is AuthException) {
          _emailError = e.message;
        } else {
          _emailError = 'An error occurred while verifying your email. Please try again.';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.setRememberMe(_rememberMe);
      
      final user = await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user == null) {
        throw AuthException('Invalid password');
      }

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
          errorMessage = e.message;
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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verifyEmail(),
            validator: validateEmail,
            backgroundColor: Colors.white,
            labelColor: Colors.black87,
            errorText: _emailError,
          ),
          const SizedBox(height: 16),

          if (!_emailVerified) ...[
            // Continue Button
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: CustomButton(
                onPressed: _isLoading ? null : _verifyEmail,
                backgroundColor: AppTheme.primaryColor,
                child: _isLoading
                    ? const LoadingIndicator()
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ] else ...[
            // Password Field
            CustomInput(
              label: 'Password',
              controller: _passwordController,
              hint: 'Enter your password',
              prefixIcon: Icon(Icons.lock, color: AppTheme.primaryColor),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
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
              validator: validatePassword,
              backgroundColor: AppTheme.cardColor,
              labelColor: AppTheme.darkNeutralColor,
            ),
            const SizedBox(height: 16),

            // Remember Me Checkbox
            Row(
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(
                      color: AppTheme.neutralColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Remember Me',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Login Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _isLoading ? null : _login,
                  child: Center(
                    child: _isLoading
                        ? const LoadingIndicator()
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 