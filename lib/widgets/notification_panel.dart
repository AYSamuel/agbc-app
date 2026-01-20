import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../utils/theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPanel extends StatefulWidget {
  final VoidCallback? onClose;

  const NotificationPanel({super.key, this.onClose});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel>
    with SingleTickerProviderStateMixin {
  bool _showConfirmation = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.3, 0),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 380,
            height: 540,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: _buildNotificationList(context),
                      ),
                    ],
                  ),
                  if (_showConfirmation) _buildConfirmationOverlay(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.done_all,
                    color: AppTheme.successColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mark All as Read',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkNeutralColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mark all notifications as read? You can still view them in your notification history.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.neutralColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showConfirmation = false;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.neutralColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final provider = Provider.of<NotificationProvider>(
                              context,
                              listen: false);
                          await provider.markAllAsRead();
                          setState(() {
                            _showConfirmation = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Mark as Read',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Notifications',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkNeutralColor,
            ),
          ),
          const Spacer(),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              // Only show button if there are unread notifications
              final hasUnreadNotifications = provider.notifications.any((n) => !n.isRead);

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: hasUnreadNotifications
                    ? TextButton.icon(
                        key: const ValueKey('mark_all_button'),
                        onPressed: () {
                          setState(() {
                            _showConfirmation = true;
                          });
                        },
                        icon: const Icon(
                          Icons.done_all,
                          size: 16,
                        ),
                        label: Text(
                          'Mark All as Read',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.successColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('empty_button'),
                      ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: AppTheme.neutralColor,
            splashRadius: 20,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          );
        }

        if (provider.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: AppTheme.neutralColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkNeutralColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'re all caught up!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.neutralColor,
                  ),
                ),
              ],
            ),
          );
        }

        // Sort notifications: unread first, then by creation date (newest first)
        final sortedNotifications = List<NotificationModel>.from(provider.notifications)
          ..sort((a, b) {
            // First, sort by read status (unread first)
            if (a.isRead != b.isRead) {
              return a.isRead ? 1 : -1;
            }
            // Then sort by creation date (newest first)
            return b.createdAt.compareTo(a.createdAt);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sortedNotifications.length,
          itemBuilder: (context, index) {
            final notification = sortedNotifications[index];
            return _buildNotificationItem(context, notification, provider);
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : AppTheme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? AppTheme.dividerColor
              : AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Only mark as read when explicitly tapped
            if (!notification.isRead) {
              provider.markAsRead(notification.id);
            }
            // TODO: Handle notification tap action based on type
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.inter(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.darkNeutralColor,
                              ),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (notification.message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.neutralColor,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        timeago.format(notification.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.neutralColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.taskAssigned:
        iconData = Icons.assignment_outlined;
        color = AppTheme.primaryColor;
        break;
      case NotificationType.taskDue:
        iconData = Icons.schedule_outlined;
        color = AppTheme.warningColor;
        break;
      case NotificationType.taskCompleted:
        iconData = Icons.check_circle_outline;
        color = AppTheme.successColor;
        break;
      case NotificationType.meetingReminder:
        iconData = Icons.event_outlined;
        color = AppTheme.secondaryColor;
        break;
      case NotificationType.meetingCancelled:
        iconData = Icons.event_busy_outlined;
        color = AppTheme.errorColor;
        break;
      case NotificationType.meetingUpdated:
        iconData = Icons.event_note_outlined;
        color = AppTheme.primaryColor;
        break;
      case NotificationType.commentAdded:
        iconData = Icons.comment_outlined;
        color = AppTheme.accentColor;
        break;
      case NotificationType.roleChanged:
        iconData = Icons.person_outline;
        color = AppTheme.primaryColor;
        break;
      case NotificationType.branchAnnouncement:
        iconData = Icons.campaign_outlined;
        color = AppTheme.secondaryColor;
        break;
      case NotificationType.general:
        iconData = Icons.info_outline;
        color = AppTheme.neutralColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 20,
      ),
    );
  }
}
