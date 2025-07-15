import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import 'package:grace_portal/models/church_branch_model.dart';
import 'package:grace_portal/widgets/custom_input.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/utils/theme.dart';
import 'package:uuid/uuid.dart';
import 'package:grace_portal/widgets/custom_back_button.dart';
import 'package:grace_portal/models/user_model.dart';
import 'package:grace_portal/widgets/custom_dropdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isActive = true;
  String? _selectedPastorId;

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
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      final branch = ChurchBranch(
        id: const Uuid().v4().toLowerCase(),
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        pastorId: _selectedPastorId?.isNotEmpty == true
            ? _selectedPastorId?.toLowerCase()
            : null,
        createdBy: currentUserId.toLowerCase(),
        isActive: _isActive,
        departments: [],
        members: [],
      );

      await Provider.of<SupabaseProvider>(context, listen: false)
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
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Basic Information Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.darkNeutralColor.withValues(alpha: 0.05),
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
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomInput(
                          label: 'Branch Name',
                          controller: _nameController,
                          hint: 'Enter branch name',
                          prefixIcon:
                              Icon(Icons.church, color: AppTheme.neutralColor),
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
                          prefixIcon: Icon(Icons.location_on,
                              color: AppTheme.neutralColor),
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
                          prefixIcon:
                              Icon(Icons.home, color: AppTheme.neutralColor),
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
                          prefixIcon: Icon(Icons.description,
                              color: AppTheme.neutralColor),
                          focusNode: _descriptionFocus,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        // Pastor Selection
                        StreamBuilder<List<UserModel>>(
                          stream: Provider.of<SupabaseProvider>(context,
                                  listen: false)
                              .getAllUsers(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            final users = snapshot.data!;
                            final pastors = users
                                .where((user) => user.role == 'pastor')
                                .toList();
                            pastors.sort((a, b) =>
                                a.displayName.compareTo(b.displayName));

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Branch Pastor',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkNeutralColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CustomDropdown<String>(
                                  value: _selectedPastorId,
                                  label: 'Select Pastor',
                                  hint: 'Choose a pastor for this branch',
                                  prefixIcon: Icons.person,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('No Pastor Assigned'),
                                    ),
                                    ...pastors.map(
                                        (pastor) => DropdownMenuItem<String>(
                                              value: pastor.id,
                                              child: Text(pastor.displayName),
                                            )),
                                  ],
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedPastorId = value;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Active Status Toggle
                        Row(
                          children: [
                            Icon(
                              Icons.toggle_on,
                              color: _isActive
                                  ? AppTheme.accentColor
                                  : AppTheme.neutralColor,
                              size: 40,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Active Branch',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.darkNeutralColor,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                              activeColor: AppTheme.accentColor,
                            ),
                          ],
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
