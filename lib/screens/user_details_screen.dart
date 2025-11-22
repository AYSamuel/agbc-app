import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import '../providers/branches_provider.dart';
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
  late UserRole selectedRole;
  late String? selectedBranchId;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.user.role;
    selectedBranchId = widget.user.branchId;
    // Refresh branches after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BranchesProvider>(context, listen: false).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(widget.user.role);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Back button and edit button row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomBackButton(
                            onPressed: () => Navigator.pop(context),
                            color: Colors.white,
                            showBackground: false,
                            showShadow: false,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              isEditing ? Icons.close_rounded : Icons.edit_rounded,
                              color: Colors.white,
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
                        ),
                      ],
                    ),
                  ),
                  // Profile section in header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      children: [
                        // Profile Picture
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.4),
                                Colors.white.withValues(alpha: 0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white.withValues(alpha: 0.9),
                              backgroundImage: widget.user.photoUrl != null &&
                                      widget.user.photoUrl!.isNotEmpty
                                  ? NetworkImage(widget.user.photoUrl!)
                                  : null,
                              child: widget.user.photoUrl == null ||
                                      widget.user.photoUrl!.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 52,
                                      color: AppTheme.primaryColor,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // User Info
                        Text(
                          widget.user.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.user.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: roleColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.user.role.name.toUpperCase(),
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // Contact Information
                  _buildModernSection(
                    icon: Icons.contact_mail_rounded,
                    title: 'Contact Information',
                    accentColor: AppTheme.primaryColor,
                    child: Column(
                      children: [
                        if (widget.user.phoneNumber != null) ...[
                          _buildInfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Phone',
                            value: widget.user.phoneNumber!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildInfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Location',
                          value: widget.user.locationString ?? 'Not set',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role and Branch Selection (only visible when editing)
                  if (isEditing) ...[
                    _buildModernSection(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Edit Role & Branch',
                      accentColor: AppTheme.secondaryColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role Selection
                          const Text(
                            'Role',
                            style: TextStyle(
                              color: AppTheme.darkNeutralColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomDropdown<UserRole>(
                            value: selectedRole,
                            items: const [
                              DropdownMenuItem(
                                value: UserRole.admin,
                                child: Text('Admin'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.pastor,
                                child: Text('Pastor'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.worker,
                                child: Text('Worker'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.member,
                                child: Text('Member'),
                              ),
                            ],
                            onChanged: (UserRole? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedRole = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          // Branch Selection
                          const Text(
                            'Branch',
                            style: TextStyle(
                              color: AppTheme.darkNeutralColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _saveChanges(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.darkNeutralColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppTheme.errorColor;
      case UserRole.pastor:
        return AppTheme.secondaryColor;
      case UserRole.worker:
        return AppTheme.accentColor;
      case UserRole.member:
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
        selectedRole.name,
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
          content: const Text(
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
            style: const TextStyle(
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
