import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grace_portal/models/meeting_model.dart';
import 'package:grace_portal/models/user_model.dart';
import 'package:grace_portal/screens/meeting_creation_screen.dart';
import 'package:grace_portal/utils/theme.dart';
import 'package:grace_portal/widgets/meeting_card.dart';
import 'package:grace_portal/widgets/task_status_card.dart';
import 'package:grace_portal/widgets/daily_verse_card.dart';
import 'package:grace_portal/widgets/quick_action_card.dart';
import 'package:grace_portal/widgets/radial_menu.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/supabase_provider.dart';
import '../models/task_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_provider.dart';

import 'add_branch_screen.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Remove the _overlayEntry and notification-related methods since they're now in MainNavigationScreen

  @override
  void initState() {
    super.initState();
    // Set status bar to transparent with dark icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    // Reset status bar to default when leaving the screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  // Add refresh method to reload all data
  Future<void> _onRefresh() async {
    try {
      // Get providers
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Clear any existing errors
      notificationProvider.clearError();
      supabaseProvider.clearError();

      // Refresh user profile data
      if (authService.isAuthenticated) {
        await authService
            .initialize(); // This calls _loadUserProfile internally
      }

      // Refresh notifications - load fresh data from database
      await notificationProvider.loadNotifications();
      await notificationProvider.refreshNotificationCount();

      // Reinitialize notification provider to get latest real-time updates
      notificationProvider.reinitialize();

      // Add a small delay to show the refresh indicator
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error during refresh: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: true);
    final userProfile = authService.currentUserProfile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 40.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userProfile?.displayName ?? 'User',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                          image: (userProfile != null &&
                                  userProfile.photoUrl != null &&
                                  userProfile.photoUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(userProfile.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (userProfile == null ||
                                userProfile.photoUrl == null ||
                                userProfile.photoUrl!.isEmpty)
                            ? Icon(Icons.person,
                                size: 32, color: AppTheme.primaryColor)
                            : null,
                      ),
                    ],
                  ),
                ),

                // Daily Verse Card
                const DailyVerseCard(
                  verse:
                      '"For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future."',
                  reference: 'Jeremiah 29:11',
                ),

                const SizedBox(height: 14),

                // Task Status Card
                StreamBuilder<List<TaskModel>>(
                  stream: Provider.of<SupabaseProvider>(context)
                      .getUserTasks(userProfile?.id ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final tasks = snapshot.data!;
                    final hasTasks = tasks.isNotEmpty;

                    // Hide card for members without tasks
                    if (userProfile?.role == UserRole.member && !hasTasks) {
                      return const SizedBox.shrink();
                    }

                    return TaskStatusCard(tasks: tasks);
                  },
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    QuickActionCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Sunday Service',
                    ),
                    QuickActionCard(
                      icon: Icons.favorite_rounded,
                      label: 'Prayer Requests',
                    ),
                    QuickActionCard(
                      icon: Icons.book_rounded,
                      label: 'Bible Study',
                    ),
                    QuickActionCard(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Donate',
                    ),
                    QuickActionCard(
                      icon: Icons.people_rounded,
                      label: 'Community',
                    ),
                    QuickActionCard(
                      icon: Icons.more_horiz_rounded,
                      label: 'More',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Upcoming Events
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Events',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    // Only show "View all" button for admins and pastors
                    if (userProfile?.role == UserRole.admin || 
                        userProfile?.role == UserRole.pastor)
                      TextButton(
                        onPressed: () {
                          // Navigate to meetings screen
                          Navigator.pushNamed(context, '/meetings');
                        },
                        child: Text(
                          'View all',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<MeetingModel>>(
                  stream:
                      Provider.of<SupabaseProvider>(context).getAllMeetings(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError || !snapshot.hasData) {
                      return SizedBox(
                        height: 180,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildEventCard(
                              'May 12',
                              'Sunday, 10:00 AM',
                              'Sunday Worship Service',
                              'Join us for praise, worship and an inspiring message from Pastor David.',
                              'Main Sanctuary',
                            ),
                            _buildEventCard(
                              'May 15',
                              'Wednesday, 7:00 PM',
                              'Midweek Bible Study',
                              'Dive deeper into God\'s word with our interactive Bible study session.',
                              'Fellowship Hall',
                            ),
                          ],
                        ),
                      );
                    }

                    final meetings = snapshot.data!;
                    final upcomingMeetings = meetings
                        .where((meeting) =>
                            meeting.dateTime.isAfter(DateTime.now()) &&
                            meeting.status == MeetingStatus.scheduled)
                        .take(5)
                        .toList();

                    if (upcomingMeetings.isEmpty) {
                      return SizedBox(
                        height: 180,
                        child: Center(
                          child: Text(
                            'No upcoming meetings',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: upcomingMeetings.length,
                        itemBuilder: (context, index) {
                          final meeting = upcomingMeetings[index];
                          return MeetingCard(
                            meeting: meeting,
                            showStatus: false,
                            onTap: () {
                              // Navigate to meeting details or meetings screen
                              Navigator.pushNamed(context, '/meetings');
                            },
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 90), // Bottom padding for the nav bar
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: userProfile?.role == UserRole.member
          ? null
          : RadialMenu(
              onTaskPressed: () => _showTaskCreationDialog(context),
              onMeetingPressed: (userProfile?.role == UserRole.pastor ||
                      userProfile?.role == UserRole.admin)
                  ? () => _showMeetingCreationDialog(context)
                  : null,
              onBranchPressed: userProfile?.role == UserRole.admin
                  ? () => _showBranchCreationDialog(context)
                  : null,
              showBranchOption: userProfile?.role == UserRole.admin,
              showMeetingOption: userProfile?.role == UserRole.pastor ||
                  userProfile?.role == UserRole.admin,
            ),
    );
  }

  void _showTaskCreationDialog(BuildContext context) {
    final userProfile =
        Provider.of<AuthService>(context, listen: false).currentUserProfile;
    if (userProfile?.role == UserRole.member) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Only workers, pastors, and administrators can create tasks'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
  }

  void _showMeetingCreationDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MeetingCreationScreen(),
      ),
    );
  }

  void _showBranchCreationDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBranchScreen()),
    );
  }

  Widget _buildEventCard(
    String date,
    String time,
    String title,
    String description,
    String location,
  ) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
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
                Icons.location_on,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
