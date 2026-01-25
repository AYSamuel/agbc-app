import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
import '../config/theme.dart';
import '../widgets/mixins/form_validation_mixin.dart';
import '../widgets/custom_dropdown.dart';
import 'form/password_field.dart';
import 'form/location_field.dart';
import 'form/form_spacing.dart';
import '../providers/branches_provider.dart';
import '../widgets/custom_toast.dart';

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
  bool _isLoading = false;
  String? _selectedBranchId;
  Map<String, String> _locationData = {'city': '', 'country': ''};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      CustomToast.show(context, message: message, type: ToastType.error);
    }
  }

  String _formatLocationString() {
    final city = _locationData['city']?.trim() ?? '';
    final country = _locationData['country']?.trim() ?? '';

    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    } else if (city.isNotEmpty) {
      return city;
    } else if (country.isNotEmpty) {
      return country;
    }
    return '';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    // Dismiss keyboard before registration
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (kDebugMode) {
        debugPrint('Calling registerWithEmailAndPassword...');
      }
      await authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _formatLocationString(),
        'member', // Default role for new registrations
        _selectedBranchId,
      );
      if (kDebugMode) {
        debugPrint('Registration call succeeded');
      }

      if (mounted) {
        // Show simple verification dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Email Verification Required'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_unread,
                    size: 64,
                    color: AppTheme.accentColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'A verification link has been sent to your email. Please check your email and click the link to verify your account.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRegisterSuccess();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Registration error: $e');
        debugPrint(stack.toString());
      }
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
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name Field
            CustomInput(
              label: 'Full Name',
              controller: _nameController,
              hint: 'Enter only your first and last name',
              prefixIcon: const Icon(Icons.person),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              validator: validateName,
              autofillHints: const [AutofillHints.name],
            ),
            const FormSpacing(),

            // Email Field
            CustomInput(
              label: 'Email',
              controller: _emailController,
              hint: 'Enter your email',
              prefixIcon: const Icon(Icons.email),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              validator: validateEmail,
              autofillHints: const [AutofillHints.email],
            ),
            const FormSpacing(),

            // Phone Field
            CustomInput(
              label: 'Phone Number',
              controller: _phoneController,
              hint: 'Enter with country code (e.g., +1234567890)',
              prefixIcon: const Icon(Icons.phone),
              keyboardType: TextInputType.phone,
              validator: validatePhone,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
            const FormSpacing(),

            // Location Field
            LocationField(
              initialLocation: _locationData,
              onLocationChanged: (location) {
                setState(() {
                  _locationData = location;
                });
              },
            ),
            const FormSpacing(),

            // Branch Selection
            Consumer<BranchesProvider>(
              builder: (context, branchesProvider, child) {
                final branches = branchesProvider.branches;
                if (branches.isEmpty) {
                  return Text(
                    'No branches available',
                    style: AppTheme.regularTextStyle(context).copyWith(
                      color: AppTheme.errorColor,
                    ),
                  );
                }

                return CustomDropdown<String>(
                  value: _selectedBranchId,
                  label: 'Select Branch',
                  hint: 'Choose your church branch',
                  prefixIcon: Icons.church,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a branch';
                    }
                    return null;
                  },
                  items: branches.map((branch) {
                    return DropdownMenuItem<String>(
                      value: branch.id,
                      child: Text(
                        branch.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBranchId = value;
                    });
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
              autofillHints: const [AutofillHints.newPassword],
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
              autofillHints: const [AutofillHints.newPassword],
            ),
            const FormSpacing(height: 32),

            // Register Button
            CustomButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const LoadingIndicator()
                  : Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
