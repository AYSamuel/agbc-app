import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../services/location_service.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
import '../utils/theme.dart';
import '../widgets/mixins/location_validation_mixin.dart';
import '../widgets/mixins/form_validation_mixin.dart';
import '../providers/supabase_provider.dart';
import '../models/church_branch_model.dart';
import '../widgets/custom_dropdown.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onRegisterSuccess;

  const RegisterForm({
    super.key,
    required this.onRegisterSuccess,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> with LocationValidationMixin, FormValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationService = LocationService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGettingLocation = false;
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    initializeLocationValidation(
      controller: _locationController,
      locationService: _locationService,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    disposeLocationValidation();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final result = await _locationService.getCurrentLocation();
      if (result != null && !result.startsWith('Error')) {
        setState(() {
          _locationController.text = result;
        });
      } else if (mounted) {
        _showErrorSnackBar(result ?? 'Error getting location');
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    // Validate location
    if (locationError != null) {
      _showErrorSnackBar(locationError!);
      return;
    }

    // Validate branch selection
    if (_selectedBranchId == null) {
      _showErrorSnackBar('Please select a branch');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final user = await authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _locationController.text.trim(),
        'member',
        _selectedBranchId,
      );

      if (mounted) {
        // Show a snackbar about the verification email
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mark_email_unread, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verification email sent to ${_emailController.text.trim()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Resend',
              textColor: Colors.white,
              onPressed: () {
                authService.sendVerificationEmail();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email resent'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        );

        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e is AuthException) {
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
          // Name Field
          CustomInput(
            label: 'Full Name',
            controller: _nameController,
            hint: 'Enter your full name',
            prefixIcon: Icon(Icons.person, color: AppTheme.neutralColor),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: validateName,
            backgroundColor: Colors.white,
            labelColor: Colors.black87,
          ),
          const SizedBox(height: 16),

          // Email Field
          CustomInput(
            label: 'Email',
            controller: _emailController,
            hint: 'Enter your email',
            prefixIcon: Icon(Icons.email, color: AppTheme.neutralColor),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: validateEmail,
            backgroundColor: Colors.white,
            labelColor: Colors.black87,
          ),
          const SizedBox(height: 16),

          // Phone Field
          CustomInput(
            label: 'Phone Number',
            controller: _phoneController,
            hint: 'Enter your phone number',
            prefixIcon: Icon(Icons.phone, color: AppTheme.neutralColor),
            keyboardType: TextInputType.phone,
            validator: validatePhone,
            backgroundColor: Colors.white,
            labelColor: Colors.black87,
          ),
          const SizedBox(height: 16),

          // Location Field
          CustomInput(
            label: 'Location',
            controller: _locationController,
            hint: 'Enter your location',
            prefixIcon: Icon(Icons.location_on, color: AppTheme.neutralColor),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            suffixIcon: _isGettingLocation || isValidatingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neutralColor),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.my_location,
                      color: AppTheme.neutralColor,
                    ),
                    onPressed: _getCurrentLocation,
                  ),
            validator: validateLocation,
            backgroundColor: Colors.white,
            labelColor: Colors.black87,
          ),
          const SizedBox(height: 16),

          // Branch Selection
          StreamBuilder<List<ChurchBranch>>(
            stream: Provider.of<SupabaseProvider>(context).getAllBranches(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final branches = snapshot.data!;
              
              return CustomDropdown<String>(
                value: _selectedBranchId,
                label: 'Select Branch',
                hint: 'Select a branch',
                prefixIcon: Icons.church,
                items: branches.map((branch) {
                  return DropdownMenuItem<String>(
                    value: branch.id,
                    child: Text(branch.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBranchId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a branch';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          CustomInput(
            label: 'Password',
            controller: _passwordController,
            hint: 'Enter your password',
            prefixIcon: Icon(Icons.lock, color: AppTheme.neutralColor),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
            backgroundColor: Colors.white,
            labelColor: Colors.black87,
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          CustomInput(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            hint: 'Confirm your password',
            prefixIcon: Icon(Icons.lock, color: AppTheme.neutralColor),
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _register(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.neutralColor,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            backgroundColor: Colors.white,
            labelColor: Colors.black87,
          ),
          const SizedBox(height: 24),

          // Register Button
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: CustomButton(
              onPressed: _isLoading ? null : _register,
              backgroundColor: AppTheme.accentColor,
              child: _isLoading
                  ? const LoadingIndicator()
                  : const Text(
                      'Register',
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