import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agbc_app/providers/firestore_provider.dart';
import 'package:agbc_app/models/church_branch_model.dart';
import 'package:agbc_app/widgets/custom_input.dart';
import 'package:agbc_app/widgets/custom_button.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:uuid/uuid.dart';
import 'package:agbc_app/widgets/custom_back_button.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Focus nodes for keyboard navigation
  final _nameFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    
    // Dispose focus nodes
    _nameFocus.dispose();
    _locationFocus.dispose();
    _addressFocus.dispose();
    _descriptionFocus.dispose();
    
    super.dispose();
  }

  Future<void> _addBranch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final branch = ChurchBranch(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: Provider.of<FirestoreProvider>(context, listen: false)
            .currentUser
            ?.uid ?? '',
      );

      await Provider.of<FirestoreProvider>(context, listen: false)
          .createBranch(branch);
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add branch: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Row(
                    children: [
                      CustomBackButton(
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Create New Branch',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Basic Information Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Branch Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomInput(
                          label: 'Branch Name',
                          controller: _nameController,
                          hint: 'Enter branch name',
                          prefixIcon: Icon(Icons.church, color: AppTheme.neutralColor),
                          focusNode: _nameFocus,
                          nextFocusNode: _locationFocus,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a branch name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          label: 'Location',
                          controller: _locationController,
                          hint: 'Enter branch location',
                          prefixIcon: Icon(Icons.location_on, color: AppTheme.neutralColor),
                          focusNode: _locationFocus,
                          nextFocusNode: _addressFocus,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          label: 'Address',
                          controller: _addressController,
                          hint: 'Enter branch address',
                          prefixIcon: Icon(Icons.home, color: AppTheme.neutralColor),
                          focusNode: _addressFocus,
                          nextFocusNode: _descriptionFocus,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          label: 'Description',
                          controller: _descriptionController,
                          hint: 'Enter branch description',
                          prefixIcon: Icon(Icons.description, color: AppTheme.neutralColor),
                          focusNode: _descriptionFocus,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  CustomButton(
                    onPressed: _isLoading ? null : _addBranch,
                    backgroundColor: AppTheme.accentColor,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Branch',
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
          ),
        ),
      ),
    );
  }
} 