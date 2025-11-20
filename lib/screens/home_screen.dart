import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grace_portal/models/meeting_model.dart';
import 'package:grace_portal/models/user_model.dart';
import 'package:grace_portal/screens/meeting_creation_screen.dart';
import 'package:grace_portal/screens/meeting_details_screen.dart';
import 'package:grace_portal/utils/theme.dart';
import 'package:grace_portal/widgets/meeting_card.dart';
import 'package:grace_portal/widgets/task_status_card.dart';
import 'package:grace_portal/widgets/daily_verse_card.dart';
import 'package:grace_portal/widgets/quick_action_card.dart';
import 'package:grace_portal/widgets/radial_menu.dart';
import 'package:grace_portal/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/supabase_provider.dart';
import '../models/task_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_provider.dart';

import 'add_branch_screen.dart';
import 'add_task_screen.dart';
import 'upcoming_events_screen.dart';
import 'pray_screen.dart';
import 'read_screen.dart';
import 'give_screen.dart';
import 'profile_screen.dart';
import 'tasks_screen.dart';
import 'admin_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import '../widgets/admin_route_guard.dart';

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
    super.dispose();
  }

  // Optimized refresh method with parallel loading
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

      // Run all refresh operations in parallel for better performance
      await Future.wait([
        // Refresh user profile data
        if (authService.isAuthenticated)
          authService.initialize(), // This calls _loadUserProfile internally

        // Refresh notifications in parallel
        notificationProvider.loadNotifications(),
        notificationProvider.refreshNotificationCount(),
      ]);

      // Reinitialize notification provider to get latest real-time updates
      notificationProvider.reinitialize();
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
    // Only listen to auth changes, not full rebuilds
    final authService = Provider.of<AuthService>(context, listen: false);
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
                        ),
                        child: ClipOval(
                          child: (userProfile?.photoUrl != null &&
                                  userProfile!.photoUrl!.isNotEmpty)
                              ? Image.network(
                                  userProfile.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Show default icon if image fails to load
                                    return const Icon(
                                      Icons.person,
                                      size: 32,
                                      color: AppTheme.primaryColor,
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    // Show loading indicator while image loads
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryColor,
                                      ),
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: AppTheme.primaryColor,
                                ),
                        ),
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
                    // Show loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    // Hide on error
                    if (snapshot.hasError) {
                      return const SizedBox.shrink();
                    }

                    // Hide if no data
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final tasks = snapshot.data!;
                    // Count only uncompleted tasks
                    final uncompletedTasks = tasks
                        .where((task) => task.status != TaskStatus.completed)
                        .toList();
                    final hasUncompletedTasks = uncompletedTasks.isNotEmpty;

                    // Hide card for members without uncompleted tasks
                    if (userProfile?.role == UserRole.member && !hasUncompletedTasks) {
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
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpcomingEventsScreen(),
                          ),
                        );
                      },
                    ),
                    QuickActionCard(
                      icon: Icons.favorite_rounded,
                      label: 'Prayer Requests',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrayScreen(),
                          ),
                        );
                      },
                    ),
                    QuickActionCard(
                      icon: Icons.book_rounded,
                      label: 'Bible Study',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReadScreen(),
                          ),
                        );
                      },
                    ),
                    QuickActionCard(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Give',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GiveScreen(),
                          ),
                        );
                      },
                    ),
                    QuickActionCard(
                      icon: Icons.people_rounded,
                      label: 'Community',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrayScreen(),
                          ),
                        );
                      },
                    ),
                    QuickActionCard(
                      icon: Icons.more_horiz_rounded,
                      label: 'More',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        final authService =
                            Provider.of<AuthService>(context, listen: false);
                        final isAdmin = authService.isAdmin;

                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => CustomDrawer(
                            title: 'More Options',
                            items: [
                              DrawerItem(
                                icon: Icons.person_outline_rounded,
                                label: 'Profile',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                              DrawerItem(
                                icon: Icons.task_rounded,
                                label: 'Tasks',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TasksScreen(
                                          showBackButton: true),
                                    ),
                                  );
                                },
                              ),
                              if (isAdmin)
                                DrawerItem(
                                  icon: Icons.admin_panel_settings_rounded,
                                  label: 'Admin Center',
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AdminRouteGuard(
                                          child: AdminScreen(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              DrawerItem(
                                icon: Icons.settings_rounded,
                                label: 'Settings',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              DrawerItem(
                                icon: Icons.help_outline_rounded,
                                label: 'Help & Support',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HelpSupportScreen(),
                                    ),
                                  );
                                },
                              ),
                              DrawerItem(
                                icon: Icons.info_outline_rounded,
                                label: 'About',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AboutScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
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
                          // Navigate to upcoming events screen
                          Navigator.pushNamed(context, '/upcoming-events');
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
                    // Show loading state while data is being fetched
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    }

                    // Show error state if there's an error
                    if (snapshot.hasError) {
                      return SizedBox(
                        height: 180,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load meetings',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: _onRefresh,
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Show empty state if no data
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SizedBox(
                        height: 180,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No upcoming meetings',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final meetings = snapshot.data!;
                    final upcomingMeetings = meetings
                        .where((meeting) =>
                            meeting.dateTime.isAfter(DateTime.now()) &&
                            meeting.status == MeetingStatus.scheduled &&
                            meeting.parentMeetingId ==
                                null) // Only show parent meetings
                        .take(5)
                        .toList();

                    if (upcomingMeetings.isEmpty) {
                      return SizedBox(
                        height: 180,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No upcoming meetings scheduled',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
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
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < upcomingMeetings.length - 1 ? 12.0 : 0,
                            ),
                            child: MeetingCard(
                              meeting: meeting,
                              width: 280,
                              onTap: () {
                                // Navigate to meeting details screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MeetingDetailsScreen(meeting: meeting),
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
}
