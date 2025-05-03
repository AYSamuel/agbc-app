import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
import '../utils/theme.dart';
import '../widgets/mixins/form_validation_mixin.dart';
import '../providers/supabase_provider.dart';
import '../models/church_branch_model.dart';
import '../widgets/custom_dropdown.dart';
import 'form/password_field.dart';
import 'form/location_field.dart';
import 'form/form_spacing.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onRegisterSuccess;

  const RegisterForm({
    super.key,
    required this.onRegisterSuccess,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> with FormValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationService = LocationService();
  bool _isLoading = false;
  String? _selectedBranchId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    super.dispose();
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

    // Validate branch selection
    if (_selectedBranchId == null) {
      _showErrorSnackBar('Please select a branch');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.registerWithEmailAndPassword(
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

        widget.onRegisterSuccess();
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name Field
          CustomInput(
            label: 'Full Name',
            controller: _nameController,
            hint: 'Enter your full name',
            prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: validateName,
          ),
          const FormSpacing(),

          // Email Field
          CustomInput(
            label: 'Email',
            controller: _emailController,
            hint: 'Enter your email',
            prefixIcon: Icon(Icons.email, color: AppTheme.primaryColor),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: validateEmail,
          ),
          const FormSpacing(),

          // Phone Field
          CustomInput(
            label: 'Phone Number',
            controller: _phoneController,
            hint: 'Enter your phone number',
            prefixIcon: Icon(Icons.phone, color: AppTheme.primaryColor),
            keyboardType: TextInputType.phone,
            validator: validatePhone,
          ),
          const FormSpacing(),

          // Location Field
          LocationField(
            controller: _locationController,
            label: 'Location',
            hint: 'Enter your location',
            locationService: _locationService,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: validateLocation,
          ),
          const FormSpacing(),

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
          const FormSpacing(),

          // Password Field
          PasswordField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: validatePassword,
          ),
          const FormSpacing(),

          // Confirm Password Field
          PasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _register(),
            validator: validatePassword,
            isConfirmField: true,
            confirmController: _passwordController,
          ),
          const FormSpacing(height: 32),

          // Register Button
          CustomButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading
                ? const LoadingIndicator()
                : const Text(
                    'Create Account',
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
