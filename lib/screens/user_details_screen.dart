import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import '../providers/branches_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_dropdown.dart';
import 'package:logging/logging.dart';
import '../models/church_branch_model.dart';

class UserDetailsScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailsScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _log = Logger('_UserDetailsScreenState');
  late String selectedRole;
  late String? selectedBranchId;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.user.role;
    selectedBranchId = widget.user.branchId;
    // Refresh branches when screen is opened
    Provider.of<BranchesProvider>(context, listen: false).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CustomBackButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'User Details',
                    style: AppTheme.titleStyle.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      isEditing ? Icons.close : Icons.edit,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        isEditing = !isEditing;
                        if (!isEditing) {
                          // Reset values when canceling edit
                          selectedRole = widget.user.role;
                          selectedBranchId = widget.user.branchId;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: [
                  // Profile Section
                  CustomCard(
                    child: Column(
                      children: [
                        // Profile Picture
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.1),
                            backgroundImage: widget.user.photoUrl != null &&
                                    widget.user.photoUrl!.isNotEmpty
                                ? NetworkImage(widget.user.photoUrl!)
                                : null,
                            child: widget.user.photoUrl == null ||
                                    widget.user.photoUrl!.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 48,
                                    color: AppTheme.primaryColor,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // User Info
                        Text(
                          widget.user.displayName,
                          style: AppTheme.titleStyle.copyWith(
                            fontSize: 24,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.user.email,
                          style: AppTheme.subtitleStyle.copyWith(
                            color: AppTheme.neutralColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(widget.user.role)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getRoleColor(widget.user.role)
                                  .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.user.role.toUpperCase(),
                            style: TextStyle(
                              color: _getRoleColor(widget.user.role),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact Information
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Information',
                          style: AppTheme.titleStyle.copyWith(
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.user.phoneNumber != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 24,
                                color: AppTheme.neutralColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.user.phoneNumber!,
                                style: AppTheme.subtitleStyle.copyWith(
                                  color: AppTheme.neutralColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 24,
                              color: AppTheme.neutralColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.user.location ?? 'Not set',
                                style: AppTheme.subtitleStyle.copyWith(
                                  color: AppTheme.neutralColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role and Branch Selection (only visible when editing)
                  if (isEditing) ...[
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Role & Branch',
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Role Selection
                          Text(
                            'Role',
                            style: AppTheme.subtitleStyle.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomDropdown<String>(
                            value: selectedRole,
                            items: const [
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('Admin'),
                              ),
                              DropdownMenuItem(
                                value: 'pastor',
                                child: Text('Pastor'),
                              ),
                              DropdownMenuItem(
                                value: 'worker',
                                child: Text('Worker'),
                              ),
                              DropdownMenuItem(
                                value: 'member',
                                child: Text('Member'),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedRole = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          // Branch Selection
                          Text(
                            'Branch',
                            style: AppTheme.subtitleStyle.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Builder(builder: (context) {
                            final branches =
                                Provider.of<BranchesProvider>(context).branches;

                            // Create a map with branch IDs as keys to ensure uniqueness
                            final Map<String, ChurchBranch> uniqueBranchesMap =
                                {};
                            for (var branch in branches) {
                              if (branch.id.isNotEmpty) {
                                uniqueBranchesMap[branch.id] = branch;
                              }
                            }

                            // Convert map values to list and sort by name
                            final uniqueBranches = uniqueBranchesMap.values
                                .toList()
                              ..sort((a, b) => a.name.compareTo(b.name));

                            final dropdownItems = uniqueBranches
                                .map((branch) => DropdownMenuItem<String>(
                                      value: branch.id,
                                      child: Text(branch.name),
                                    ))
                                .toList();

                            _log.info('Selected Branch ID: $selectedBranchId');
                            _log.info(
                                'Available Branch IDs: ${uniqueBranches.map((b) => b.id).toList()}');

                            return CustomDropdown<String>(
                              value: selectedBranchId,
                              hint: 'Select Branch',
                              items: dropdownItems,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedBranchId = newValue;
                                  });
                                }
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save Button
                    ElevatedButton(
                      onPressed: () => _saveChanges(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.errorColor;
      case 'pastor':
        return AppTheme.secondaryColor;
      case 'worker':
        return AppTheme.accentColor;
      case 'member':
      default:
        return AppTheme.successColor;
    }
  }

  Future<void> _saveChanges(BuildContext context) async {
    try {
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);

      // Update role
      await supabaseProvider.updateUserRole(
        widget.user.id,
        selectedRole,
      );

      // Update branch if changed
      if (selectedBranchId != widget.user.branchId) {
        _log.info(
            'Updating branch from ${widget.user.branchId} to $selectedBranchId');
        final updatedUser = widget.user.copyWith(branchId: selectedBranchId);
        await supabaseProvider.updateUser(updatedUser);
      }

      if (!context.mounted) return;

      setState(() {
        isEditing = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User updated successfully',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Force a rebuild of the screen
      setState(() {});
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating user: $e',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
