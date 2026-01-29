import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../providers/supabase_provider.dart';
import '../providers/branches_provider.dart';
import '../models/meeting_model.dart';
import '../models/church_branch_model.dart';
import '../models/recurrence.dart';
import '../models/initial_notification_config.dart';
import '../config/theme.dart';
import '../utils/timezone_helper.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_date_time_picker.dart';
import '../widgets/custom_toast.dart';
import '../widgets/multi_user_select_widget.dart';
import '../widgets/recurrence_options_widget.dart';
import '../widgets/initial_notification_settings.dart';

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

  DateTime? _selectedDateTime;
  DateTime? _selectedEndTime;
  ChurchBranch? _selectedBranch;
  bool _isVirtual = false;

  // Meeting scope: 'global', 'local', or 'invite'
  String _meetingScope = 'local';
  List<String> _selectedUserIds = [];

  // Add these missing state variables for the loading overlay
  bool _isCreating = false;

  // Initial notification configuration
  NotificationTiming? _initialNotificationTiming = NotificationTiming.immediate;
  DateTime? _scheduledNotificationDateTime;

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

  // Recurring meeting configuration
  bool _isRecurring = false;
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.weekly;
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
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
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomBackButton(
                            onPressed: () => Navigator.pop(context),
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
                            Remix.calendar_event_line,
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
                                'Create Meeting',
                                style: AppTheme.titleStyle(context).copyWith(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Schedule a new meeting event',
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
                  ),
                ),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Meeting Details Card
                          _buildModernSection(
                            icon: Remix.information_line,
                            title: 'Meeting Details',
                            accentColor: AppTheme.primary(context),
                            child: Column(
                              children: [
                                CustomInput(
                                  controller: _titleController,
                                  label: 'Meeting Title',
                                  hint: 'Enter meeting title',
                                  prefixIcon:
                                      const Icon(Remix.file_list_2_line),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a meeting title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                CustomInput(
                                  controller: _descriptionController,
                                  label: 'Description',
                                  hint: 'Provide meeting description',
                                  prefixIcon:
                                      const Icon(Remix.file_list_2_line),
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a description';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Meeting Scope Selector
                                _buildMeetingScopeSelector(),
                                const SizedBox(height: 20),
                                // Conditional: Branch dropdown or User picker
                                if (_meetingScope == 'local')
                                  Consumer<BranchesProvider>(
                                    builder:
                                        (context, branchesProvider, child) {
                                      final branches =
                                          branchesProvider.branches;

                                      return CustomDropdown<ChurchBranch>(
                                        label: 'Branch',
                                        value: _selectedBranch,
                                        items: branches.map<
                                                DropdownMenuItem<ChurchBranch>>(
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
                                          if (_meetingScope == 'local' &&
                                              value == null) {
                                            return 'Please select a branch';
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                  ),
                                if (_meetingScope == 'invite')
                                  MultiUserSelectWidget(
                                    label: 'Invite Users',
                                    selectedUserIds: _selectedUserIds,
                                    excludeUserId:
                                        Provider.of<SupabaseProvider>(context,
                                                listen: false)
                                            .currentUser
                                            ?.id,
                                    onSelectionChanged: (userIds) {
                                      setState(() {
                                        _selectedUserIds = userIds;
                                      });
                                    },
                                    validator: (userIds) {
                                      if (_meetingScope == 'invite' &&
                                          userIds.isEmpty) {
                                        return 'Please select at least one user';
                                      }
                                      return null;
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date & Time Card
                          _buildModernSection(
                            icon: Remix.calendar_event_line,
                            title: 'Schedule',
                            accentColor: AppTheme.secondary(context),
                            child: Column(
                              children: [
                                CustomDateTimePicker(
                                  label: 'Meeting Start Time',
                                  hintText: 'Select start date and time',
                                  value: _selectedDateTime,
                                  onChanged: (dateTime) {
                                    setState(() {
                                      _selectedDateTime = dateTime;
                                      // If end time is before start time, clear it or move it
                                      if (_selectedEndTime != null &&
                                          dateTime != null) {
                                        if (_selectedEndTime!
                                            .isBefore(dateTime)) {
                                          _selectedEndTime = dateTime
                                              .add(const Duration(hours: 1));
                                        }
                                      }
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a start time';
                                    }
                                    if (value.isBefore(DateTime.now())) {
                                      return 'Start time cannot be in the past';
                                    }
                                    return null;
                                  },
                                  prefixIcon: Remix.calendar_event_line,
                                  mode: DateTimePickerMode.dateAndTime,
                                ),
                                const SizedBox(height: 16),
                                CustomDateTimePicker(
                                  label: 'Meeting End Time',
                                  hintText: 'Select end date and time',
                                  value: _selectedEndTime,
                                  onChanged: (dateTime) {
                                    setState(() {
                                      _selectedEndTime = dateTime;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select an end time';
                                    }
                                    if (_selectedDateTime != null &&
                                        value.isBefore(_selectedDateTime!)) {
                                      return 'End time must be after start time';
                                    }
                                    return null;
                                  },
                                  prefixIcon: Remix.calendar_close_line,
                                  mode: DateTimePickerMode.dateAndTime,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Location Card
                          _buildModernSection(
                            icon: Remix.map_pin_line,
                            title: 'Location',
                            accentColor: AppTheme.secondary(context),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Switch(
                                      value: _isVirtual,
                                      onChanged: (value) {
                                        setState(() {
                                          _isVirtual = value;
                                        });
                                      },
                                      activeThumbColor:
                                          AppTheme.accent(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Virtual Meeting',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_isVirtual)
                                  CustomInput(
                                    controller: _meetingLinkController,
                                    label: 'Meeting Link',
                                    hint: 'Enter virtual meeting URL',
                                    prefixIcon: const Icon(Remix.link),
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
                                    label: 'Physical Location',
                                    hint: 'Enter meeting location',
                                    prefixIcon: const Icon(Remix.map_pin_line),
                                    validator: (value) {
                                      if (!_isVirtual &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please enter a location';
                                      }
                                      return null;
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          InitialNotificationSettings(
                            timing: _initialNotificationTiming,
                            scheduledTime: _scheduledNotificationDateTime,
                            onTimingChanged: (val) => setState(() {
                              _initialNotificationTiming = val;
                              if (val != NotificationTiming.scheduled) {
                                _scheduledNotificationDateTime = null;
                              }
                            }),
                            onScheduledTimeChanged: (val) => setState(() {
                              _scheduledNotificationDateTime = val;
                            }),
                            itemType: 'meeting',
                            targetAudience: 'branch members',
                          ),

                          const SizedBox(height: 24),

                          _buildModernSection(
                            icon: Remix.notification_line,
                            title: 'Notification Reminders',
                            accentColor: AppTheme.secondary(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select when to remind branch members about this meeting:',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._reminderOptions.map((option) {
                                  final minutes = _reminderValues[option]!;
                                  final isSelected =
                                      _reminderMinutes.contains(minutes);
                                  return CheckboxListTile(
                                    title: Text(
                                      option,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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
                                    activeColor: AppTheme.primary(context),
                                    checkColor: Colors.white,
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppTheme.primary(context)
                                          : Theme.of(context).dividerColor,
                                      width: 2,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          _buildModernSection(
                            icon: Remix.repeat_line,
                            title: 'Recurring Meeting',
                            accentColor: AppTheme.primary(context),
                            child: RecurrenceOptionsWidget(
                              isRecurring: _isRecurring,
                              onRecurringChanged: (val) =>
                                  setState(() => _isRecurring = val),
                              frequency: _recurrenceFrequency,
                              onFrequencyChanged: (val) =>
                                  setState(() => _recurrenceFrequency = val),
                              interval: _recurrenceInterval,
                              onIntervalChanged: (val) =>
                                  setState(() => _recurrenceInterval = val),
                              endDate: _recurrenceEndDate,
                              onEndDateChanged: (val) =>
                                  setState(() => _recurrenceEndDate = val),
                              itemType: 'Meeting',
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Create Meeting Button
                          CustomButton(
                            onPressed: _isCreating ? null : _createMeeting,
                            isLoading: _isCreating,
                            height: 56,
                            child: Text(
                              _isCreating
                                  ? 'Creating Meeting...'
                                  : 'Create Meeting',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createMeeting() async {
    // Dismiss keyboard before validation
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() ||
        _selectedDateTime == null ||
        _selectedEndTime == null) {
      CustomToast.show(context,
          message:
              'Please fill in all required fields including start and end times',
          type: ToastType.error);
      return;
    }

    // Validate scheduled notification if selected
    if (_initialNotificationTiming == NotificationTiming.scheduled &&
        _scheduledNotificationDateTime == null) {
      CustomToast.show(context,
          message:
              'Please select a date and time for the scheduled notification',
          type: ToastType.error);
      return;
    }

    // Validate meeting scope requirements
    if (_meetingScope == 'local' && _selectedBranch == null) {
      CustomToast.show(context,
          message: 'Please select a branch for the meeting',
          type: ToastType.error);
      return;
    }

    if (_meetingScope == 'invite' && _selectedUserIds.isEmpty) {
      CustomToast.show(context,
          message: 'Please select at least one user to invite',
          type: ToastType.error);
      return;
    }

    final supabaseProvider =
        Provider.of<SupabaseProvider>(context, listen: false);

    // Check if user is authenticated
    if (supabaseProvider.currentUser?.id == null) {
      CustomToast.show(context,
          message: 'You must be logged in to create a meeting',
          type: ToastType.error);
      return;
    }

    // Show loading state
    setState(() {
      _isCreating = true;
    });

    // Create initial notification config with reminder minutes
    final initialNotificationConfig = InitialNotificationConfig(
      enabled: _initialNotificationTiming != NotificationTiming.none,
      timing: _initialNotificationTiming ?? NotificationTiming.immediate,
      scheduledDateTime: _scheduledNotificationDateTime,
      reminderMinutes: _reminderMinutes.isNotEmpty ? _reminderMinutes : null,
    );

    // Get the creator's timezone and convert times to UTC
    final userTimezone = TimezoneHelper.getDeviceTimezone();
    final utcDateTime =
        TimezoneHelper.convertToUtc(_selectedDateTime!, userTimezone);
    final utcEndTime = _selectedEndTime != null
        ? TimezoneHelper.convertToUtc(_selectedEndTime!, userTimezone)
        : null;

    // Determine branch ID and meeting type
    String? branchId;
    String meetingType = _meetingScope;

    if (_meetingScope == 'local') {
      branchId = _selectedBranch?.id;
      // If the selected branch is the Global branch, treat it as a global meeting
      if (_selectedBranch?.isGlobalBranch == true) {
        meetingType = 'global';
      }
    }

    final meeting = MeetingModel(
      id: '', // Will be generated by database
      title: _titleController.text,
      description: _descriptionController.text,
      dateTime: utcDateTime,
      type: meetingType, // 'global', 'local', or 'invite'
      endTime: utcEndTime,
      branchId: branchId,
      invitedUserIds: _meetingScope == 'invite' ? _selectedUserIds : [],
      organizerId: supabaseProvider.currentUser!.id,
      organizerName:
          supabaseProvider.currentUser?.userMetadata?['full_name'] ?? 'Unknown',
      location: _isVirtual ? 'Virtual Meeting' : _locationController.text,
      isVirtual: _isVirtual,
      meetingLink: _isVirtual ? _meetingLinkController.text : null,
      creatorTimezone: userTimezone,
      initialNotificationConfig: initialNotificationConfig,
      initialNotificationSent: false,
      initialNotificationSentAt: null,
      // Recurring meeting fields
      isRecurring: _isRecurring,
      recurrenceFrequency:
          _isRecurring ? _recurrenceFrequency : RecurrenceFrequency.none,
      recurrenceInterval: _isRecurring ? _recurrenceInterval : 1,
      recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
      recurrenceDayOfWeek: _isRecurring && _selectedDateTime != null
          ? _selectedDateTime!.weekday % 7 // 0=Sunday, 6=Saturday
          : null,
      recurrenceDayOfMonth: _isRecurring && _selectedDateTime != null
          ? _selectedDateTime!.day
          : null,
    );

    final success = await supabaseProvider.createMeetingWithInitialNotification(
      meeting,
      _reminderMinutes,
    );

    if (success) {
      if (mounted) {
        String message;
        if (_initialNotificationTiming == NotificationTiming.immediate) {
          message = 'Meeting created and members notified';
        } else if (_initialNotificationTiming == NotificationTiming.scheduled) {
          message = 'Meeting created, notification scheduled';
        } else {
          message = 'Meeting created successfully';
        }

        CustomToast.show(context, message: message, type: ToastType.success);
        Navigator.pop(context);
      }
    } else {
      // Hide loading state and show error
      setState(() {
        _isCreating = false;
      });

      if (mounted) {
        CustomToast.show(context,
            message: supabaseProvider.error ??
                'Failed to create meeting. Please try again.',
            type: ToastType.error);
      }
    }
  }

  Widget _buildMeetingScopeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Scope',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.textSecondary(context),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.inputBorderColor(context),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              _buildScopeOption(
                value: 'local',
                icon: Remix.building_2_line,
                title: 'Branch Members',
                subtitle: 'Visible to selected branch (or Global)',
                isFirst: true,
              ),
              _buildScopeOption(
                value: 'invite',
                icon: Remix.user_star_line,
                title: 'Specific People',
                subtitle: 'Invite individual users',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScopeOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = _meetingScope == value;

    return InkWell(
      onTap: () {
        setState(() {
          _meetingScope = value;
          // Clear branch selection when switching away from 'local'
          if (value != 'local') {
            _selectedBranch = null;
          }
          // Clear user selection when switching away from 'invite'
          if (value != 'invite') {
            _selectedUserIds = [];
          }
        });
      },
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(11) : Radius.zero,
        topRight: isFirst ? const Radius.circular(11) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(11) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(11) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary(context).withValues(alpha: 0.08)
              : Colors.transparent,
          border: !isLast
              ? Border(
                  bottom: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary(context)
                      : AppTheme.inputBorderColor(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary(context),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Icon
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppTheme.primary(context)
                  : AppTheme.textSecondary(context),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }
}
