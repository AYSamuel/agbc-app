import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../models/church_branch_model.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/branch_card.dart';
import 'add_branch_screen.dart';
import '../services/notification_service.dart';

class BranchManagementScreen extends StatelessWidget {
  const BranchManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseProvider = Provider.of<SupabaseProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CustomBackButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Branches',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const Spacer(),
                  if (user?.role == 'admin')
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await notificationService
                                  .sendBroadcastNotification(
                                title: 'Test Notification',
                                message:
                                    'This is a test notification from the app',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Test notification sent!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.notifications),
                          label: const Text('Test Notification'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddBranchScreen(),
                              fullscreenDialog: true,
                            ),
                          ),
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                ],
              ),
            ),
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
                        onEdit: user?.role == 'admin'
                            ? () => _showEditBranchDialog(context, branch)
                            : null,
                        onDelete: user?.role == 'admin'
                            ? () => _deleteBranch(context, branch)
                            : null,
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

  Future<void> _deleteBranch(BuildContext context, ChurchBranch branch) async {
    try {
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);

      // Check if there are users in this branch
      final users = await supabaseProvider.getAllUsers().first;
      final usersInBranch =
          users.where((user) => user.branchId == branch.id).toList();

      if (usersInBranch.isNotEmpty) {
        // Show warning dialog
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Warning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'This branch has ${usersInBranch.length} user${usersInBranch.length > 1 ? 's' : ''} assigned to it.'),
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

        if (result != true) {
          return;
        }

        // Clear branchId for all users in this branch
        for (final user in usersInBranch) {
          final updatedUser = user.copyWith(branchId: null);
          await supabaseProvider.updateUser(updatedUser);
        }
      }

      // Proceed with deletion
      if (context.mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Branch'),
            content: Text('Are you sure you want to delete ${branch.name}?'),
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

        if (confirm == true) {
          await supabaseProvider.deleteBranch(branch.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Branch deleted successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting branch: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showBranchDetails(BuildContext context, ChurchBranch branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(branch.name),
        content: Column(
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
            Text(branch.location),
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
              'Members: ${branch.members.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
