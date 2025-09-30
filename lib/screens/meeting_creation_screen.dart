import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/supabase_provider.dart';
import '../providers/branches_provider.dart';
import '../models/meeting_model.dart';
import '../models/church_branch_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_dropdown.dart';

class MeetingCreationScreen extends StatefulWidget {
  const MeetingCreationScreen({super.key});

  @override
  State<MeetingCreationScreen> createState() => _MeetingCreationScreenState();
}

class _MeetingCreationScreenState extends State<MeetingCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _expectedAttendanceController = TextEditingController();

  DateTime? _selectedDateTime;
  DateTime? _selectedEndTime;
  ChurchBranch? _selectedBranch;
  bool _isVirtual = false;

  // Add these missing state variables for the loading overlay
  bool _isCreating = false;
  bool _showSuccess = false;

  // Notification scheduling
  final List<int> _reminderMinutes = [];
  final List<String> _reminderOptions = [
    '15 minutes before',
    '1 hour before',
    '1 day before',
    '1 week before'
  ];
  final Map<String, int> _reminderValues = {
    '15 minutes before': 15,
    '1 hour before': 60,
    '1 day before': 1440,
    '1 week before': 10080
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CustomBackButton(
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Create Meeting',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkNeutralColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meeting Title
                          CustomInput(
                            controller: _titleController,
                            label: 'Meeting Title',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a meeting title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description
                          CustomInput(
                            controller: _descriptionController,
                            label: 'Description',
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Branch Selection
                          Builder(
                            builder: (context) {
                              final branchesProvider =
                                  Provider.of<BranchesProvider>(context);
                              final branches = branchesProvider.branches;

                              // Reset selected branch if it's not in the current list
                              if (_selectedBranch != null &&
                                  !branches.any((branch) =>
                                      branch.id == _selectedBranch!.id)) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    _selectedBranch = null;
                                  });
                                });
                              }

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
                          const SizedBox(height: 16),

                          // Date and Time Selection
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _selectDateTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppTheme.neutralColor),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Meeting Start Time',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppTheme.neutralColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedDateTime != null
                                              ? _formatDateTime(
                                                  _selectedDateTime!)
                                              : 'Select start date and time',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: _selectedDateTime != null
                                                ? AppTheme.darkNeutralColor
                                                : AppTheme.neutralColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // End Time Selection
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _selectEndTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppTheme.neutralColor),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Meeting End Time',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppTheme.neutralColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedEndTime != null
                                              ? _formatDateTime(
                                                  _selectedEndTime!)
                                              : 'Select end date and time',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: _selectedEndTime != null
                                                ? AppTheme.darkNeutralColor
                                                : AppTheme.neutralColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Virtual Meeting Toggle
                          Row(
                            children: [
                              Switch(
                                value: _isVirtual,
                                onChanged: (value) {
                                  setState(() {
                                    _isVirtual = value;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Virtual Meeting',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppTheme.darkNeutralColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Location or Meeting Link
                          if (_isVirtual)
                            CustomInput(
                              controller: _meetingLinkController,
                              label: 'Meeting Link',
                              validator: (value) {
                                if (_isVirtual &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter a meeting link';
                                }
                                return null;
                              },
                            )
                          else
                            CustomInput(
                              controller: _locationController,
                              label: 'Location',
                              validator: (value) {
                                if (!_isVirtual &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter a location';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 16),

                          // Expected Attendance
                          CustomInput(
                            controller: _expectedAttendanceController,
                            label: 'Expected Attendance',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),

                          // Notification Reminders Section
                          Text(
                            'Notification Reminders',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkNeutralColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select when to remind branch members about this meeting:',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.neutralColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Reminder Options
                          ..._reminderOptions.map((option) {
                            final minutes = _reminderValues[option]!;
                            final isSelected =
                                _reminderMinutes.contains(minutes);

                            return CheckboxListTile(
                              title: Text(
                                option,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppTheme.darkNeutralColor,
                                ),
                              ),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _reminderMinutes.add(minutes);
                                  } else {
                                    _reminderMinutes.remove(minutes);
                                  }
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            );
                          }),

                          const SizedBox(height: 32),

                          // Create Meeting Button
                          CustomButton(
                            onPressed: _isCreating ? null : _createMeeting,
                            isLoading: false,
                            child: Text('Create Meeting'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isCreating)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showSuccess
                            ? Icon(
                                Icons.check_circle,
                                key: ValueKey('success'),
                                color: Colors.green,
                                size: 64,
                              )
                            : CircularProgressIndicator(
                                key: ValueKey('loading'),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showSuccess
                            ? 'Meeting Created!'
                            : 'Creating Meeting...',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _showSuccess
                              ? Colors.green
                              : AppTheme.darkNeutralColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    // Ensure start time is selected first
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start time first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime!,
      firstDate: _selectedDateTime!,
      lastDate: _selectedDateTime!.add(const Duration(days: 7)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime!.add(const Duration(hours: 1)),
        ),
      );

      if (time != null) {
        final endDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        // Validate that end time is after start time
        if (endDateTime.isBefore(_selectedDateTime!) ||
            endDateTime.isAtSameMomentAs(_selectedDateTime!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _selectedEndTime = endDateTime;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDateTime == null ||
        _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill in all required fields including start and end times'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final supabaseProvider =
        Provider.of<SupabaseProvider>(context, listen: false);

    // Check if user is authenticated
    if (supabaseProvider.currentUser?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a meeting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading overlay
    setState(() {
      _isCreating = true;
      _showSuccess = false;
    });

    final meeting = MeetingModel(
      id: '', // Will be generated by database
      title: _titleController.text,
      description: _descriptionController.text,
      dateTime: _selectedDateTime!,
      type: _selectedBranch != null ? 'local' : 'global',
      endTime: _selectedEndTime!,
      branchId: _selectedBranch?.id,
      organizerId: supabaseProvider.currentUser!.id,
      organizerName:
          supabaseProvider.currentUser?.userMetadata?['full_name'] ?? 'Unknown',
      location: _isVirtual ? 'Virtual Meeting' : _locationController.text,
      isVirtual: _isVirtual,
      meetingLink: _isVirtual ? _meetingLinkController.text : null,
      expectedAttendance: int.tryParse(_expectedAttendanceController.text) ?? 0,
    );

    final success = await supabaseProvider.createMeetingWithNotifications(
      meeting,
      _reminderMinutes,
    );

    if (success) {
      // Show success checkmark
      setState(() {
        _showSuccess = true;
      });

      // Wait for animation, then navigate back to home
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        // Navigate back to home screen by removing all routes and pushing home
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } else {
      // Hide loading overlay and show error
      setState(() {
        _isCreating = false;
        _showSuccess = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(supabaseProvider.error ??
                'Failed to create meeting. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _expectedAttendanceController.dispose();
    super.dispose();
  }
}