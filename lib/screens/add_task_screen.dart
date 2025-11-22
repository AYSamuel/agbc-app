import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/supabase_provider.dart';
import '../providers/branches_provider.dart';
import '../models/task_model.dart';
import '../models/church_branch_model.dart';
import '../models/user_model.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_dropdown.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../utils/focus_helper.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deadlineController = TextEditingController();

  // Focus nodes for keyboard navigation
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _deadlineFocus = FocusNode();

  UserModel? _selectedAssignee;
  ChurchBranch? _selectedBranch;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDeadline;

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
    _deadlineController.dispose();

    // Dispose focus nodes
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _deadlineFocus.dispose();

    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller,
      FocusNode focusNode, bool isDeadline) async {
    if (!mounted) return;

    // FIXED: Dismiss keyboard before showing date picker
    FocusHelper.unfocus(context);

    HapticFeedback.selectionClick();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkNeutralColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        initialEntryMode: TimePickerEntryMode.dialOnly,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryColor,
                onPrimary: Colors.white,
                onSurface: AppTheme.darkNeutralColor,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (!mounted) return;

      if (time != null) {
        final DateTime dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isDeadline) {
            _selectedDeadline = dateTime;
            _isDeadlineValid = true;
          }
          controller.text = _formatDateTime(dateTime);
        });

        // FIXED: Ensure focus is cleared after setting the value
        FocusHelper.unfocus(context);
      }
    }

    // FIXED: Final cleanup - ensure keyboard stays dismissed
    if (mounted) {
      FocusHelper.unfocus(context);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitForm() async {
    // Dismiss keyboard before validation
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Prevent duplicate submissions
    if (_isCreating) return;

    setState(() => _isCreating = true);

    final currentContext = context;
    try {
      final currentUser = currentContext.read<AuthService>().currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final task = TaskModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDeadline!,
        assignedTo: _selectedAssignee!.id,
        createdBy: currentUser.id,
        branchId: _selectedBranch?.id,
        priority: _selectedPriority,
      );

      await currentContext.read<SupabaseProvider>().createTask(task);

      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(currentContext);
      }
    } catch (e) {
      if (currentContext.mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error creating task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        CustomBackButton(
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Task',
                                style: AppTheme.titleStyle.copyWith(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in the details below',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
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
                          icon: Icons.edit_document,
                          title: 'Task Information',
                          accentColor: AppTheme.primaryColor,
                          child: Column(
                            children: [
                              CustomInput(
                                label: 'Task Title',
                                controller: _titleController,
                                hint: 'Enter a clear, descriptive title',
                                prefixIcon: const Icon(Icons.title),
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
                                prefixIcon: const Icon(Icons.description),
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
                          icon: Icons.people,
                          title: 'Assignment',
                          accentColor: AppTheme.secondaryColor,
                          child: Column(
                            children: [
                              // Branch Selection First
                              Consumer<BranchesProvider>(
                                builder: (context, branchesProvider, child) {
                                  final branches = branchesProvider.branches;

                                  return CustomDropdown<ChurchBranch>(
                                    label: 'Branch',
                                    value: _selectedBranch,
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
                                  } else if (_selectedBranch!.name.toLowerCase() == 'global') {
                                    // Global branch - show all users
                                    filteredUsers = allUsers;
                                  } else {
                                    // Specific branch - show only users in that branch
                                    filteredUsers = allUsers
                                        .where((user) => user.branchId == _selectedBranch!.id)
                                        .toList();
                                  }

                                  return CustomDropdown<UserModel>(
                                    label: 'Assign To',
                                    value: _selectedAssignee,
                                    enabled: _selectedBranch != null && filteredUsers.isNotEmpty,
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
                          accentColor: AppTheme.accentColor,
                          child: Column(
                            children: [
                              CustomInput(
                                label: 'Deadline',
                                controller: _deadlineController,
                                hint: 'Select deadline date & time',
                                prefixIcon: const Icon(Icons.calendar_today),
                                focusNode: _deadlineFocus,
                                readOnly: true,
                                onTap: () => _selectDate(
                                    _deadlineController, _deadlineFocus, true),
                                validator: (value) {
                                  if (_selectedDeadline == null) {
                                    return 'Please select a deadline';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              CustomDropdown<TaskPriority>(
                                value: _selectedPriority,
                                label: 'Priority Level',
                                hint: 'Select priority',
                                prefixIcon: Icons.flag,
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
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$completedSteps of $totalSteps completed',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
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
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.secondaryColor,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNeutralColor,
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
