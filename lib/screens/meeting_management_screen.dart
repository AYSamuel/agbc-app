import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/supabase_provider.dart';
import '../models/meeting_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';

class MeetingManagementScreen extends StatelessWidget {
  const MeetingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseProvider = Provider.of<SupabaseProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CustomBackButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Meeting Management',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNeutralColor,
                    ),
                  ),
                ],
              ),
            ),
            // Meetings List
            Expanded(
              child: StreamBuilder<List<MeetingModel>>(
                stream: supabaseProvider.getAllMeetings(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
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
                            Icons.event_note,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Meetings Found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are currently no meetings in the system.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.neutralColor,
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
                      final meeting = meetings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: AppTheme.cardColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meeting.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.darkNeutralColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          meeting.description,
                                          style: GoogleFonts.inter(
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
                                  _buildStatusChip(meeting.status),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildMeetingDetails(context, meeting),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditMeetingDialog(
                                        context, meeting),
                                    color: AppTheme.primaryColor,
                                    tooltip: 'Edit Meeting',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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

  Widget _buildStatusChip(MeetingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusDisplayText(status),
        style: GoogleFonts.inter(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMeetingDetails(BuildContext context, MeetingModel meeting) {
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.calendar_today,
          label: 'Date',
          value: _formatDateTime(meeting.dateTime),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.location_on,
          label: 'Location',
          value: meeting.location,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.people,
          label: 'Expected Attendance',
          value: meeting.expectedAttendance.toString(),
        ),
        if (meeting.isVirtual && meeting.meetingLink != null) ...[
          const SizedBox(height: 8),
          _buildClickableLinkRow(
            context: context,
            icon: Icons.video_call,
            label: 'Meeting Link',
            value: meeting.meetingLink!,
            url: meeting.meetingLink!,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.neutralColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.neutralColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.darkNeutralColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildClickableLinkRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required String url,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.neutralColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.neutralColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () async {
              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not launch meeting link',
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error opening meeting link: ${e.toString()}',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.blue,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  void _showEditMeetingDialog(BuildContext context, MeetingModel meeting) {
    // TODO: Implement meeting edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Meeting editing functionality coming soon',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
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
