import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';
import '../models/task_model.dart';
import '../services/supabase_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'task_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../widgets/task_card.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_drawer.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Container(
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
                  if (widget.showBackButton) ...[
                    CustomBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Text(
                    'Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Remix.filter_3_line),
                    color: const Color(0xFF4B5563),
                    onPressed: () {
                      // Show filter options
                    },
                  ),
                ],
              ),
            ),

            // Filter Tabs
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterTab(
                        'All Tasks',
                        _selectedFilter == 'all',
                        Remix.list_check,
                      ),
                      _buildFilterTab(
                        'In Progress',
                        _selectedFilter == 'in_progress',
                        Remix.time_line,
                      ),
                      _buildFilterTab(
                        'Completed',
                        _selectedFilter == 'completed',
                        Remix.checkbox_circle_line,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sort Options
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFF3F4F6),
                    width: 1,
                  ),
                ),
              ),
              child: StreamBuilder<List<TaskModel>>(
                stream: _supabaseService.getTasksForUser(user?.id ?? ''),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final tasks = snapshot.data!;
                  final filteredTasks = _filterAndSortTasks(tasks);
                  final taskCount = filteredTasks.length;
                  final taskText = taskCount == 1 ? 'task' : 'tasks';

                  return Row(
                    children: [
                      Text(
                        '$taskCount $taskText',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Sort by:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _showSortOptions(context);
                        },
                        child: Row(
                          children: [
                            Text(
                              _getSortLabel(_selectedSort),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF5B7EBF),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Remix.arrow_down_s_line,
                              size: 16,
                              color: Color(0xFF5B7EBF),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Task List
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
                      return TaskCard(
                        task: tasks[index],
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskDetailsScreen(task: tasks[index]),
                            ),
                          );
                        },
                        onStatusChanged: (value) {
                          // Handle task status change
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildFilterTab(String label, bool isSelected, IconData icon) {
    String filterValue = label.toLowerCase().replaceAll(' ', '_');
    if (label == 'All Tasks') {
      filterValue = 'all';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedFilter = filterValue;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF5B7EBF) : Colors.white,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF4B5563),
          elevation: isSelected ? 2 : 0,
          shadowColor: isSelected
              ? const Color(0xFF5B7EBF).withValues(alpha: 0.3)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF5B7EBF)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomDrawer(
        title: 'Sort by',
        items: [
          DrawerItem(
            icon: Remix.calendar_line,
            label: 'Due Date',
            showChevron: false,
            onTap: () {
              setState(() {
                _selectedSort = 'due_date';
              });
              Navigator.pop(context);
            },
          ),
          DrawerItem(
            icon: Remix.flag_line,
            label: 'Priority',
            showChevron: false,
            onTap: () {
              setState(() {
                _selectedSort = 'priority';
              });
              Navigator.pop(context);
            },
          ),
          DrawerItem(
            icon: Remix.checkbox_circle_line,
            label: 'Status',
            showChevron: false,
            onTap: () {
              setState(() {
                _selectedSort = 'status';
              });
              Navigator.pop(context);
            },
          ),
          DrawerItem(
            icon: Remix.file_text_line,
            label: 'Title',
            showChevron: false,
            onTap: () {
              setState(() {
                _selectedSort = 'title';
              });
              Navigator.pop(context);
            },
          ),
          DrawerItem(
            icon: Remix.time_line,
            label: 'Created Date',
            showChevron: false,
            onTap: () {
              setState(() {
                _selectedSort = 'created_at';
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortValue) {
    switch (sortValue) {
      case 'due_date':
        return 'Due Date';
      case 'priority':
        return 'Priority';
      case 'status':
        return 'Status';
      case 'title':
        return 'Title';
      case 'created_at':
        return 'Created Date';
      default:
        return 'Due Date';
    }
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
      case 'title':
        filteredTasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'created_at':
        filteredTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
}
