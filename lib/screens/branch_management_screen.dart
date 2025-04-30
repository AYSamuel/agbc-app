import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../models/church_branch_model.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import 'add_branch_screen.dart';

class BranchManagementScreen extends StatelessWidget {
  const BranchManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseProvider = Provider.of<SupabaseProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: AppTheme.cardColor,
                        child: ListTile(
                          title: Text(branch.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(branch.address),
                              const SizedBox(height: 4),
                              Text(
                                'Pastor: ${branch.pastorId ?? 'Not assigned'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Members: ${branch.members.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: user?.role == 'admin'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showEditBranchDialog(
                                          context, branch),
                                      color: AppTheme.primaryColor,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _showDeleteBranchDialog(
                                          context, branch),
                                      color: Colors.red,
                                    ),
                                  ],
                                )
                              : null,
                        ),
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

  void _showDeleteBranchDialog(BuildContext context, ChurchBranch branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Are you sure you want to delete ${branch.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SupabaseProvider>(context, listen: false)
                  .deleteBranch(branch.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
