import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'package:remixicon/remixicon.dart';

/// A screen that displays the details of a task
class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({
    required this.task,
    super.key,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late TaskModel _task;
  UserModel? _creator;
  UserModel? _assignee;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadUserDetails();
    // Set status bar to transparent with dark icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    // Reset status bar to default when leaving the screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    final supabaseService = SupabaseService();

    // Load creator details
    final creatorStream = supabaseService.getUser(_task.createdBy);
    creatorStream.listen((user) {
      if (mounted) {
        setState(() {
          _creator = user;
        });
      }
    });

    // Load assignee details
    final assigneeStream = supabaseService.getUser(_task.assignedTo);
    assigneeStream.listen((user) {
      if (mounted) {
        setState(() {
          _assignee = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Task Details',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkNeutralColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      _task.title,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkNeutralColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Remix.file_text_line,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Description',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _task.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.neutralColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status and Priority
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Status',
                            _task.status.toUpperCase(),
                            _getStatusColor(_task.status),
                            Remix.checkbox_circle_line,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            'Priority',
                            _task.priority.toUpperCase(),
                            _getPriorityColor(_task.priority),
                            Remix.flag_line,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    _buildInfoCard(
                      'Due Date',
                      _formatDateTime(_task.dueDate),
                      Colors.blue,
                      Remix.calendar_line,
                    ),
                    const SizedBox(height: 16),

                    // Creator and Assignee
                    Row(
                      children: [
                        Expanded(
                          child: _buildUserCard(
                            'Created by',
                            _creator?.displayName ?? 'Loading...',
                            _creator?.email ?? '',
                            Remix.user_add_line,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildUserCard(
                            'Assigned to',
                            _assignee?.displayName ?? 'Loading...',
                            _assignee?.email ?? '',
                            Remix.user_line,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.neutralColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
      String title, String name, String email, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.neutralColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkNeutralColor,
            ),
          ),
          Text(
            email,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.neutralColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
