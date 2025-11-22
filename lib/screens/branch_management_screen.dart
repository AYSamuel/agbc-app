import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../models/church_branch_model.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/branch_card.dart';
import 'add_branch_screen.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final supabaseProvider = Provider.of<SupabaseProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Back button and add button row
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
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddBranchScreen(),
                                fullscreenDialog: true,
                              ),
                            ),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Title and subtitle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.location_city,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Branch Management',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Manage church branches',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
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
            // Branches List
            Expanded(
              child: StreamBuilder<List<ChurchBranch>>(
                stream: supabaseProvider.getAllBranches(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final branches = snapshot.data!;

                  if (branches.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.church,
                            size: 64,
                            color: Color(0xFF1A237E),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Branches Found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'There are currently no branches in the system.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort branches alphabetically by name
                  branches.sort((a, b) => a.name.compareTo(b.name));

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      return BranchCard(
                        branch: branch,
                        // Always provide edit and delete callbacks since only admins can access this screen
                        onEdit: () => _showEditBranchDialog(context, branch),
                        onDelete: () => _deleteBranch(context, branch),
                        onView: () => _showBranchDetails(context, branch),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBranchDialog(BuildContext context, ChurchBranch branch) {
    // TODO: Implement branch edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Branch'),
        content: const Text('Branch edit dialog will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Add this helper method at the top of the class
  void _safeShowSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Silently fail if we can't show the snackbar
      debugPrint('Failed to show snackbar: $e');
    }
  }

  Future<void> _deleteBranch(BuildContext context, ChurchBranch branch) async {
    try {
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);

      // Check if there are users in this branch
      final users = await supabaseProvider.getAllUsers().first;
      final usersInBranch =
          users.where((user) => user.branchId == branch.id).toList();

      if (usersInBranch.isNotEmpty) {
        if (!mounted || !context.mounted) return;
        // Show warning dialog
        final result = await _showWarningDialog(context, usersInBranch.length);
        if (result != true) return;

        // Clear branchId for all users in this branch
        for (final user in usersInBranch) {
          final updatedUser = user.copyWith(branchId: null);
          await supabaseProvider.updateUser(updatedUser);
        }
      }

      // Proceed with deletion
      if (!mounted || !context.mounted) return;
      final confirm = await _showDeleteConfirmationDialog(context, branch.name);
      if (confirm == true) {
        await supabaseProvider.deleteBranch(branch.id);
        _safeShowSnackBar('Branch deleted successfully');
      }
    } catch (e) {
      _safeShowSnackBar(
        'Error deleting branch: ${e.toString()}',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<bool?> _showWarningDialog(BuildContext context, int userCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'This branch has $userCount user${userCount > 1 ? 's' : ''} assigned to it.'),
            const SizedBox(height: 16),
            const Text(
                'Deleting this branch will remove the branch assignment for these users. They will see "No branch joined yet" in their profiles.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete Anyway'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context, String branchName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Are you sure you want to delete $branchName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Updated method to show branch details with members
  void _showBranchDetails(BuildContext context, ChurchBranch branch) async {
    try {
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);

      // Get all users in this branch
      final users = await supabaseProvider.getAllUsers().first;
      final branchMembers =
          users.where((user) => user.branchId == branch.id).toList();

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(branch.name),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(branch.locationString),
                const SizedBox(height: 16),
                const Text(
                  'Address:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(branch.address),
                const SizedBox(height: 16),
                if (branch.description != null) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(branch.description!),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Members (${branchMembers.length}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (branchMembers.isEmpty)
                  const Text(
                    'No members in this branch yet.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  SizedBox(
                    height: 200, // Constrain height for scrolling
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: branchMembers.length,
                      itemBuilder: (context, index) {
                        final member = branchMembers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                member.fullName.isNotEmpty
                                    ? member.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              member.fullName.isNotEmpty
                                  ? member.fullName
                                  : 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Chip(
                              label: Text(
                                member.role.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: _getRoleColor(member.role),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _safeShowSnackBar(
        'Error loading branch details: ${e.toString()}',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  // Helper method to get role colors
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
}
