import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meeting_model.dart';
import '../utils/theme.dart';

class MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final double? width;

  const MeetingCard({
    super.key,
    required this.meeting,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored accent bar
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: _getStatusColor(meeting.status),
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
                  mainAxisSize: MainAxisSize.min,
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkNeutralColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                meeting.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.neutralColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(meeting.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusDisplayText(meeting.status),
                            style: TextStyle(
                              color: _getStatusColor(meeting.status),
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
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateTime(meeting.dateTime),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.darkNeutralColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Location or Virtual Meeting indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: meeting.isVirtual
                                ? Colors.blue.withValues(alpha: 0.1)
                                : AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            meeting.isVirtual ? Icons.video_call : Icons.location_on,
                            size: 14,
                            color: meeting.isVirtual ? Colors.blue : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            meeting.isVirtual ? 'Virtual Meeting' : meeting.location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.darkNeutralColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (showActions && meeting.isVirtual && meeting.meetingLink != null) ...[
                      const SizedBox(height: 12),
                      // Meeting link (only shown when showActions is true)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.link,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _launchMeetingLink(context, meeting.meetingLink!),
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
                    if (showActions && (onEdit != null || onDelete != null)) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppTheme.neutralColor),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onEdit != null)
                            TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onEdit!();
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              label: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          if (onEdit != null && onDelete != null)
                            const SizedBox(width: 8),
                          if (onDelete != null)
                            TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onDelete!();
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: AppTheme.errorColor,
                              ),
                              label: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch meeting link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening meeting link: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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

  Color _getStatusColor(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.scheduled:
        return Colors.blue;
      case MeetingStatus.inprogress:
        return Colors.green;
      case MeetingStatus.completed:
        return AppTheme.neutralColor;
      case MeetingStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
