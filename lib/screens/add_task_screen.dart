import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/supabase_provider.dart';
import '../models/task_model.dart';
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
  final _reminderController = TextEditingController();

  // Focus nodes for keyboard navigation
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _deadlineFocus = FocusNode();
  final _reminderFocus = FocusNode();

  String? _selectedAssigneeId;
  String? _selectedBranchId;
  String _selectedAssigneeName = '';
  String _selectedBranchName = '';
  String _selectedPriority = 'medium';
  DateTime? _selectedDeadline;

  // Track form completion
  bool _isTitleValid = false;
  bool _isDescriptionValid = false;
  bool _isAssigneeValid = false;
  bool _isDeadlineValid = false;
  bool _isBranchValid = false;

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
    _reminderController.dispose();

    // Dispose focus nodes
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _deadlineFocus.dispose();
    _reminderFocus.dispose();

    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller,
      FocusNode focusNode, bool isDeadline) async {
    if (!mounted) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted) return;

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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
    if (_formKey.currentState!.validate()) {
      // Update validation states
      _validateTitle();
      _validateDescription();

      final currentContext = context;
      try {
        final currentUser = currentContext.read<AuthService>().currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        final task = TaskModel(
          id: const Uuid().v4(),
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _selectedDeadline!,
          assignedTo: _selectedAssigneeId!,
          createdBy: currentUser.id,
          branchId: _selectedBranchId,
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
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Error creating task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                              setState(() => _isTitleValid = false);
                              return 'Please enter a title';
                            }
                            setState(() => _isTitleValid = true);
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
                              setState(() => _isDescriptionValid = false);
                              return 'Please enter a description';
                            }
                            setState(() => _isDescriptionValid = true);
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomInput(
                                label: 'Assignee',
                                controller: TextEditingController(
                                    text: _selectedAssigneeName),
                                hint: 'Select assignee',
                                prefixIcon: const Icon(Icons.person,
                                    color: Colors.grey),
                                readOnly: true,
                                onTap: () async {
                                  if (!context.mounted) return;
                                  final currentContext = context;
                                  final SupabaseProvider provider =
                                      Provider.of<SupabaseProvider>(
                                          currentContext,
                                          listen: false);

                                  try {
                                    final users =
                                        await provider.getAllUsers().first;
                                    if (!context.mounted) return;

                                    final selectedUser =
                                        await Navigator.of(context)
                                            .push<dynamic>(
                                      MaterialPageRoute(
                                        builder: (context) => AlertDialog(
                                          title: const Text('Select Assignee'),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: users.length,
                                              itemBuilder: (context, index) {
                                                final user = users[index];
                                                return ListTile(
                                                  title: Text(user.displayName),
                                                  subtitle: Text(user.email),
                                                  onTap: () => Navigator.pop(
                                                      context, user),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    );

                                    if (selectedUser != null) {
                                      setState(() {
                                        _selectedAssigneeId = selectedUser.id;
                                        _selectedAssigneeName =
                                            selectedUser.displayName;
                                        _isAssigneeValid = true;
                                      });
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error loading users: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                validator: (value) {
                                  if (_selectedAssigneeId == null) {
                                    return 'Please select an assignee';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomInput(
                                label: 'Branch',
                                controller: TextEditingController(
                                    text: _selectedBranchName),
                                hint: 'Select branch',
                                prefixIcon: const Icon(Icons.business,
                                    color: Colors.grey),
                                readOnly: true,
                                onTap: () async {
                                  if (!context.mounted) return;
                                  final currentContext = context;
                                  final SupabaseProvider provider =
                                      Provider.of<SupabaseProvider>(
                                          currentContext,
                                          listen: false);

                                  try {
                                    final branches =
                                        await provider.getAllBranches().first;
                                    if (!context.mounted) return;

                                    final selectedBranch = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Select Branch'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: branches.length,
                                            itemBuilder: (context, index) {
                                              final branch = branches[index];
                                              return ListTile(
                                                title: Text(branch.name),
                                                subtitle: Text(branch.address),
                                                onTap: () => Navigator.pop(
                                                    context, branch),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );

                                    if (selectedBranch != null) {
                                      setState(() {
                                        _selectedBranchId = selectedBranch.id;
                                        _selectedBranchName =
                                            selectedBranch.name;
                                        _isBranchValid = true;
                                      });
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Error loading branches: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                validator: (value) {
                                  if (_selectedBranchId == null) {
                                    return 'Please select a branch';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomInput(
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomInput(
                                label: 'Reminder (Optional)',
                                controller: _reminderController,
                                hint: 'Select reminder time',
                                prefixIcon: const Icon(Icons.notifications,
                                    color: Colors.grey),
                                focusNode: _reminderFocus,
                                readOnly: true,
                                onTap: () => _selectDate(
                                    _reminderController, _reminderFocus, false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown<String>(
                                value: _selectedPriority,
                                label: 'Priority',
                                hint: 'Select priority',
                                prefixIcon: Icons.priority_high,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'high', child: Text('High')),
                                  DropdownMenuItem(
                                      value: 'medium', child: Text('Medium')),
                                  DropdownMenuItem(
                                      value: 'low', child: Text('Low')),
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
                    onPressed: _submitForm,
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
