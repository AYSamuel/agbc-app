import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/supabase_provider.dart';
import '../models/task_model.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_back_button.dart';
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
  String _selectedPriority = 'medium';
  String _selectedCategory = 'general';
  DateTime? _selectedDeadline;
  DateTime? _selectedReminder;

  @override
  void dispose() {
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      // Check if the widget is still mounted before showing the time picker
      if (!mounted) return;

      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      // Check again after the async operation
      if (!mounted) return;

      if (time != null) {
        final DateTime selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isDeadline) {
            _selectedDeadline = selectedDateTime;
            controller.text =
                '${picked.day}/${picked.month}/${picked.year} ${time.format(context)}';
          } else {
            _selectedReminder = selectedDateTime;
            controller.text =
                '${picked.day}/${picked.month}/${picked.year} ${time.format(context)}';
          }
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAssigneeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an assignee')),
        );
        return;
      }

      if (_selectedDeadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a deadline')),
        );
        return;
      }

      try {
        final currentUser = context.read<AuthService>().currentUser;
        if (currentUser == null) return;

        final task = TaskModel(
          id: const Uuid().v4(),
          title: _titleController.text,
          description: _descriptionController.text,
          deadline: _selectedDeadline!,
          assignedTo: _selectedAssigneeId!,
          createdBy: currentUser.id,
          reminder: _selectedReminder,
          priority: _selectedPriority,
          category: _selectedCategory,
        );

        await context.read<SupabaseProvider>().createTask(task);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating task: $e')),
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
                            if (value == null || value.isEmpty) {
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
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          label: 'Assignee',
                          controller: TextEditingController(
                              text: _selectedAssigneeId ?? ''),
                          hint: 'Select assignee',
                          prefixIcon:
                              const Icon(Icons.person, color: Colors.grey),
                          readOnly: true,
                          onTap: () async {
                            if (!mounted) return;
                            final currentContext = context;
                            final SupabaseProvider provider =
                                Provider.of<SupabaseProvider>(currentContext,
                                    listen: false);

                            try {
                              final users = await provider.getAllUsers().first;
                              if (!mounted) return;

                              if (!currentContext.mounted) return;
                              await showDialog(
                                context: currentContext,
                                builder: (dialogContext) => AlertDialog(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Select Assignee'),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                      ),
                                    ],
                                  ),
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
                                          onTap: () {
                                            setState(() {
                                              _selectedAssigneeId = user.id;
                                            });
                                            Navigator.pop(dialogContext);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Failed to load users: ${e.toString()}')),
                              );
                            }
                          },
                          validator: (value) {
                            if (_selectedAssigneeId == null) {
                              return 'Please select an assignee';
                            }
                            return null;
                          },
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
                        CustomInput(
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedPriority,
                                decoration: const InputDecoration(
                                  labelText: 'Priority',
                                  prefixIcon: Icon(Icons.priority_high,
                                      color: Colors.grey),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                ),
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'low', child: Text('Low')),
                                  DropdownMenuItem(
                                      value: 'medium', child: Text('Medium')),
                                  DropdownMenuItem(
                                      value: 'high', child: Text('High')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriority = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon:
                                      Icon(Icons.category, color: Colors.grey),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                ),
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'general', child: Text('General')),
                                  DropdownMenuItem(
                                      value: 'ministry',
                                      child: Text('Ministry')),
                                  DropdownMenuItem(
                                      value: 'event', child: Text('Event')),
                                  DropdownMenuItem(
                                      value: 'maintenance',
                                      child: Text('Maintenance')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value!;
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
}
