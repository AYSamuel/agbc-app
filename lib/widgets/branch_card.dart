import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/church_branch_model.dart';
import '../config/theme.dart';

class BranchCard extends StatelessWidget {
  final ChurchBranch branch;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final bool showActions;

  const BranchCard({
    super.key,
    required this.branch,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.showActions = true,
  });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onView != null
              ? () {
                  HapticFeedback.lightImpact();
                  onView!();
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Colored accent bar
              Container(
                height: 5,
                decoration: const BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.church,
                            color: AppTheme.successColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branch.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (branch.description != null &&
                                  branch.description!.isNotEmpty) ...[
                                Text(
                                  branch.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Location
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatLocation(branch.location),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Address
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.home,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            branch.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (showActions &&
                        (onEdit != null || onDelete != null)) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onEdit != null)
                            TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onEdit!();
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              label: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          if (onEdit != null && onDelete != null)
                            const SizedBox(width: 8),
                          if (onDelete != null)
                            TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onDelete!();
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: AppTheme.errorColor,
                              ),
                              label: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
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
    );
  }
}
