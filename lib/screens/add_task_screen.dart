import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../providers/branches_provider.dart';
import '../models/task_model.dart';
import '../models/church_branch_model.dart';
import '../models/user_model.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_dropdown.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';

import '../utils/notification_helper.dart';
import '../services/notification_service.dart';
import '../models/initial_notification_config.dart';
import '../widgets/custom_date_time_picker.dart';
import '../widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Focus nodes for keyboard navigation
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  UserModel? _selectedAssignee;
  ChurchBranch? _selectedBranch;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDeadline;

  // Notification timing
  NotificationTiming? _initialNotificationTiming = NotificationTiming.immediate;
  DateTime? _scheduledNotificationDateTime;

  // Track form completion
  bool _isTitleValid = false;
  bool _isDescriptionValid = false;
  bool _isAssigneeValid = false;
  bool _isDeadlineValid = false;
  bool _isBranchValid = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_validateTitle);
    _descriptionController.addListener(_validateDescription);
  }

  void _validateTitle() {
    if (mounted) {
      setState(() {
        _isTitleValid = _titleController.text.trim().isNotEmpty;
      });
    }
  }

  void _validateDescription() {
    if (mounted) {
      setState(() {
        _isDescriptionValid = _descriptionController.text.trim().isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_validateTitle);
    _descriptionController.removeListener(_validateDescription);
    _titleController.dispose();
    _descriptionController.dispose();

    // Dispose focus nodes
    _titleFocus.dispose();
    _descriptionFocus.dispose();

    super.dispose();
  }

  Future<void> _submitForm() async {
    // Dismiss keyboard before validation
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Validate scheduled notification if selected
    if (_initialNotificationTiming == NotificationTiming.scheduled &&
        _scheduledNotificationDateTime == null) {
      CustomToast.show(context,
          message:
              'Please select a date and time for the scheduled notification',
          type: ToastType.error);
      return;
    }

    // Prevent duplicate submissions
    if (_isCreating) return;

    setState(() => _isCreating = true);

    final currentContext = context;
    try {
      final currentUser = currentContext.read<AuthService>().currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final supabaseProvider = currentContext.read<SupabaseProvider>();
      final notificationService = currentContext.read<NotificationService>();

      // Create notification helper
      final notificationHelper = NotificationHelper(
        supabaseProvider: supabaseProvider,
        notificationService: notificationService,
      );

      // Create notification config based on user selection
      InitialNotificationConfig? notificationConfig;
      if (_initialNotificationTiming != NotificationTiming.none) {
        if (_initialNotificationTiming == NotificationTiming.immediate) {
          notificationConfig = InitialNotificationConfig.immediate();
        } else if (_initialNotificationTiming == NotificationTiming.scheduled) {
          notificationConfig = InitialNotificationConfig.scheduled(
              _scheduledNotificationDateTime!);
        }
      }

      // Use the notification-enabled method instead of basic createTask
      await supabaseProvider.createTaskWithNotification(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority.name,
        assignedTo: _selectedAssignee!.id,
        branchId: _selectedBranch!.id,
        dueDate: _selectedDeadline,
        notificationHelper: notificationHelper,
        notificationConfig: notificationConfig,
      );

      if (currentContext.mounted) {
        // Show appropriate success message based on notification timing
        String message;
        if (_initialNotificationTiming == NotificationTiming.immediate) {
          message = 'Task created and assignee notified';
        } else if (_initialNotificationTiming == NotificationTiming.scheduled) {
          message = 'Task created, notification scheduled';
        } else {
          message = 'Task created successfully';
        }

        CustomToast.show(currentContext,
            message: message, type: ToastType.success);
        Navigator.pop(currentContext);
      }
    } catch (e) {
      if (currentContext.mounted) {
        setState(() => _isCreating = false);
        CustomToast.show(currentContext,
            message: 'Error creating task: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomBackButton(
                            onPressed: () => Navigator.pop(context),
                            color: AppTheme.textPrimary(context),
                            showBackground: false,
                            showShadow: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Remix.task_line,
                            color: AppTheme.primary(context),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Task',
                                style: AppTheme.titleStyle(context).copyWith(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in the details below',
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Modern Progress Indicators
                    _buildModernProgressBar(),
                  ],
                ),
              ),
            ),

            // Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Task Information Card
                        _buildModernSection(
                          icon: Remix.edit_box_line,
                          title: 'Task Information',
                          accentColor: AppTheme.primary(context),
                          child: Column(
                            children: [
                              CustomInput(
                                label: 'Task Title',
                                controller: _titleController,
                                hint: 'Enter a clear, descriptive title',
                                prefixIcon: const Icon(Remix.file_list_2_line),
                                focusNode: _titleFocus,
                                nextFocusNode: _descriptionFocus,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              CustomInput(
                                label: 'Description',
                                controller: _descriptionController,
                                hint: 'Provide detailed task description',
                                prefixIcon: const Icon(Remix.file_list_3_line),
                                focusNode: _descriptionFocus,
                                maxLines: 4,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a description';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Assignment Card
                        _buildModernSection(
                          icon: Remix.group_line,
                          title: 'Assignment',
                          accentColor: AppTheme.secondary(context),
                          child: Column(
                            children: [
                              // Branch Selection First
                              Consumer<BranchesProvider>(
                                builder: (context, branchesProvider, child) {
                                  final branches = branchesProvider.branches;

                                  return CustomDropdown<ChurchBranch>(
                                    label: 'Branch',
                                    value: _selectedBranch,
                                    prefixIcon: Remix.community_line,
                                    items: branches
                                        .map<DropdownMenuItem<ChurchBranch>>(
                                            (ChurchBranch branch) {
                                      return DropdownMenuItem<ChurchBranch>(
                                        value: branch,
                                        child: Text(branch.name),
                                      );
                                    }).toList(),
                                    onChanged: (branch) {
                                      if (branch != null) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _selectedBranch = branch;
                                          _isBranchValid = true;
                                          // Reset assignee when branch changes
                                          _selectedAssignee = null;
                                          _isAssigneeValid = false;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a branch';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              // User Selection (filtered by branch)
                              StreamBuilder<List<UserModel>>(
                                stream: Provider.of<SupabaseProvider>(context,
                                        listen: false)
                                    .getAllUsers(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final allUsers = snapshot.data!;

                                  // Filter users based on selected branch
                                  final List<UserModel> filteredUsers;
                                  if (_selectedBranch == null) {
                                    // No branch selected, show empty or all users
                                    filteredUsers = [];
                                  } else if (_selectedBranch!.name
                                          .toLowerCase() ==
                                      'global') {
                                    // Global branch - show all users
                                    filteredUsers = allUsers;
                                  } else {
                                    // Specific branch - show only users in that branch
                                    filteredUsers = allUsers
                                        .where((user) =>
                                            user.branchId ==
                                            _selectedBranch!.id)
                                        .toList();
                                  }

                                  return CustomDropdown<UserModel>(
                                    label: 'Assign To',
                                    value: _selectedAssignee,
                                    prefixIcon: Remix.user_line,
                                    enabled: _selectedBranch != null &&
                                        filteredUsers.isNotEmpty,
                                    items: filteredUsers.isEmpty
                                        ? [
                                            const DropdownMenuItem<UserModel>(
                                              value: null,
                                              child: Text('No users available'),
                                            ),
                                          ]
                                        : filteredUsers
                                            .map<DropdownMenuItem<UserModel>>(
                                                (UserModel user) {
                                            return DropdownMenuItem<UserModel>(
                                              value: user,
                                              child: Text(user.displayName),
                                            );
                                          }).toList(),
                                    onChanged: (user) {
                                      if (user != null) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _selectedAssignee = user;
                                          _isAssigneeValid = true;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select an assignee';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Scheduling Card
                        _buildModernSection(
                          icon: Icons.schedule,
                          title: 'Scheduling',
                          accentColor: AppTheme.accent(context),
                          child: Column(
                            children: [
                              CustomDateTimePicker(
                                key: ValueKey(_selectedDeadline),
                                label: 'Deadline',
                                value: _selectedDeadline,
                                hintText: 'Select deadline date & time',
                                prefixIcon: Remix.calendar_line,
                                onChanged: (dateTime) {
                                  setState(() {
                                    _selectedDeadline = dateTime;
                                    _isDeadlineValid = dateTime != null;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a deadline';
                                  }
                                  if (value.isBefore(DateTime.now())) {
                                    return 'Deadline cannot be in the past';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              CustomDropdown<TaskPriority>(
                                value: _selectedPriority,
                                label: 'Priority Level',
                                hint: 'Select priority',
                                prefixIcon: Remix.flag_line,
                                items: const [
                                  DropdownMenuItem(
                                      value: TaskPriority.urgent,
                                      child: Text('🔴 Urgent')),
                                  DropdownMenuItem(
                                      value: TaskPriority.high,
                                      child: Text('🟠 High')),
                                  DropdownMenuItem(
                                      value: TaskPriority.medium,
                                      child: Text('🟡 Medium')),
                                  DropdownMenuItem(
                                      value: TaskPriority.low,
                                      child: Text('🟢 Low')),
                                ],
                                onChanged: (value) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedPriority = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Notification Timing Card
                        _buildModernSection(
                          icon: Remix.notification_3_line,
                          title: 'Notification Settings',
                          accentColor: AppTheme.secondary(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose when to notify the assignee about this task:',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Immediate Notification Option
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _initialNotificationTiming ==
                                              NotificationTiming.immediate
                                          ? AppTheme.primary(context)
                                          : AppTheme.dividerColor(context),
                                      width: 2,
                                    ),
                                  ),
                                  child: _initialNotificationTiming ==
                                          NotificationTiming.immediate
                                      ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.primary(context),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  'Notify immediately',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  'Send notification as soon as the task is created',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _initialNotificationTiming =
                                        NotificationTiming.immediate;
                                    _scheduledNotificationDateTime = null;
                                  });
                                },
                              ),

                              // Scheduled Notification Option
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _initialNotificationTiming ==
                                              NotificationTiming.scheduled
                                          ? AppTheme.primary(context)
                                          : AppTheme.dividerColor(context),
                                      width: 2,
                                    ),
                                  ),
                                  child: _initialNotificationTiming ==
                                          NotificationTiming.scheduled
                                      ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.primary(context),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  'Schedule notification',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  'Send notification at a specific date and time',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _initialNotificationTiming =
                                        NotificationTiming.scheduled;
                                  });
                                },
                              ),

                              // No Notification Option
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _initialNotificationTiming ==
                                              NotificationTiming.none
                                          ? AppTheme.primary(context)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: _initialNotificationTiming ==
                                          NotificationTiming.none
                                      ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.primary(context),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  'No initial notification',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  'Don\'t send any notification when task is created',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _initialNotificationTiming =
                                        NotificationTiming.none;
                                    _scheduledNotificationDateTime = null;
                                  });
                                },
                              ),

                              // Scheduled Notification Date/Time Picker
                              if (_initialNotificationTiming ==
                                  NotificationTiming.scheduled) ...[
                                const SizedBox(height: 16),
                                const SizedBox(height: 16),
                                CustomDateTimePicker(
                                  key: ValueKey(_scheduledNotificationDateTime),
                                  label: 'Notification Date & Time',
                                  hintText: 'Select when to send notification',
                                  value: _scheduledNotificationDateTime,
                                  onChanged: (dateTime) {
                                    setState(() {
                                      _scheduledNotificationDateTime = dateTime;
                                    });
                                  },
                                  mode: DateTimePickerMode.dateAndTime,
                                  validator: (value) {
                                    if (_initialNotificationTiming ==
                                            NotificationTiming.scheduled &&
                                        value == null) {
                                      return 'Please select a notification time';
                                    }
                                    if (value != null &&
                                        value.isBefore(DateTime.now())) {
                                      return 'Notification time must be in the future';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        CustomButton(
                          onPressed: _isCreating ? null : _submitForm,
                          isLoading: _isCreating,
                          height: 56,
                          child: Text(
                            _isCreating ? 'Creating Task...' : 'Create Task',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProgressBar() {
    const totalSteps = 5;
    final completedSteps = [
      _isTitleValid,
      _isDescriptionValid,
      _isAssigneeValid,
      _isDeadlineValid,
      _isBranchValid,
    ].where((valid) => valid).length;

    final progress = completedSteps / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$completedSteps of $totalSteps completed',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppTheme.primary(context).withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primary(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with colored accent
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}
