import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../providers/supabase_provider.dart';
import '../providers/branches_provider.dart';
import '../models/meeting_model.dart';
import '../models/church_branch_model.dart';
import '../models/initial_notification_config.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_dropdown.dart';
import '../utils/focus_helper.dart';

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
  final _recurrenceIntervalController = TextEditingController(text: '1');

  DateTime? _selectedDateTime;
  DateTime? _selectedEndTime;
  ChurchBranch? _selectedBranch;
  bool _isVirtual = false;

  // Add these missing state variables for the loading overlay
  bool _isCreating = false;
  bool _showSuccess = false;

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
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
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
                    child: Row(
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
                                'Create Meeting',
                                style: AppTheme.titleStyle.copyWith(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Schedule a new meeting event',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meeting Details Card
                          _buildModernSection(
                            icon: Icons.event,
                            title: 'Meeting Details',
                            accentColor: AppTheme.primaryColor,
                            child: Column(
                              children: [
                                CustomInput(
                                  controller: _titleController,
                                  label: 'Meeting Title',
                                  hint: 'Enter meeting title',
                                  prefixIcon: const Icon(Icons.title),
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
                                  prefixIcon: const Icon(Icons.description),
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a description';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date & Time Card
                          _buildModernSection(
                            icon: Icons.access_time,
                            title: 'Date & Time',
                            accentColor: AppTheme.secondaryColor,
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: _selectDateTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppTheme.neutralColor.withValues(alpha: 0.15),
                                          width: 1.5),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.event_available,
                                          color: AppTheme.secondaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Meeting Start Time',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: AppTheme.neutralColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _selectedDateTime != null
                                                    ? _formatDateTime(_selectedDateTime!)
                                                    : 'Select start date and time',
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  color: _selectedDateTime != null
                                                      ? AppTheme.darkNeutralColor
                                                      : AppTheme.neutralColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: _selectEndTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppTheme.neutralColor.withValues(alpha: 0.15),
                                          width: 1.5),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.event_busy,
                                          color: AppTheme.secondaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Meeting End Time',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: AppTheme.neutralColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _selectedEndTime != null
                                                    ? _formatDateTime(_selectedEndTime!)
                                                    : 'Select end date and time',
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  color: _selectedEndTime != null
                                                      ? AppTheme.darkNeutralColor
                                                      : AppTheme.neutralColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Location Card
                          _buildModernSection(
                            icon: Icons.location_on,
                            title: 'Location',
                            accentColor: AppTheme.accentColor,
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
                                      activeThumbColor: AppTheme.accentColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Virtual Meeting',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: AppTheme.darkNeutralColor,
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
                                    prefixIcon: const Icon(Icons.link),
                                    validator: (value) {
                                      if (_isVirtual && (value == null || value.isEmpty)) {
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
                                    prefixIcon: const Icon(Icons.place),
                                    validator: (value) {
                                      if (!_isVirtual && (value == null || value.isEmpty)) {
                                        return 'Please enter a location';
                                      }
                                      return null;
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Initial Notification Section
                          Text(
                            'Initial Notification',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkNeutralColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose when to notify branch members about this meeting:',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.neutralColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Initial Notification Timing Options
                          Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _initialNotificationTiming == NotificationTiming.immediate 
                                        ? AppTheme.primaryColor 
                                        : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: _initialNotificationTiming == NotificationTiming.immediate
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      )
                                    : null,
                                ),
                                title: Text(
                                  'Notify immediately',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: AppTheme.darkNeutralColor,
                                  ),
                                ),
                                subtitle: Text(
                                  'Send notification as soon as the meeting is created',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.neutralColor,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _initialNotificationTiming = NotificationTiming.immediate;
                                    _scheduledNotificationDateTime = null;
                                  });
                                },
                              ),
                              ListTile(
                                leading: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _initialNotificationTiming == NotificationTiming.scheduled 
                                        ? AppTheme.primaryColor 
                                        : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: _initialNotificationTiming == NotificationTiming.scheduled
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      )
                                    : null,
                                ),
                                title: Text(
                                  'Schedule notification',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: AppTheme.darkNeutralColor,
                                  ),
                                ),
                                subtitle: Text(
                                  'Send notification at a specific date and time',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.neutralColor,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _initialNotificationTiming = NotificationTiming.scheduled;
                                  });
                                },
                              ),
                              ListTile(
                                leading: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _initialNotificationTiming == NotificationTiming.none 
                                        ? AppTheme.primaryColor 
                                        : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: _initialNotificationTiming == NotificationTiming.none
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      )
                                    : null,
                                ),
                                title: Text(
                                  'No initial notification',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: AppTheme.darkNeutralColor,
                                  ),
                                ),
                                subtitle: Text(
                                  'Don\'t send any notification when meeting is created',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.neutralColor,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _initialNotificationTiming = NotificationTiming.none;
                                    _scheduledNotificationDateTime = null;
                                  });
                                },
                              ),
                            ],
                          ),

                          // Scheduled Notification Date/Time Picker
                          if (_initialNotificationTiming == NotificationTiming.scheduled) ...[
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _selectScheduledNotificationDateTime,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.neutralColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notification Date & Time',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppTheme.neutralColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _scheduledNotificationDateTime != null
                                          ? _formatDateTime(_scheduledNotificationDateTime!)
                                          : 'Select when to send notification',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: _scheduledNotificationDateTime != null
                                            ? AppTheme.darkNeutralColor
                                            : AppTheme.neutralColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

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
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.neutralColor,
                                width: 2,
                              ),
                            );
                          }),

                          const SizedBox(height: 32),

                          // Recurring Meeting Section
                          Text(
                            'Recurring Meeting',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkNeutralColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set up this meeting to repeat automatically',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.neutralColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Recurring Toggle
                          Row(
                            children: [
                              Switch(
                                value: _isRecurring,
                                onChanged: (value) {
                                  setState(() {
                                    _isRecurring = value;
                                  });
                                },
                                activeTrackColor: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enable Recurring',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppTheme.darkNeutralColor,
                                ),
                              ),
                            ],
                          ),

                          // Recurring Configuration (shown when enabled)
                          if (_isRecurring) ...[
                            const SizedBox(height: 16),

                            // Frequency Selector
                            CustomDropdown<RecurrenceFrequency>(
                              label: 'Repeat',
                              value: _recurrenceFrequency,
                              items: RecurrenceFrequency.values
                                  .where((freq) => freq != RecurrenceFrequency.none)
                                  .map<DropdownMenuItem<RecurrenceFrequency>>(
                                      (RecurrenceFrequency freq) {
                                return DropdownMenuItem<RecurrenceFrequency>(
                                  value: freq,
                                  child: Text(_getFrequencyLabel(freq)),
                                );
                              }).toList(),
                              onChanged: (freq) {
                                if (freq != null) {
                                  setState(() {
                                    _recurrenceFrequency = freq;
                                  });
                                }
                              },
                              validator: null,
                            ),
                            const SizedBox(height: 16),

                            // Interval Selector (Every X weeks/months, etc.)
                            CustomInput(
                              controller: _recurrenceIntervalController,
                              label: 'Every (interval)',
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final interval = int.tryParse(value) ?? 1;
                                setState(() {
                                  _recurrenceInterval =
                                      interval > 0 ? interval : 1;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an interval';
                                }
                                final interval = int.tryParse(value);
                                if (interval == null || interval < 1) {
                                  return 'Interval must be at least 1';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getIntervalHint(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.neutralColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // End Date or Count
                            Text(
                              'Ends',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkNeutralColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectRecurrenceEndDate,
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
                                            'End Date',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: AppTheme.neutralColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _recurrenceEndDate != null
                                                ? _formatDate(_recurrenceEndDate!)
                                                : 'Never',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              color: _recurrenceEndDate != null
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
                            const SizedBox(height: 8),
                            // Info message about "Never" end date
                            if (_recurrenceEndDate == null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Remix.information_line,
                                      size: 20,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'When set to "Never", only 3 months of future instances will be created. You can manually extend the series later as needed.',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],

                          const SizedBox(height: 32),

                          // Create Meeting Button
                          CustomButton(
                            onPressed: _isCreating ? null : _createMeeting,
                            isLoading: _isCreating,
                            height: 56,
                            child: Text(
                              _isCreating ? 'Creating Meeting...' : 'Create Meeting',
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

          // Loading Overlay
          if (_isCreating)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
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
                            ? const Icon(
                                Icons.check_circle,
                                key: ValueKey('success'),
                                color: Colors.green,
                                size: 64,
                              )
                            : const CircularProgressIndicator(
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
    if (!mounted) return;

    // FIXED: Dismiss keyboard before showing date picker
    FocusHelper.unfocus(context);

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
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

    if (date != null && mounted) {
      final time = await showTimePicker(
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

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
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

    if (!mounted) return;

    // FIXED: Dismiss keyboard before showing date picker
    FocusHelper.unfocus(context);

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime!,
      firstDate: _selectedDateTime!,
      lastDate: _selectedDateTime!.add(const Duration(days: 7)),
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

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime!.add(const Duration(hours: 1)),
        ),
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

      if (time != null && mounted) {
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End time must be after start time'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedEndTime = endDateTime;
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _getFrequencyLabel(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
      case RecurrenceFrequency.none:
        return 'None';
    }
  }

  String _getIntervalHint() {
    switch (_recurrenceFrequency) {
      case RecurrenceFrequency.daily:
        return _recurrenceInterval == 1
            ? 'Repeats every day'
            : 'Repeats every $_recurrenceInterval days';
      case RecurrenceFrequency.weekly:
        return _recurrenceInterval == 1
            ? 'Repeats every week'
            : 'Repeats every $_recurrenceInterval weeks';
      case RecurrenceFrequency.monthly:
        return _recurrenceInterval == 1
            ? 'Repeats every month'
            : 'Repeats every $_recurrenceInterval months';
      case RecurrenceFrequency.yearly:
        return _recurrenceInterval == 1
            ? 'Repeats every year'
            : 'Repeats every $_recurrenceInterval years';
      case RecurrenceFrequency.none:
        return '';
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    if (!mounted) return;

    // FIXED: Dismiss keyboard before showing date picker
    FocusHelper.unfocus(context);

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: _selectedDateTime ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years
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

    if (date != null && mounted) {
      setState(() {
        _recurrenceEndDate = date;
      });

      // FIXED: Ensure focus is cleared after setting the value
      FocusHelper.unfocus(context);
    }

    // FIXED: Final cleanup - ensure keyboard stays dismissed
    if (mounted) {
      FocusHelper.unfocus(context);
    }
  }

  Future<void> _selectScheduledNotificationDateTime() async {
    if (!mounted) return;

    // FIXED: Dismiss keyboard before showing date picker
    FocusHelper.unfocus(context);

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
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

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
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

      if (time != null && mounted) {
        final scheduledDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        // Validate that scheduled time is in the future
        if (scheduledDateTime.isBefore(DateTime.now())) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Scheduled notification time must be in the future'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _scheduledNotificationDateTime = scheduledDateTime;
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

  Future<void> _createMeeting() async {
    // Dismiss keyboard before validation
    FocusScope.of(context).unfocus();

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

    // Validate scheduled notification if selected
    if (_initialNotificationTiming == NotificationTiming.scheduled &&
        _scheduledNotificationDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time for the scheduled notification'),
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

    // Create initial notification config
    final initialNotificationConfig = InitialNotificationConfig(
      enabled: _initialNotificationTiming != NotificationTiming.none,
      timing: _initialNotificationTiming ?? NotificationTiming.immediate,
      scheduledDateTime: _scheduledNotificationDateTime,
    );

    // Determine if this is a global meeting based on selected branch
    final isGlobalMeeting = _selectedBranch?.isGlobalBranch ?? false;

    final meeting = MeetingModel(
      id: '', // Will be generated by database
      title: _titleController.text,
      description: _descriptionController.text,
      dateTime: _selectedDateTime!,
      type: isGlobalMeeting ? 'global' : 'local',
      endTime: _selectedEndTime!,
      branchId: isGlobalMeeting ? null : _selectedBranch?.id,
      organizerId: supabaseProvider.currentUser!.id,
      organizerName:
          supabaseProvider.currentUser?.userMetadata?['full_name'] ?? 'Unknown',
      location: _isVirtual ? 'Virtual Meeting' : _locationController.text,
      isVirtual: _isVirtual,
      meetingLink: _isVirtual ? _meetingLinkController.text : null,
      initialNotificationConfig: initialNotificationConfig,
      initialNotificationSent: false,
      initialNotificationSentAt: null,
      // Recurring meeting fields
      isRecurring: _isRecurring,
      recurrenceFrequency: _isRecurring ? _recurrenceFrequency : RecurrenceFrequency.none,
      recurrenceInterval: _isRecurring ? _recurrenceInterval : 1,
      recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
      recurrenceDayOfWeek: _isRecurring && _selectedDateTime != null
          ? _selectedDateTime!.weekday % 7  // 0=Sunday, 6=Saturday
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _recurrenceIntervalController.dispose();
    super.dispose();
  }
}