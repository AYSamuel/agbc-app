import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import '../providers/supabase_provider.dart';
import 'package:grace_portal/models/church_branch_model.dart';
import 'package:grace_portal/widgets/custom_input.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/widgets/form/location_field.dart';
import 'package:grace_portal/config/theme.dart';
import 'package:uuid/uuid.dart';
import 'package:grace_portal/widgets/custom_back_button.dart';
import 'package:grace_portal/models/user_model.dart';
import 'package:grace_portal/widgets/custom_dropdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_toast.dart';

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
        CustomToast.show(context,
            message: 'Branch created successfully', type: ToastType.success);
        Navigator.pop(context);
      } else {
        CustomToast.show(context,
            message: 'Failed to create branch. Please try again.',
            type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context,
            message: 'Failed to add branch: $e', type: ToastType.error);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomBackButton(
                        onPressed: () => Navigator.pop(context),
                        showBackground: false,
                        showShadow: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Remix.community_line,
                        color: AppTheme.primary(context),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Branch',
                            style: AppTheme.titleStyle(context).copyWith(
                              color: AppTheme.textPrimary(context),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Expand your ministry reach',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Branch Details Card
                      _buildModernSection(
                        icon: Remix.community_line,
                        title: 'Branch Details',
                        accentColor: AppTheme.primary(context),
                        child: Column(
                          children: [
                            CustomInput(
                              label: 'Branch Name',
                              hint: 'Enter the branch name',
                              controller: _nameController,
                              focusNode: _nameFocus,
                              nextFocusNode: _stateFocus,
                              prefixIcon: const Icon(Remix.community_line),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Branch name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomInput(
                              label: 'Description',
                              hint: 'Enter branch description (optional)',
                              controller: _descriptionController,
                              focusNode: _descriptionFocus,
                              prefixIcon: const Icon(Remix.file_list_2_line),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Location Card
                      _buildModernSection(
                        icon: Remix.map_pin_line,
                        title: 'Location',
                        accentColor: AppTheme.secondary(context),
                        child: Column(
                          children: [
                            LocationField(
                              initialLocation: _locationData,
                              onLocationChanged: (location) {
                                setState(() {
                                  _locationData = location;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomInput(
                              label: 'State/Province',
                              hint: 'Enter state or province',
                              controller: _stateController,
                              focusNode: _stateFocus,
                              nextFocusNode: _addressFocus,
                              prefixIcon: const Icon(Remix.map_2_line),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'State/Province is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomInput(
                              label: 'Address',
                              hint: 'Enter full address',
                              controller: _addressController,
                              focusNode: _addressFocus,
                              nextFocusNode: _descriptionFocus,
                              prefixIcon: const Icon(Remix.home_4_line),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Address is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pastor Assignment Card
                      _buildModernSection(
                        icon: Remix.user_line,
                        title: 'Pastor Assignment',
                        accentColor: AppTheme.secondary(context),
                        child: StreamBuilder<List<UserModel>>(
                          stream: Provider.of<SupabaseProvider>(context,
                                  listen: false)
                              .getAllUsers(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ));
                            }

                            final pastors = snapshot.data ?? [];

                            return CustomDropdown<String>(
                              value: _selectedPastorId,
                              label: 'Select Pastor',
                              hint: 'Choose a pastor for this branch',
                              items: pastors.map((pastor) {
                                return DropdownMenuItem<String>(
                                  value: pastor.id,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.05),
                                        child: Icon(
                                          Remix.user_line,
                                          size: 16,
                                          color: AppTheme.primary(context),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          pastor.displayName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
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
                      ),
                      const SizedBox(height: 20),

                      // Status Card
                      _buildModernSection(
                        icon: Remix.toggle_line,
                        title: 'Branch Status',
                        accentColor: AppTheme.primary(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isActive
                                ? AppTheme.success(context)
                                    .withValues(alpha: 0.1)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isActive
                                  ? AppTheme.success(context)
                                      .withValues(alpha: 0.3)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isActive
                                    ? Remix.checkbox_circle_line
                                    : Remix.checkbox_blank_circle_line,
                                color: _isActive
                                    ? AppTheme.success(context)
                                    : Theme.of(context).disabledColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isActive
                                          ? 'Active Branch'
                                          : 'Inactive Branch',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _isActive
                                          ? 'Branch will be immediately available'
                                          : 'Branch will be created as inactive',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
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
                                activeTrackColor: AppTheme.success(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      CustomButton(
                        onPressed: _isLoading ? null : _addBranch,
                        isLoading: _isLoading,
                        width: double.infinity,
                        height: 56,
                        child: Text(
                          _isLoading ? 'Creating Branch...' : 'Create Branch',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with colored accent
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}
