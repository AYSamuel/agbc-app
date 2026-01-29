import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../config/theme.dart';
import '../models/initial_notification_config.dart';
import '../widgets/custom_date_time_picker.dart';
import '../widgets/modern_form_section.dart';

class InitialNotificationSettings extends StatelessWidget {
  final NotificationTiming? timing;
  final DateTime? scheduledTime;
  final ValueChanged<NotificationTiming> onTimingChanged;
  final ValueChanged<DateTime?> onScheduledTimeChanged;
  final String itemType; // 'meeting' or 'task'
  final String targetAudience; // 'branch members' or 'assignee'

  const InitialNotificationSettings({
    super.key,
    required this.timing,
    this.scheduledTime,
    required this.onTimingChanged,
    required this.onScheduledTimeChanged,
    required this.itemType,
    required this.targetAudience,
  });

  @override
  Widget build(BuildContext context) {
    return ModernFormSection(
      icon: Remix.notification_3_line,
      title: 'Initial Notification',
      accentColor: AppTheme.secondary(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose when to notify $targetAudience about this $itemType:',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildOption(
                context,
                NotificationTiming.immediate,
                'Notify immediately',
                'Send notification as soon as the $itemType is created',
              ),
              _buildOption(
                context,
                NotificationTiming.scheduled,
                'Schedule notification',
                'Send notification at a specific date and time',
              ),
              _buildOption(
                context,
                NotificationTiming.none,
                'No initial notification',
                'Don\'t send any notification when $itemType is created',
              ),
            ],
          ),
          if (timing == NotificationTiming.scheduled) ...[
            const SizedBox(height: 16),
            CustomDateTimePicker(
              key: ValueKey(scheduledTime),
              label: 'Notification Date & Time',
              hintText: 'Select when to send notification',
              value: scheduledTime,
              onChanged: onScheduledTimeChanged,
              mode: DateTimePickerMode.dateAndTime,
              validator: (value) {
                if (timing == NotificationTiming.scheduled && value == null) {
                  return 'Please select a notification time';
                }
                if (value != null && value.isBefore(DateTime.now())) {
                  return 'Notification time must be in the future';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    NotificationTiming option,
    String title,
    String subtitle,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: timing == option
                ? AppTheme.primary(context)
                : Theme.of(context).disabledColor, // or AppTheme.dividerColor(context) if available
            width: 2,
          ),
        ),
        child: timing == option
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
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      onTap: () => onTimingChanged(option),
    );
  }
}
