import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import 'package:grace_portal/models/church_branch_model.dart';
import 'package:grace_portal/widgets/custom_input.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/widgets/custom_card.dart';
import 'package:grace_portal/widgets/form/location_field.dart'; // Add this import
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
  final _stateController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Location data for the LocationField
  Map<String, String> _locationData = {'city': '', 'country': ''};

  // Focus nodes for keyboard navigation (removed city and country focus nodes)
  final _nameFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  bool _isLoading = false;
  bool _isActive = true;
  String? _selectedPastorId;

  @override
  void dispose() {
    _nameController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _stateFocus.dispose();
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

      // Create location map from LocationField data and state field
      final location = <String, dynamic>{};
      if (_locationData['city']?.trim().isNotEmpty == true) {
        location['city'] = _locationData['city']!.trim();
      }
      if (_stateController.text.trim().isNotEmpty) {
        location['state'] = _stateController.text.trim();
      }
      if (_locationData['country']?.trim().isNotEmpty == true) {
        location['country'] = _locationData['country']!.trim();
      }

      final branch = ChurchBranch(
        id: const Uuid().v4().toLowerCase(),
        name: _nameController.text.trim(),
        location: location,
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        pastorId: _selectedPastorId?.isNotEmpty == true
            ? _selectedPastorId?.toLowerCase()
            : null,
        createdBy: currentUserId.toLowerCase(),
        isActive: _isActive,
      );

      final success =
          await Provider.of<SupabaseProvider>(context, listen: false)
              .createBranch(branch);

      if (!mounted) return; // Add this check

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch created successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create branch. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Header Section using existing components
                Row(
                  children: [
                    CustomBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Branch',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkNeutralColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add a new church branch to expand your ministry',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutralColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Form using CustomCard for better visual grouping
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        'Branch Details',
                        'Basic information about the new branch',
                        Icons.business,
                      ),
                      const SizedBox(height: 24),

                      // Branch Name using existing CustomInput
                      CustomInput(
                        label: 'Branch Name',
                        hint: 'Enter the branch name',
                        controller: _nameController,
                        focusNode: _nameFocus,
                        nextFocusNode:
                            _stateFocus, // Changed from _cityFocus to _stateFocus
                        prefixIcon: const Icon(Icons.church),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Branch name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Location Section Header
                      _buildSectionHeader(
                        'Location',
                        'Where is this branch located?',
                        Icons.location_on,
                      ),
                      const SizedBox(height: 16),

                      // Location Field with Autocomplete (replaces City and Country fields)
                      LocationField(
                        initialLocation: _locationData,
                        onLocationChanged: (location) {
                          setState(() {
                            _locationData = location;
                          });
                        },
                        validator: (location) {
                          if (location['city']?.isEmpty == true ||
                              location['country']?.isEmpty == true) {
                            return 'Both city and country are required';
                          }
                          return null;
                        },
                        formKey: _formKey,
                      ),
                      const SizedBox(height: 16),

                      // State/Province Input (kept as separate field)
                      CustomInput(
                        label: 'State/Province',
                        hint: 'Enter state or province',
                        controller: _stateController,
                        focusNode: _stateFocus,
                        nextFocusNode: _addressFocus,
                        prefixIcon: const Icon(Icons.map),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'State/Province is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address Input
                      CustomInput(
                        label: 'Address',
                        hint: 'Enter full address',
                        controller: _addressController,
                        focusNode: _addressFocus,
                        nextFocusNode: _descriptionFocus,
                        prefixIcon: const Icon(Icons.home),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Description Section
                      _buildSectionHeader(
                        'Description',
                        'Tell us more about this branch',
                        Icons.description,
                      ),
                      const SizedBox(height: 16),

                      CustomInput(
                        label: 'Description',
                        hint: 'Enter branch description (optional)',
                        controller: _descriptionController,
                        focusNode: _descriptionFocus,
                        prefixIcon: const Icon(Icons.notes),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      // Pastor Selection Section
                      _buildSectionHeader(
                        'Pastor Assignment',
                        'Select a pastor for this branch',
                        Icons.person,
                      ),
                      const SizedBox(height: 16),

                      // Pastor Dropdown (using corrected method and property names)
                      StreamBuilder<List<UserModel>>(
                        stream: Provider.of<SupabaseProvider>(context,
                                listen: false)
                            .getAllUsers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final pastors = snapshot.data
                                  ?.where(
                                      (user) => user.role == UserRole.pastor)
                                  .toList() ??
                              [];

                          return CustomDropdown<String>(
                            value: _selectedPastorId,
                            hint: 'Select a pastor',
                            items: pastors.map((pastor) {
                              return DropdownMenuItem<String>(
                                value: pastor.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.person,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        pastor.displayName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPastorId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a pastor';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Active Status Section
                      _buildSectionHeader(
                        'Status',
                        'Set the initial status of this branch',
                        Icons.toggle_on,
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isActive
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _isActive
                                  ? AppTheme.successColor
                                  : AppTheme.neutralColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Branch',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _isActive
                                        ? 'This branch will be immediately available'
                                        : 'This branch will be created as inactive',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.neutralColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                              activeThumbColor: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button using CustomButton
                CustomButton(
                  onPressed: _isLoading ? null : _addBranch,
                  isLoading: _isLoading,
                  width: double.infinity,
                  height: 56,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    'Create Branch',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkNeutralColor,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutralColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
