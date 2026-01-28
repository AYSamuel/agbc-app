import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grace_portal/models/meeting_model.dart';
import 'package:grace_portal/models/user_model.dart';
import 'package:grace_portal/screens/meeting_creation_screen.dart';
import 'package:grace_portal/config/theme.dart';
import 'package:grace_portal/config/animations.dart';
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
import 'package:remixicon/remixicon.dart';

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
import '../widgets/custom_toast.dart';
import '../services/bible_verse_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _onRefresh() async {
    try {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      notificationProvider.clearError();
      supabaseProvider.clearError();

      await Future.wait([
        if (authService.isAuthenticated) authService.initialize(),
        notificationProvider.loadNotifications(),
        notificationProvider.refreshNotificationCount(),
      ]);

      notificationProvider.reinitialize();
    } catch (e) {
      debugPrint('Error during refresh: $e');
      if (mounted) {
        CustomToast.show(context,
            message: 'Failed to refresh data: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userProfile = authService.currentUserProfile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.accent(context),
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                AppAnimations.staggeredFadeIn(
                  index: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: AppTheme.textMuted(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userProfile?.displayName.split(' ').first ??
                                  'User',
                              style: GoogleFonts.roboto(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.accent(context),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: (userProfile?.photoUrl != null &&
                                      userProfile!.photoUrl!.isNotEmpty)
                                  ? Image.network(
                                      userProfile.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(
                                          Remix.user_3_line,
                                          size: 24,
                                          color: AppTheme.accent(context),
                                        );
                                      },
                                    )
                                  : Icon(
                                      Remix.user_3_line,
                                      size: 24,
                                      color: AppTheme.accent(context),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Daily Verse Card
                AppAnimations.staggeredFadeIn(
                  index: 1,
                  child: FutureBuilder<DailyVerse>(
                    future: BibleVerseService().getTodayVerse(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const DailyVerseCard(
                          verse: 'Loading daily verse...',
                          reference: 'KJV',
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const DailyVerseCard(
                          verse:
                              '"For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future."',
                          reference: 'Jeremiah 29:11',
                        );
                      }
                      final dv = snapshot.data!;
                      return DailyVerseCard(
                        verse: dv.verse,
                        reference:
                            '${dv.reference} (${dv.translationId.toUpperCase()})',
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Task Status Card
                AppAnimations.staggeredFadeIn(
                  index: 2,
                  child: StreamBuilder<List<TaskModel>>(
                    stream: Provider.of<SupabaseProvider>(context)
                        .getUserInvolvedTasks(userProfile?.id ?? ''),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final tasks = snapshot.data!;
                      final uncompletedTasks = tasks
                          .where((task) => task.status != TaskStatus.completed)
                          .toList();
                      final hasUncompletedTasks = uncompletedTasks.isNotEmpty;

                      if (userProfile?.role == UserRole.member &&
                          !hasUncompletedTasks) {
                        return const SizedBox.shrink();
                      }

                      return TaskStatusCard(tasks: tasks);
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                AppAnimations.staggeredFadeIn(
                  index: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
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
                          StreamBuilder<List<MeetingModel>>(
                            stream: Provider.of<SupabaseProvider>(context)
                                .getAllMeetings(),
                            builder: (context, snapshot) {
                              final hasUpcomingMeetings = snapshot.hasData &&
                                  snapshot.data!.any((meeting) =>
                                      meeting.dateTime
                                          .isAfter(DateTime.now()) &&
                                      meeting.status ==
                                          MeetingStatus.scheduled &&
                                      meeting.parentMeetingId == null);

                              return QuickActionCard(
                                icon: Remix.calendar_event_line,
                                label: 'Services',
                                showDot: hasUpcomingMeetings,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const UpcomingEventsScreen(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          QuickActionCard(
                            icon: Remix.heart_line,
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
                            icon: Remix.book_read_line,
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
                            icon: Remix.hand_coin_line,
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
                            icon: Remix.team_line,
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
                            icon: Remix.more_line,
                            label: 'More',
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);
                              final isAdmin = authService.isAdmin;

                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => CustomDrawer(
                                  title: 'More Options',
                                  items: [
                                    DrawerItem(
                                      icon: Remix.user_settings_line,
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
                                      icon: Remix.task_line,
                                      label: 'Tasks',
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TasksScreen(
                                                    showBackButton: true),
                                          ),
                                        );
                                      },
                                    ),
                                    if (isAdmin)
                                      DrawerItem(
                                        icon: Remix.admin_line,
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
                                      icon: Remix.settings_3_line,
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
                                      icon: Remix.question_line,
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
                                      icon: Remix.information_line,
                                      label: 'About',
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AboutScreen(),
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
                    ],
                  ),
                ),

                const SizedBox(height: 90),
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
      CustomToast.show(context,
          message: 'Only workers, pastors, and administrators can create tasks',
          type: ToastType.error);
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
