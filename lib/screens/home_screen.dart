import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/widgets/radial_menu.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/firestore_provider.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/church_model.dart';
import 'user_management_screen.dart';
import 'task_management_screen.dart';
import 'meeting_management_screen.dart';
import 'admin_screen.dart';
import 'add_branch_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showTaskCreationDialog(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (!(user?.hasPermission('create_tasks') ?? false) || user?.role == 'member') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only workers, pastors, and administrators can create tasks'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement task creation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Task'),
        content: const Text('Task creation dialog will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMeetingCreationDialog(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (!(user?.hasPermission('create_meetings') ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to create meetings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement meeting creation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Meeting'),
        content: const Text('Meeting creation dialog will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBranchCreationDialog(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (!(user?.hasPermission('manage_church') ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only administrators can create church branches'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBranchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: true);
    final firestoreProvider = Provider.of<FirestoreProvider>(context);
    final user = authService.currentUser;

    // Determine which options to show based on user role
    final bool showTasks = user?.role != 'member';
    final bool showMeetings = user?.role == 'pastor' || user?.role == 'admin';
    final bool showBranches = user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Welcome and profile section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Welcome and name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile picture
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.transparent,
                      backgroundImage: (user != null && user.photoUrl != null && user.photoUrl!.isNotEmpty)
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: (user == null || user.photoUrl == null || user.photoUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 40, color: Color(0xFFB0BEC5))
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            // Tasks and Meetings Section
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: const [
                        Tab(text: 'Tasks'),
                        Tab(text: 'Meetings'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tasks Tab
                          StreamBuilder<List<TaskModel>>(
                            stream: firestoreProvider.getTasksForUser(user?.uid ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final tasks = snapshot.data!;
                              if (tasks.isEmpty) {
                                return const Center(
                                  child: Text('No tasks assigned'),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: ListTile(
                                      title: Text(task.title),
                                      subtitle: Text(task.description),
                                      trailing: Text(
                                        task.status,
                                        style: TextStyle(
                                          color: task.status == 'completed'
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          // Meetings Tab
                          StreamBuilder<List<MeetingModel>>(
                            stream: firestoreProvider.getMeetingsForUser(user?.uid ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final meetings = snapshot.data!;
                              if (meetings.isEmpty) {
                                return const Center(
                                  child: Text('No meetings scheduled'),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: meetings.length,
                                itemBuilder: (context, index) {
                                  final meeting = meetings[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: ListTile(
                                      title: Text(meeting.title),
                                      subtitle: Text(
                                        '${meeting.dateTime.toString()} - ${meeting.location}',
                                      ),
                                      trailing: Text(
                                        meeting.status,
                                        style: TextStyle(
                                          color: meeting.status == 'completed'
                                              ? Colors.green
                                              : Colors.blue,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: user?.role != 'member' 
          ? RadialMenu(
              onTaskPressed: () => _showTaskCreationDialog(context),
              onMeetingPressed: showMeetings ? () => _showMeetingCreationDialog(context) : null,
              onBranchPressed: showBranches ? () => _showBranchCreationDialog(context) : null,
              showBranchOption: showBranches,
              showMeetingOption: showMeetings,
            )
          : null,
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'pastor':
        return Colors.purple;
      case 'worker':
        return Colors.blue;
      case 'member':
      default:
        return Colors.green;
    }
  }
}
