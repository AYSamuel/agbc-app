import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/meeting_model.dart';
import '../utils/theme.dart';

class MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback? onTap;
  final bool showStatus;
  final double? width;

  const MeetingCard({
    super.key,
    required this.meeting,
    this.onTap,
    this.showStatus = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 280,
        margin: const EdgeInsets.only(right: 16, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDate(meeting.dateTime),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatTime(meeting.dateTime),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showStatus) ...[
                  const SizedBox(width: 8),
                  _buildStatusChip(),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              meeting.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meeting.description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  meeting.isVirtual ? Icons.video_call : Icons.location_on,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    meeting.isVirtual ? 'Virtual Meeting' : meeting.location,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (meeting.expectedAttendance > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${meeting.expectedAttendance} expected',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(),
        style: GoogleFonts.inter(
          color: _getStatusColor(),
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (meeting.status) {
      case MeetingStatus.scheduled:
        return Colors.blue;
      case MeetingStatus.inprogress:
        return Colors.green;
      case MeetingStatus.completed:
        return Colors.grey;
      case MeetingStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (meeting.status) {
      case MeetingStatus.scheduled:
        return 'Scheduled';
      case MeetingStatus.inprogress:
        return 'Ongoing';
      case MeetingStatus.completed:
        return 'Completed';
      case MeetingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}
