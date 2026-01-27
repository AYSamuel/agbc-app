import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:remixicon/remixicon.dart';
import '../providers/supabase_provider.dart';
import '../models/meeting_model.dart';
import '../config/theme.dart';
import '../utils/timezone_helper.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_toast.dart';

class MeetingManagementScreen extends StatelessWidget {
  const MeetingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseProvider = Provider.of<SupabaseProvider>(context);

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
              ),
              child: Column(
                children: [
                  // Header row
                  Padding(
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
                            Remix.calendar_line,
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
                                'Meeting Management',
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Schedule and manage meetings',
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Meetings List
            Expanded(
              child: StreamBuilder<List<MeetingModel>>(
                stream: supabaseProvider.getAllMeetings(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary(context),
                      ),
                    );
                  }

                  final meetings = snapshot.data!;

                  if (meetings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Remix.calendar_line,
                            size: 64,
                            color: AppTheme.primary(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Meetings Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are currently no meetings in the system.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort meetings by date (most recent first)
                  meetings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: meetings.length,
                    itemBuilder: (context, index) {
                      return _buildMeetingCard(context, meetings[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(BuildContext context, MeetingModel meeting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to meeting details if needed
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Colored accent bar
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: _getStatusColor(context, meeting.status),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meeting.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                meeting.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(context, meeting.status)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusDisplayText(meeting.status),
                            style: TextStyle(
                              color: _getStatusColor(context, meeting.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Date and time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Remix.calendar_line,
                            size: 14,
                            color: AppTheme.primary(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateTime(meeting.dateTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Location
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Remix.map_pin_line,
                            size: 14,
                            color: AppTheme.primary(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            meeting.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (meeting.isVirtual && meeting.meetingLink != null) ...[
                      const SizedBox(height: 12),
                      // Meeting link
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Remix.video_chat_line,
                              size: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _launchMeetingLink(
                                  context, meeting.meetingLink!),
                              child: Text(
                                meeting.meetingLink!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchMeetingLink(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!context.mounted) return;
        CustomToast.show(context,
            message: 'Could not launch meeting link', type: ToastType.error);
      }
    } catch (e) {
      if (!context.mounted) return;
      CustomToast.show(context,
          message: 'Error opening meeting link: ${e.toString()}',
          type: ToastType.error);
    }
  }

  String _getStatusDisplayText(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.scheduled:
        return 'SCHEDULED';
      case MeetingStatus.inprogress:
        return 'ONGOING';
      case MeetingStatus.completed:
        return 'COMPLETED';
      case MeetingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _getStatusColor(BuildContext context, MeetingStatus status) {
    switch (status) {
      case MeetingStatus.scheduled:
        return Colors.blue;
      case MeetingStatus.inprogress:
        return Colors.green;
      case MeetingStatus.completed:
        return Theme.of(context).disabledColor;
      case MeetingStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Convert UTC to user's local timezone
    final userTimezone = TimezoneHelper.getDeviceTimezone();
    final localDateTime = TimezoneHelper.convertFromUtc(dateTime, userTimezone);
    return '${localDateTime.day}/${localDateTime.month}/${localDateTime.year} at ${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
  }
}
