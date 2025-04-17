import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firestore_provider.dart';
import 'user_management_screen.dart';
import 'task_management_screen.dart';
import 'meeting_management_screen.dart';
import 'branch_management_screen.dart';
import '../utils/theme.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildAdminCard(
              context,
              icon: Icons.people,
              title: 'Users',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              ),
            ),
            _buildAdminCard(
              context,
              icon: Icons.task,
              title: 'Tasks',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaskManagementScreen(),
                ),
              ),
            ),
            _buildAdminCard(
              context,
              icon: Icons.calendar_today,
              title: 'Meetings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MeetingManagementScreen(),
                ),
              ),
            ),
            _buildAdminCard(
              context,
              icon: Icons.church,
              title: 'Branches',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BranchManagementScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 