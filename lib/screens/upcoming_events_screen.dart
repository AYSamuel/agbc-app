import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/meeting_model.dart';
import '../widgets/meeting_card.dart';
import '../widgets/custom_back_button.dart';
import '../utils/theme.dart';
import '../providers/supabase_provider.dart';
import 'meeting_details_screen.dart';

class UpcomingEventsScreen extends StatefulWidget {
  const UpcomingEventsScreen({super.key});

  @override
  State<UpcomingEventsScreen> createState() => _UpcomingEventsScreenState();
}

class _UpcomingEventsScreenState extends State<UpcomingEventsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
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
                    'Upcoming Events',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            
            // Events List
            Expanded(
              child: StreamBuilder<List<MeetingModel>>(
                stream: Provider.of<SupabaseProvider>(context).getAllMeetings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading events',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.neutralColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.red[300],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final meetings = snapshot.data ?? [];

                  // Filter for upcoming events only
                  // Exclude recurring instances - only show parent meetings
                  final upcomingMeetings = meetings
                      .where((meeting) =>
                          meeting.dateTime.isAfter(DateTime.now()) &&
                          meeting.status == MeetingStatus.scheduled &&
                          meeting.parentMeetingId == null) // Only show parent meetings, not instances
                      .toList();

                  // Sort by date (earliest first)
                  upcomingMeetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                  if (upcomingMeetings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 64,
                            color: AppTheme.neutralColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming events',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.neutralColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for new events',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.neutralColor.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: upcomingMeetings.length,
                      itemBuilder: (context, index) {
                        final meeting = upcomingMeetings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: MeetingCard(
                            meeting: meeting,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MeetingDetailsScreen(meeting: meeting),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}