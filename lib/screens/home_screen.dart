import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/widgets/radial_menu.dart';
import 'package:agbc_app/widgets/task_status_card.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/supabase_provider.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';

import 'add_branch_screen.dart';
import 'add_task_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showTaskCreationDialog(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user?.role == 'member') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Only workers, pastors, and administrators can create tasks'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
  }

  void _showMeetingCreationDialog(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user?.role != 'pastor' && user?.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only pastors and administrators can create meetings'),
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
        content:
            const Text('Meeting creation dialog will be implemented here.'),
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

    if (user?.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only administrators can create branches'),
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
    final supabaseProvider = Provider.of<SupabaseProvider>(context);
    final user = authService.currentUser;

    // Determine which options to show based on user role
    final bool showMeetings = user?.role == 'pastor' || user?.role == 'admin';
    final bool showBranches = user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Welcome and profile section
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
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
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.neutralColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.displayName ?? 'User',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile picture
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppTheme.primaryColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.cardColor,
                      backgroundImage: (user != null &&
                              user.photoUrl != null &&
                              user.photoUrl!.isNotEmpty)
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: (user == null ||
                              user.photoUrl == null ||
                              user.photoUrl!.isEmpty)
                          ? Icon(Icons.person,
                              size: 40, color: AppTheme.primaryColor)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            // Task Status Section
            StreamBuilder<List<TaskModel>>(
              stream: supabaseProvider.getTasksForUser(user?.id ?? ''),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return TaskStatusCard(tasks: snapshot.data!);
              },
            ),
            const SizedBox(height: 24),
            // Tasks and Meetings Section
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.neutralColor,
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
                            stream: supabaseProvider
                                .getTasksForUser(user?.id ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final tasks = snapshot.data!;
                              if (tasks.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.task_alt,
                                        size: 64,
                                        color: AppTheme.neutralColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Tasks',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'You have no tasks assigned',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: AppTheme.neutralColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    color: AppTheme.cardColor,
                                    child: ListTile(
                                      title: Text(
                                        task.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.darkNeutralColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        task.description,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppTheme.neutralColor,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: task.status == 'completed'
                                              ? AppTheme.successColor
                                                  .withValues(alpha: 0.1)
                                              : AppTheme.warningColor
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          task.status,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: task.status == 'completed'
                                                ? AppTheme.successColor
                                                : AppTheme.warningColor,
                                          ),
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
                            stream: supabaseProvider
                                .getMeetingsForUser(user?.id ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final meetings = snapshot.data!;
                              if (meetings.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 64,
                                        color: AppTheme.neutralColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Meetings',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'You have no meetings scheduled',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: AppTheme.neutralColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: meetings.length,
                                itemBuilder: (context, index) {
                                  final meeting = meetings[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    color: AppTheme.cardColor,
                                    child: ListTile(
                                      title: Text(
                                        meeting.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${meeting.dateTime.toString()} - ${meeting.location}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppTheme.neutralColor,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: meeting.status == 'completed'
                                              ? AppTheme.successColor
                                                  .withValues(alpha: 0.1)
                                              : AppTheme.primaryColor
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          meeting.status,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: meeting.status == 'completed'
                                                ? AppTheme.successColor
                                                : AppTheme.primaryColor,
                                          ),
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
      floatingActionButton: RadialMenu(
        onTaskPressed: () => _showTaskCreationDialog(context),
        onMeetingPressed:
            showMeetings ? () => _showMeetingCreationDialog(context) : null,
        onBranchPressed:
            showBranches ? () => _showBranchCreationDialog(context) : null,
        showBranchOption: showBranches,
        showMeetingOption: showMeetings,
      ),
    );
  }
}
