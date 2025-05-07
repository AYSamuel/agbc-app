import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../providers/branches_provider.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final Color roleColor;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.roleColor,
  });

  String _getBranchName(BuildContext context, String? branchId) {
    if (branchId == null || branchId.isEmpty) return 'Not assigned';

    final branchesProvider =
        Provider.of<BranchesProvider>(context, listen: false);
    try {
      final branch = branchesProvider.branches.firstWhere(
        (branch) => branch.id == branchId,
      );
      return branch.name;
    } catch (e) {
      return 'Unknown Branch';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: roleColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: roleColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: roleColor.withValues(alpha: 0.1),
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 24,
                          color: roleColor,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: AppTheme.subtitleStyle.copyWith(
                        fontSize: 14,
                        color: AppTheme.neutralColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Location and Branch Info
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (user.location != null)
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppTheme.neutralColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    user.location!,
                                    style: AppTheme.subtitleStyle.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.neutralColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (user.branchId != null)
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.church,
                                  size: 14,
                                  color: AppTheme.neutralColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _getBranchName(context, user.branchId),
                                    style: AppTheme.subtitleStyle.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.neutralColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Role Badge and Edit Button
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    onPressed: onEdit,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
