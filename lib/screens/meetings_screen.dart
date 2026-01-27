import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meeting_model.dart';
import '../widgets/meeting_card.dart';

import '../providers/supabase_provider.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final SupabaseProvider _supabaseProvider = SupabaseProvider();
  String? _currentUserBranchId;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final userId = _supabaseProvider.currentUser?.id;
    if (userId != null) {
      final user = await _supabaseProvider.getUserById(userId);
      if (mounted) {
        setState(() {
          _currentUserBranchId = user?.branchId;
          _isLoadingUser = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<MeetingModel>>(
                  stream: _supabaseProvider.getAllMeetings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
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
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading meetings',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please try again later',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    // Show loading while fetching user data
                    if (_isLoadingUser) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final allMeetings = snapshot.data ?? [];

                    // Get current user info for visibility filtering
                    final currentUserId = _supabaseProvider.currentUser?.id;

                    // Filter meetings:
                    // 1. Exclude recurring instances (only show parent meetings)
                    // 2. Show only meetings visible to current user (based on type)
                    // 3. Always show meetings where user is the organizer
                    final meetings = allMeetings.where((meeting) {
                      // Exclude recurring instances
                      if (meeting.parentMeetingId != null) return false;

                      // Always show if user is the organizer
                      if (currentUserId != null &&
                          meeting.organizerId == currentUserId) {
                        return true;
                      }

                      // Check visibility based on meeting type
                      return meeting.shouldNotify(
                          _currentUserBranchId, currentUserId);
                    }).toList();

                    if (meetings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No meetings scheduled',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Meetings will appear here when they are created',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
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
                        padding: const EdgeInsets.all(8.0),
                        itemCount: meetings.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: MeetingCard(meeting: meetings[index]),
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
      ),
    );
  }
}
