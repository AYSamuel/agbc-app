import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'task_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_back_button.dart';

class TasksScreen extends StatefulWidget {
  final bool showBackButton;
  const TasksScreen({super.key, this.showBackButton = false});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  String _selectedFilter = 'all';
  String _selectedSort = 'due_date';
  final Map<String, UserModel?> _userCache = {};

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with conditional Back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (widget.showBackButton) ...[
                    CustomBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Text(
                    'My Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNeutralColor,
                    ),
                  ),
                ],
              ),
            ),
            _buildFilterAndSortBar(),
            Expanded(
              child: StreamBuilder<List<TaskModel>>(
                stream: _supabaseService.getTasksForUser(user?.id ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final tasks = _filterAndSortTasks(snapshot.data!);
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.warningColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Remix.task_line,
                              color: AppTheme.warningColor,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Tasks Found',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkNeutralColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You don\'t have any tasks assigned to you',
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
                      return _buildTaskCard(tasks[index]);
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

  Widget _buildFilterAndSortBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomDropdown<String>(
              value: _selectedFilter,
              label: 'Filter',
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Tasks')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                    value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomDropdown<String>(
              value: _selectedSort,
              label: 'Sort by',
              items: const [
                DropdownMenuItem(value: 'due_date', child: Text('Due Date')),
                DropdownMenuItem(value: 'priority', child: Text('Priority')),
                DropdownMenuItem(value: 'status', child: Text('Status')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSort = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 8,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      child: InkWell(
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(task: task),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkNeutralColor,
                    ),
                  ),
                ),
                _buildStatusChip(task.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.neutralColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  Remix.calendar_line,
                  _formatDate(task.dueDate),
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Remix.flag_line,
                  task.priority.toUpperCase(),
                  _getPriorityColor(task.priority),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<UserModel?>(
              future: _getUserDetails(task.createdBy),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Row(
                    children: [
                      Icon(
                        Remix.user_line,
                        size: 16,
                        color: AppTheme.neutralColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Created by: ${snapshot.data?.displayName ?? 'Unknown'}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.neutralColor,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<TaskModel> _filterAndSortTasks(List<TaskModel> tasks) {
    // Apply filter
    var filteredTasks = tasks;
    if (_selectedFilter != 'all') {
      filteredTasks =
          tasks.where((task) => task.status == _selectedFilter).toList();
    }

    // Apply sort
    switch (_selectedSort) {
      case 'due_date':
        filteredTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'priority':
        filteredTasks.sort((a, b) => _getPriorityWeight(b.priority)
            .compareTo(_getPriorityWeight(a.priority)));
        break;
      case 'status':
        filteredTasks.sort((a, b) => a.status.compareTo(b.status));
        break;
    }

    return filteredTasks;
  }

  int _getPriorityWeight(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<UserModel?> _getUserDetails(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final user = await _supabaseService.getUser(userId).first;
      _userCache[userId] = user;
      return user;
    } catch (e) {
      return null;
    }
  }
}
