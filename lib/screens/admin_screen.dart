import 'package:flutter/material.dart';
import 'user_management_screen.dart';
import 'task_management_screen.dart';
import 'meeting_management_screen.dart';
import 'branch_management_screen.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/admin_card.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {
                      // Simply pop back to the previous screen
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Admin Dashboard',
                    style: AppTheme.titleStyle.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate the size of each card based on available space
                  final cardWidth = (constraints.maxWidth - 48) /
                      2; // 48 = padding (16) + spacing (16)
                  final cardHeight = cardWidth * 1.2; // Maintain aspect ratio

                  return GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: cardWidth / cardHeight,
                    children: [
                      AdminCard(
                        icon: Icons.people,
                        title: 'Users',
                        description: 'Manage church members and roles',
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        ),
                      ),
                      AdminCard(
                        icon: Icons.task,
                        title: 'Tasks',
                        description: 'Assign and track church tasks',
                        color: AppTheme.accentColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TaskManagementScreen(),
                          ),
                        ),
                      ),
                      AdminCard(
                        icon: Icons.calendar_today,
                        title: 'Meetings',
                        description: 'Schedule and manage meetings',
                        color: AppTheme.secondaryColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MeetingManagementScreen(),
                          ),
                        ),
                      ),
                      AdminCard(
                        icon: Icons.church,
                        title: 'Branches',
                        description: 'Manage church branches',
                        color: AppTheme.successColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BranchManagementScreen(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
