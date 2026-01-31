import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import '../models/church_branch_model.dart';
import '../models/user_model.dart';
import '../config/theme.dart';

class BranchDetailsSheet extends StatelessWidget {
  final ChurchBranch branch;
  final List<UserModel> members;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showMemberEmails;

  const BranchDetailsSheet({
    super.key,
    required this.branch,
    required this.members,
    this.onEdit,
    this.onDelete,
    this.showMemberEmails = true,
  });

  static Future<void> show(
    BuildContext context, {
    required ChurchBranch branch,
    required List<UserModel> members,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    bool showMemberEmails = true,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BranchDetailsSheet(
        branch: branch,
        members: members,
        onEdit: onEdit,
        onDelete: onDelete,
        showMemberEmails: showMemberEmails,
      ),
    );
  }

  String _formatLocation(Map<String, dynamic> location) {
    if (location.isEmpty) return 'No location set';

    final city = location['city']?.toString().trim();
    final state = location['state']?.toString().trim();
    final country = location['country']?.toString().trim();

    List<String> parts = [];
    if (city != null && city.isNotEmpty) parts.add(city);
    if (state != null && state.isNotEmpty) parts.add(state);
    if (country != null && country.isNotEmpty) parts.add(country);

    return parts.isNotEmpty ? parts.join(', ') : 'No location set';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppTheme.primary(context);
    final secondaryAccent = AppTheme.secondary(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with Gradient
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  secondaryAccent.withValues(alpha: isDark ? 0.15 : 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Branch Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, secondaryAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Remix.building_2_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Branch Name and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: branch.isActive
                              ? AppTheme.successColor.withValues(alpha: 0.15)
                              : AppTheme.warningColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: branch.isActive
                                ? AppTheme.successColor.withValues(alpha: 0.3)
                                : AppTheme.warningColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: branch.isActive
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              branch.isActive ? 'Active Branch' : 'Inactive',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: branch.isActive
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Close Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Remix.close_line,
                    color: AppTheme.textMuted(context),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Remix.map_pin_2_fill,
                          title: 'Location',
                          value: _formatLocation(branch.location),
                          color: accentColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Remix.group_fill,
                          title: 'Members',
                          value: '${members.length}',
                          color: AppTheme.successColor,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  // Address Card
                  if (branch.address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Remix.home_5_fill,
                      title: 'Address',
                      value: branch.address,
                      color: secondaryAccent,
                      isDark: isDark,
                      isFullWidth: true,
                    ),
                  ],

                  // Description
                  if (branch.description != null &&
                      branch.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(
                      icon: Remix.file_text_line,
                      title: 'Description',
                      color: accentColor,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        branch.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary(context),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  // Members Section
                  const SizedBox(height: 24),
                  _SectionHeader(
                    icon: Remix.team_fill,
                    title: 'Branch Members',
                    color: AppTheme.successColor,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${members.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Members List
                  if (members.isEmpty)
                    _EmptyMembersCard(isDark: isDark)
                  else
                    ...members.map(
                      (member) => _MemberCard(
                        member: member,
                        isDark: isDark,
                        showEmail: showMemberEmails,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (onEdit != null || onDelete != null) ...[
                    Row(
                      children: [
                        if (onEdit != null)
                          Expanded(
                            child: _ActionButton(
                              icon: Remix.edit_2_line,
                              label: 'Edit Branch',
                              color: accentColor,
                              onPressed: () {
                                Navigator.pop(context);
                                onEdit!();
                              },
                              isDark: isDark,
                            ),
                          ),
                        if (onEdit != null && onDelete != null)
                          const SizedBox(width: 12),
                        if (onDelete != null)
                          Expanded(
                            child: _ActionButton(
                              icon: Remix.delete_bin_6_line,
                              label: 'Delete',
                              color: AppTheme.errorColor,
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete!();
                              },
                              isDark: isDark,
                              isOutlined: true,
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Bottom Safe Area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Info Card Widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDark;
  final bool isFullWidth;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                  maxLines: isFullWidth ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// Member Card Widget
class _MemberCard extends StatelessWidget {
  final UserModel member;
  final bool isDark;
  final bool showEmail;

  const _MemberCard({
    required this.member,
    required this.isDark,
    this.showEmail = true,
  });

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppTheme.errorColor;
      case UserRole.pastor:
        return AppTheme.infoColor;
      case UserRole.worker:
        return AppTheme.warningColor;
      case UserRole.member:
        return AppTheme.successColor;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Remix.shield_star_fill;
      case UserRole.pastor:
        return Remix.user_star_fill;
      case UserRole.worker:
        return Remix.user_settings_fill;
      case UserRole.member:
        return Remix.user_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(member.role);
    final initials = member.fullName.isNotEmpty
        ? member.fullName
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : 'U';
    final hasPhoto = member.photoUrl != null && member.photoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar with profile picture or initials fallback
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: hasPhoto
                  ? null
                  : LinearGradient(
                      colors: [
                        AppTheme.primary(context),
                        AppTheme.secondary(context),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(14),
              image: hasPhoto
                  ? DecorationImage(
                      image: NetworkImage(member.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: hasPhoto
                  ? Border.all(
                      color: AppTheme.primary(context).withValues(alpha: 0.3),
                      width: 2,
                    )
                  : null,
            ),
            child: hasPhoto
                ? null
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Name and Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName.isNotEmpty ? member.fullName : 'Unknown User',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                if (showEmail && member.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: roleColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(member.role),
                  size: 12,
                  color: roleColor,
                ),
                const SizedBox(width: 4),
                Text(
                  member.role.name[0].toUpperCase() +
                      member.role.name.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: roleColor,
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

// Empty Members Card
class _EmptyMembersCard extends StatelessWidget {
  final bool isDark;

  const _EmptyMembersCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.textMuted(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Remix.user_add_line,
              size: 32,
              color: AppTheme.textMuted(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Members Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Members will appear here once they join this branch',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isDark;
  final bool isOutlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.isDark,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isOutlined
                ? Colors.transparent
                : color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: isOutlined ? 0.4 : 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
