import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../providers/supabase_provider.dart';

/// A widget for selecting multiple users from a list.
/// Displays selected users as chips and provides search functionality.
class MultiUserSelectWidget extends StatefulWidget {
  /// List of currently selected user IDs
  final List<String> selectedUserIds;

  /// Callback when selection changes
  final void Function(List<String>) onSelectionChanged;

  /// User ID to exclude from the list (e.g., current user)
  final String? excludeUserId;

  /// Label displayed above the widget
  final String label;

  /// Whether the widget is interactive
  final bool enabled;

  /// Optional hint text for the search field
  final String? searchHint;

  /// Optional validator function
  final String? Function(List<String>)? validator;

  const MultiUserSelectWidget({
    super.key,
    required this.selectedUserIds,
    required this.onSelectionChanged,
    this.excludeUserId,
    this.label = 'Select Users',
    this.enabled = true,
    this.searchHint,
    this.validator,
  });

  @override
  State<MultiUserSelectWidget> createState() => _MultiUserSelectWidgetState();
}

class _MultiUserSelectWidgetState extends State<MultiUserSelectWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isExpanded = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _validate();
  }

  @override
  void didUpdateWidget(MultiUserSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUserIds != widget.selectedUserIds) {
      _validate();
    }
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.selectedUserIds);
      });
    }
  }

  void _toggleUser(String userId) {
    if (!widget.enabled) return;

    final newSelection = List<String>.from(widget.selectedUserIds);
    if (newSelection.contains(userId)) {
      newSelection.remove(userId);
    } else {
      newSelection.add(userId);
    }
    widget.onSelectionChanged(newSelection);
  }

  void _removeUser(String userId) {
    if (!widget.enabled) return;

    final newSelection = List<String>.from(widget.selectedUserIds);
    newSelection.remove(userId);
    widget.onSelectionChanged(newSelection);
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    var filtered = users.where((user) {
      // Exclude specified user
      if (widget.excludeUserId != null && user.id == widget.excludeUserId) {
        return false;
      }
      // Only include active users
      if (!user.isActive) return false;
      return true;
    }).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user.displayName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    }

    // Sort: selected users first, then alphabetically
    filtered.sort((a, b) {
      final aSelected = widget.selectedUserIds.contains(a.id);
      final bSelected = widget.selectedUserIds.contains(b.id);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      return a.displayName.compareTo(b.displayName);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with selected count
        Row(
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textSecondary(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
            ),
            if (widget.selectedUserIds.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.selectedUserIds.length} selected',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary(context),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Main container
        Container(
          decoration: BoxDecoration(
            color: widget.enabled
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _errorText != null
                  ? Theme.of(context).colorScheme.error
                  : _isExpanded
                      ? AppTheme.primary(context)
                      : AppTheme.inputBorderColor(context),
              width: _isExpanded ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              // Selected users chips row
              if (widget.selectedUserIds.isNotEmpty) ...[
                StreamBuilder<List<UserModel>>(
                  stream: Provider.of<SupabaseProvider>(context, listen: false)
                      .getAllUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 32,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      );
                    }

                    final allUsers = snapshot.data!;
                    final selectedUsers = allUsers
                        .where((u) => widget.selectedUserIds.contains(u.id))
                        .toList();

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.primary(context).withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11),
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedUsers.map((user) {
                          return _UserChip(
                            user: user,
                            onRemove: widget.enabled
                                ? () => _removeUser(user.id)
                                : null,
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],

              // Toggle button to expand/collapse
              InkWell(
                onTap: widget.enabled
                    ? () => setState(() => _isExpanded = !_isExpanded)
                    : null,
                borderRadius: widget.selectedUserIds.isEmpty
                    ? BorderRadius.circular(11)
                    : const BorderRadius.only(
                        bottomLeft: Radius.circular(11),
                        bottomRight: Radius.circular(11),
                      ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Remix.user_add_line,
                        size: 20,
                        color: widget.enabled
                            ? AppTheme.textSecondary(context)
                            : AppTheme.textMuted(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.selectedUserIds.isEmpty
                              ? 'Tap to select users'
                              : 'Tap to ${_isExpanded ? 'collapse' : 'add more users'}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: widget.enabled
                                ? AppTheme.textSecondary(context)
                                : AppTheme.textMuted(context),
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: widget.enabled
                              ? AppTheme.primary(context)
                              : AppTheme.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded user list
              if (_isExpanded) ...[
                const Divider(height: 1),
                // Search input
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: widget.searchHint ?? 'Search users...',
                      hintStyle: GoogleFonts.inter(
                        color: AppTheme.textMuted(context),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Remix.search_line,
                        size: 20,
                        color: AppTheme.textMuted(context),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Remix.close_line,
                                size: 18,
                                color: AppTheme.primary(context),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.inputBorderColor(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.inputBorderColor(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.primary(context),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // User list
                StreamBuilder<List<UserModel>>(
                  stream: Provider.of<SupabaseProvider>(context, listen: false)
                      .getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Error loading users',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      );
                    }

                    final users = _filterUsers(snapshot.data ?? []);

                    if (users.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Remix.user_search_line,
                                size: 48,
                                color: AppTheme.textMuted(context),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No users found for "$_searchQuery"'
                                    : 'No users available',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textMuted(context),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isSelected =
                              widget.selectedUserIds.contains(user.id);

                          return _UserListTile(
                            user: user,
                            isSelected: isSelected,
                            onTap: () => _toggleUser(user.id),
                            isLast: index == users.length - 1,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        // Error text
        if (_errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            _errorText!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// A chip widget for displaying a selected user with remove capability
class _UserChip extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onRemove;

  const _UserChip({
    required this.user,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary(context).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primary(context).withValues(alpha: 0.1),
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary(context),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          // Name
          Text(
            user.displayName.split(' ').first, // First name only for chips
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          // Remove button
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Remix.close_circle_fill,
                size: 18,
                color: AppTheme.textMuted(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A list tile for displaying a user in the selection list
class _UserListTile extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLast;

  const _UserListTile({
    required this.user,
    required this.isSelected,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary(context).withValues(alpha: 0.08)
              : Colors.transparent,
          border: !isLast
              ? Border(
                  bottom: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color:
                    isSelected ? AppTheme.primary(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary(context)
                      : AppTheme.inputBorderColor(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary(context).withValues(alpha: 0.1),
              backgroundImage:
                  user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary(context),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleLabel(user.role),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(user.role),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.pastor:
        return Colors.purple;
      case UserRole.worker:
        return Colors.blue;
      case UserRole.member:
        return Colors.green;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.pastor:
        return 'Pastor';
      case UserRole.worker:
        return 'Worker';
      case UserRole.member:
        return 'Member';
    }
  }
}
