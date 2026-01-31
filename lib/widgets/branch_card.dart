import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import '../models/church_branch_model.dart';
import '../config/theme.dart';

class BranchCard extends StatefulWidget {
  final ChurchBranch branch;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final bool showActions;
  final int? memberCount;

  const BranchCard({
    super.key,
    required this.branch,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.showActions = true,
    this.memberCount,
  });

  @override
  State<BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<BranchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatLocation(Map<String, dynamic> location) {
    if (location.isEmpty) return 'No location set';

    final city = location['city']?.toString().trim();
    final country = location['country']?.toString().trim();

    if (city != null &&
        country != null &&
        city.isNotEmpty &&
        country.isNotEmpty) {
      return '$city, $country';
    } else if (city != null && city.isNotEmpty) {
      return city;
    } else if (country != null && country.isNotEmpty) {
      return country;
    }

    return 'No location set';
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppTheme.primary(context);
    final secondaryAccent = AppTheme.secondary(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onView != null
            ? () {
                HapticFeedback.lightImpact();
                widget.onView!();
              }
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : accentColor.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : accentColor.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // Gradient Header
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        secondaryAccent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                // Card Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Container with gradient background
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withValues(alpha: 0.15),
                                  secondaryAccent.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Remix.building_2_fill,
                              color: accentColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title and Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.branch.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary(context),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.branch.isActive
                                            ? AppTheme.successColor
                                                .withValues(alpha: 0.12)
                                            : AppTheme.warningColor
                                                .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: widget.branch.isActive
                                              ? AppTheme.successColor
                                                  .withValues(alpha: 0.3)
                                              : AppTheme.warningColor
                                                  .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: widget.branch.isActive
                                                  ? AppTheme.successColor
                                                  : AppTheme.warningColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.branch.isActive
                                                ? 'Active'
                                                : 'Inactive',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: widget.branch.isActive
                                                  ? AppTheme.successColor
                                                  : AppTheme.warningColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.branch.description != null &&
                                    widget.branch.description!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.branch.description!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted(context),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Info Pills Row
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          // Location Pill
                          _InfoPill(
                            icon: Remix.map_pin_2_fill,
                            text: _formatLocation(widget.branch.location),
                            color: accentColor,
                            isDark: isDark,
                          ),
                          // Address Pill
                          if (widget.branch.address.isNotEmpty)
                            _InfoPill(
                              icon: Remix.home_5_fill,
                              text: widget.branch.address,
                              color: secondaryAccent,
                              isDark: isDark,
                            ),
                          // Member Count Pill
                          if (widget.memberCount != null)
                            _InfoPill(
                              icon: Remix.group_fill,
                              text:
                                  '${widget.memberCount} member${widget.memberCount != 1 ? 's' : ''}',
                              color: AppTheme.successColor,
                              isDark: isDark,
                            ),
                        ],
                      ),

                      // Actions
                      if (widget.showActions &&
                          (widget.onEdit != null ||
                              widget.onDelete != null)) ...[
                        const SizedBox(height: 20),
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.dividerColor(context),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // View Details Button
                            if (widget.onView != null)
                              Expanded(
                                child: _ActionButton(
                                  icon: Remix.eye_line,
                                  label: 'View',
                                  color: accentColor,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    widget.onView!();
                                  },
                                  isDark: isDark,
                                ),
                              ),
                            if (widget.onView != null &&
                                (widget.onEdit != null ||
                                    widget.onDelete != null))
                              const SizedBox(width: 10),
                            // Edit Button
                            if (widget.onEdit != null)
                              Expanded(
                                child: _ActionButton(
                                  icon: Remix.edit_2_line,
                                  label: 'Edit',
                                  color: secondaryAccent,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    widget.onEdit!();
                                  },
                                  isDark: isDark,
                                ),
                              ),
                            if (widget.onEdit != null && widget.onDelete != null)
                              const SizedBox(width: 10),
                            // Delete Button
                            if (widget.onDelete != null)
                              _ActionButton(
                                icon: Remix.delete_bin_6_line,
                                label: 'Delete',
                                color: AppTheme.errorColor,
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  widget.onDelete!();
                                },
                                isDark: isDark,
                                isDestructive: true,
                              ),
                          ],
                        ),
                      ],
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
}

// Info Pill Widget
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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
