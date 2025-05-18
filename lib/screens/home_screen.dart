import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/widgets/task_status_card.dart';
import 'package:agbc_app/widgets/daily_verse_card.dart';
import 'package:agbc_app/widgets/quick_action_card.dart';
import 'package:agbc_app/widgets/radial_menu.dart';
import 'package:agbc_app/widgets/app_nav_bar.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/supabase_provider.dart';
import '../models/task_model.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_branch_screen.dart';
import 'add_task_screen.dart';
import 'meetings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: true);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Navigation Bar
            const AppNavBar(
              onNotificationTap: null, // TODO: Implement notification handling
              notificationCount: 3, // TODO: Get actual notification count
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
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
                                  user?.displayName ?? 'User',
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
                                image: (user != null &&
                                        user.photoUrl != null &&
                                        user.photoUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(user.photoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: (user == null ||
                                      user.photoUrl == null ||
                                      user.photoUrl!.isEmpty)
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
                            .getTasksForUser(user?.id ?? ''),
                        builder: (context, snapshot) {
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          return TaskStatusCard(tasks: snapshot.data!);
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

                      // Church News
                      Text(
                        'Church News',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNewsCard(
                        'Choir Rehearsal Schedule Update',
                        'The choir rehearsal has been rescheduled to Thursday evenings at 6:30 PM starting next week.',
                        'May 11, 2025',
                      ),
                      const SizedBox(height: 12),
                      _buildNewsCard(
                        'Food Drive Success',
                        'Thanks to your generosity, we collected over 500 items for the local food bank last weekend!',
                        'May 10, 2025',
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
                          TextButton(
                            onPressed: () {},
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
                      SizedBox(
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
                      ),

                      const SizedBox(
                          height: 90), // Bottom padding for the nav bar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: user?.role == 'member'
          ? null
          : RadialMenu(
              onTaskPressed: () => _showTaskCreationDialog(context),
              onMeetingPressed:
                  (user?.role == 'pastor' || user?.role == 'admin')
                      ? () => _showMeetingCreationDialog(context)
                      : null,
              onBranchPressed: user?.role == 'admin'
                  ? () => _showBranchCreationDialog(context)
                  : null,
              showBranchOption: user?.role == 'admin',
              showMeetingOption:
                  user?.role == 'pastor' || user?.role == 'admin',
            ),
    );
  }

  void _showTaskCreationDialog(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user?.role == 'member') {
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
      MaterialPageRoute(builder: (context) => const MeetingsScreen()),
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

  Widget _buildNewsCard(String title, String description, String date) {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.newspaper_rounded,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
