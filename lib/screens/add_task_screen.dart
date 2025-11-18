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
      }
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Row(
                    children: [
                      CustomBackButton(
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Create New Task',
                        style: AppTheme.titleStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Form Progress Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProgressIndicator('Title', _isTitleValid),
                      _buildProgressIndicator('Details', _isDescriptionValid),
                      _buildProgressIndicator('Assignee', _isAssigneeValid),
                      _buildProgressIndicator('Deadline', _isDeadlineValid),
                      _buildProgressIndicator('Branch', _isBranchValid),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Basic Information Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        const Text(
                          'Task Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomInput(
                          label: 'Title',
                          controller: _titleController,
                          hint: 'Enter task title',
                          prefixIcon:
                              const Icon(Icons.title, color: Colors.grey),
                          focusNode: _titleFocus,
                          nextFocusNode: _descriptionFocus,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          label: 'Description',
                          controller: _descriptionController,
                          hint: 'Enter task description',
                          prefixIcon:
                              const Icon(Icons.description, color: Colors.grey),
                          focusNode: _descriptionFocus,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: StreamBuilder<List<UserModel>>(
                                stream: Provider.of<SupabaseProvider>(context,
                                        listen: false)
                                    .getAllUsers(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final users = snapshot.data!;

                                  return CustomDropdown<UserModel>(
                                    label: 'Select Assignee',
                                    value: _selectedAssignee,
                                    items: users
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Consumer<BranchesProvider>(
                                builder: (context, branchesProvider, child) {
                                  final branches = branchesProvider.branches;

                                  return CustomDropdown<ChurchBranch>(
                                    label: 'Select Branch',
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
                                        setState(() {
                                          _selectedBranch = branch;
                                          _isBranchValid = true;
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          label: 'Deadline',
                          controller: _deadlineController,
                          hint: 'Select deadline',
                          prefixIcon: const Icon(Icons.calendar_today,
                              color: Colors.grey),
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown<TaskPriority>(
                                value: _selectedPriority,
                                label: 'Priority',
                                hint: 'Select priority',
                                prefixIcon: Icons.priority_high,
                                items: const [
                                  DropdownMenuItem(
                                      value: TaskPriority.urgent,
                                      child: Text('Urgent')),
                                  DropdownMenuItem(
                                      value: TaskPriority.high,
                                      child: Text('High')),
                                  DropdownMenuItem(
                                      value: TaskPriority.medium,
                                      child: Text('Medium')),
                                  DropdownMenuItem(
                                      value: TaskPriority.low,
                                      child: Text('Low')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriority = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  CustomButton(
                    onPressed: _isCreating ? null : _submitForm,
                    isLoading: _isCreating,
                    child: const Text('Create Task'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String label, bool isComplete) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete ? Colors.green : Colors.grey[300],
          ),
          child: isComplete
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isComplete ? Colors.green : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
