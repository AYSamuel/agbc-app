import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../config/theme.dart';
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.dividerColor(context).withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: AppTheme.cardShadow(context),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
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
                  child: const Icon(
                    Remix.check_double_line,
                    color: AppTheme.successColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mark All as Read',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mark all notifications as read? You can still view them in your notification history.',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
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
                          foregroundColor: AppTheme.textMuted(context),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppTheme.dividerColor(context),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.roboto(
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Mark as Read',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Remix.notification_3_line,
              color: AppTheme.teal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Notifications',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const Spacer(),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final hasUnreadNotifications =
                  provider.notifications.any((n) => !n.isRead);

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: hasUnreadNotifications
                    ? TextButton.icon(
                        key: const ValueKey('mark_all_button'),
                        onPressed: () {
                          setState(() {
                            _showConfirmation = true;
                          });
                        },
                        icon: const Icon(
                          Remix.check_double_line,
                          size: 16,
                        ),
                        label: Text(
                          'Mark All as Read',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
            icon: const Icon(Remix.close_line),
            iconSize: 20,
            color: AppTheme.textMuted(context),
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
              color: AppTheme.teal,
              strokeWidth: 2,
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
                    color: AppTheme.backgroundColor(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Remix.notification_off_line,
                    size: 48,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'re all caught up!',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
          );
        }

        final sortedNotifications =
            List<NotificationModel>.from(provider.notifications)
              ..sort((a, b) {
                if (a.isRead != b.isRead) {
                  return a.isRead ? 1 : -1;
                }
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
            ? Theme.of(context).colorScheme.surface
            : AppTheme.teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: notification.isRead
              ? AppTheme.dividerColor(context).withValues(alpha: 0.5)
              : AppTheme.teal.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (!notification.isRead) {
              provider.markAsRead(notification.id);
            }
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
                              style: GoogleFonts.roboto(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.teal,
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
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: AppTheme.textSecondary(context),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        timeago.format(notification.createdAt),
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppTheme.textMuted(context),
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
        iconData = Remix.task_line;
        color = AppTheme.secondary(context);
        break;
      case NotificationType.taskDue:
        iconData = Remix.time_line;
        color = AppTheme.warning(context);
        break;
      case NotificationType.taskCompleted:
        iconData = Remix.checkbox_circle_line;
        color = AppTheme.success(context);
        break;
      case NotificationType.meetingReminder:
        iconData = Remix.calendar_event_line;
        color = AppTheme.primary(context);
        break;
      case NotificationType.meetingCancelled:
        iconData = Remix.calendar_close_line;
        color = AppTheme.error(context);
        break;
      case NotificationType.meetingUpdated:
        iconData = Remix.calendar_check_line;
        color = AppTheme.primary(context);
        break;
      case NotificationType.commentAdded:
        iconData = Remix.chat_3_line;
        color = AppTheme.secondary(context);
        break;
      case NotificationType.roleChanged:
        iconData = Remix.user_settings_line;
        color = AppTheme.secondary(context);
        break;
      case NotificationType.branchAnnouncement:
        iconData = Remix.broadcast_line;
        color = AppTheme.primary(context);
        break;
      case NotificationType.general:
        iconData = Remix.information_line;
        color = AppTheme.primary(context);
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
