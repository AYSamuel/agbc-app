import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/user_card.dart';
import 'user_details_screen.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseProvider = Provider.of<SupabaseProvider>(context);

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
                  Text(
                    'Users',
                    style: AppTheme.titleStyle.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            // Users List
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: supabaseProvider.getAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: AppTheme.subtitleStyle.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }
                  final users = snapshot.data!;

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Users Found',
                            style: AppTheme.titleStyle.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are currently no users in the system.',
                            style: AppTheme.subtitleStyle.copyWith(
                              color: AppTheme.neutralColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort users alphabetically by display name
                  users.sort((a, b) => a.displayName.compareTo(b.displayName));

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return UserCard(
                        user: user,
                        roleColor: _getRoleColor(user.role),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailsScreen(user: user),
                          ),
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
}
