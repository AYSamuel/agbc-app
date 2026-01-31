import 'package:flutter/material.dart';
import 'package:grace_portal/config/theme.dart';
import 'package:remixicon/remixicon.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/services/storage_service.dart';
import 'package:grace_portal/providers/branches_provider.dart';
import 'package:grace_portal/providers/supabase_provider.dart';
import 'package:grace_portal/widgets/custom_back_button.dart';
import 'package:grace_portal/widgets/custom_toast.dart';
import 'package:grace_portal/widgets/branch_details_sheet.dart';
import 'package:grace_portal/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final bool isMainTab;
  const ProfileScreen({
    super.key,
    this.isMainTab = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingPhoto = false;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // Initialize branches when screen is opened
    Future.microtask(() async {
      if (mounted) {
        final branchesProvider =
            Provider.of<BranchesProvider>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUserProfile;

        // Fetch branches if not already loaded
        await branchesProvider.fetchBranches();

        // If user has a branch, ensure it's loaded
        if (user?.branchId != null && user!.branchId!.isNotEmpty) {
          await branchesProvider.fetchBranches();
        }
      }
    });
  }

  /// Show bottom sheet with options to take photo or choose from gallery
  void _showImagePickerOptions() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserProfile;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Remix.camera_line, color: AppTheme.primary(context)),
                ),
                title: const Text('Take Photo'),
                subtitle: Text(
                  'Use your camera',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Remix.image_line, color: AppTheme.secondary(context)),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: Text(
                  'Select an existing photo',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Remix.delete_bin_line, color: AppTheme.errorColor),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  subtitle: Text(
                    'Delete your profile picture',
                    style: TextStyle(
                      color: AppTheme.errorColor.withValues(alpha: 0.6),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePicture();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Pick, crop, and upload a profile picture
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser == null) {
      if (mounted) {
        CustomToast.show(context, message: 'Please sign in first', type: ToastType.error);
      }
      return;
    }

    setState(() => _isUploadingPhoto = true);

    try {
      final url = await _storageService.pickCropAndUploadProfilePicture(
        source: source,
        userId: authService.currentUser!.id,
        toolbarColor: AppTheme.primary(context),
      );

      if (url != null) {
        // Refresh user profile to show new image
        await authService.refreshUserProfile();

        if (mounted) {
          CustomToast.show(
            context,
            message: 'Profile picture updated!',
            type: ToastType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Failed to update profile picture',
          type: ToastType.error,
        );
      }
      debugPrint('Error uploading profile picture: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  /// Remove the current profile picture
  Future<void> _removeProfilePicture() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      await _storageService.deleteProfilePicture(authService.currentUser!.id);

      // Refresh user profile
      await authService.refreshUserProfile();

      if (mounted) {
        CustomToast.show(
          context,
          message: 'Profile picture removed',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Failed to remove profile picture',
          type: ToastType.error,
        );
      }
      debugPrint('Error removing profile picture: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      final currentContext = context;
      final authService =
          Provider.of<AuthService>(currentContext, listen: false);
      await authService.signOut();
      if (!mounted) return;
      if (!currentContext.mounted) return;

      // Use pushNamedAndRemoveUntil to clear entire navigation stack
      // This prevents back button from accessing authenticated screens
      Navigator.of(currentContext).pushNamedAndRemoveUntil(
        '/login',
        (route) => false, // Remove all previous routes
        arguments: {'clearForm': true},
      );
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      CustomToast.show(context, message: e.toString(), type: ToastType.error);
    }
  }

  /// Show branch details in a bottom sheet
  Future<void> _showBranchDetails(String branchId) async {
    try {
      final branchesProvider =
          Provider.of<BranchesProvider>(context, listen: false);
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);

      final branch = branchesProvider.getBranchById(branchId);
      if (branch == null) {
        if (mounted) {
          CustomToast.show(
            context,
            message: 'Branch not found',
            type: ToastType.error,
          );
        }
        return;
      }

      // Get all users in this branch
      final users = await supabaseProvider.getAllUsers().first;
      final branchMembers =
          users.where((user) => user.branchId == branch.id).toList();

      if (!mounted || !context.mounted) return;

      BranchDetailsSheet.show(
        context,
        branch: branch,
        members: branchMembers,
        showMemberEmails: false,
      );
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error loading branch details',
          type: ToastType.error,
        );
      }
      debugPrint('Error showing branch details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final branchesProvider = Provider.of<BranchesProvider>(context);
    final user = authService.currentUserProfile;
    final canPop = Navigator.canPop(context);
    final showBackButton = canPop && !widget.isMainTab;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Modern Header with Gradient Background
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Bar with Back Button (only show if there's a route to pop and not in main tab)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Row(
                    children: [
                      if (showBackButton) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomBackButton(
                            onPressed: () => Navigator.of(context).pop(),
                            showBackground: false,
                            showShadow: false,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Profile Card - Redesigned with horizontal layout
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.3)
                              : AppTheme.primary(context).withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Gradient Header Bar
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary(context),
                                AppTheme.secondary(context),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                        ),
                        // Card Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Picture - Left Side
                              Stack(
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primary(context).withValues(alpha: 0.2),
                                          AppTheme.secondary(context).withValues(alpha: 0.2),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.primary(context).withValues(alpha: 0.3),
                                        width: 3,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(17),
                                      child: (user?.photoUrl != null &&
                                              user!.photoUrl!.isNotEmpty)
                                          ? CachedNetworkImage(
                                              imageUrl: user.photoUrl!,
                                              width: 110,
                                              height: 110,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: AppTheme.primary(context)
                                                    .withValues(alpha: 0.1),
                                                child: const Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) =>
                                                  Container(
                                                color: AppTheme.primary(context)
                                                    .withValues(alpha: 0.1),
                                                child: Icon(
                                                  Remix.user_3_line,
                                                  size: 50,
                                                  color: AppTheme.primary(context),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: AppTheme.primary(context)
                                                  .withValues(alpha: 0.1),
                                              child: Icon(
                                                Remix.user_3_line,
                                                size: 50,
                                                color: AppTheme.primary(context),
                                              ),
                                            ),
                                    ),
                                  ),
                                  // Camera Button
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: GestureDetector(
                                      onTap: _isUploadingPhoto ? null : _showImagePickerOptions,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.primary(context),
                                              AppTheme.secondary(context),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primary(context)
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: _isUploadingPhoto
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Remix.camera_fill,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              // User Details - Right Side
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Full Name
                                    Text(
                                      user?.fullName ?? 'User',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary(context),
                                        letterSpacing: -0.3,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Email
                                    if (user?.email != null && user!.email.isNotEmpty)
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textMuted(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 12),
                                    // Role Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user?.role ?? UserRole.member)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _getRoleColor(user?.role ?? UserRole.member)
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getRoleIcon(user?.role ?? UserRole.member),
                                            size: 14,
                                            color: _getRoleColor(user?.role ?? UserRole.member),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            user?.role
                                                    .toString()
                                                    .split('.')
                                                    .last
                                                    .toUpperCase() ??
                                                'MEMBER',
                                            style: TextStyle(
                                              color: _getRoleColor(user?.role ?? UserRole.member),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Branch Info - Tappable
                                    Builder(builder: (context) {
                                      String branchDisplayName;
                                      final hasBranch = user?.branchId?.isNotEmpty == true;
                                      if (hasBranch) {
                                        branchDisplayName =
                                            branchesProvider.getBranchName(user!.branchId!);
                                      } else {
                                        branchDisplayName = 'No branch assigned';
                                      }
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: hasBranch
                                              ? () => _showBranchDetails(user!.branchId!)
                                              : null,
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: hasBranch
                                                  ? AppTheme.secondary(context)
                                                      .withValues(alpha: 0.1)
                                                  : Theme.of(context).brightness == Brightness.dark
                                                      ? Colors.white.withValues(alpha: 0.05)
                                                      : Colors.black.withValues(alpha: 0.03),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: hasBranch
                                                    ? AppTheme.secondary(context)
                                                        .withValues(alpha: 0.2)
                                                    : Theme.of(context).brightness == Brightness.dark
                                                        ? Colors.white.withValues(alpha: 0.08)
                                                        : Colors.black.withValues(alpha: 0.06),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Remix.building_2_fill,
                                                  size: 14,
                                                  color: hasBranch
                                                      ? AppTheme.secondary(context)
                                                      : AppTheme.textMuted(context),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    branchDisplayName,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: hasBranch
                                                          ? AppTheme.secondary(context)
                                                          : AppTheme.textMuted(context),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (hasBranch) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Remix.arrow_right_s_line,
                                                    size: 14,
                                                    color: AppTheme.secondary(context)
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Personal Information Section
                  _buildModernSection(
                    icon: Remix.user_3_line,
                    title: 'Personal Information',
                    accentColor: AppTheme.primary(context),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          title: 'Email',
                          value: user?.email ?? 'Not set',
                          icon: Remix.mail_line,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          title: 'Phone',
                          value: user?.phoneNumber ?? 'Not set',
                          icon: Remix.phone_line,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          title: 'Location',
                          value: user?.locationString ?? 'Not set',
                          icon: Remix.map_pin_line,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Branch Information Section
                  _buildModernSection(
                    icon: Remix.community_line,
                    title: 'Branch Information',
                    accentColor: AppTheme.secondary(context),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          title: 'Branch',
                          value: user?.branchId?.isNotEmpty == true
                              ? branchesProvider.getBranchName(user!.branchId!)
                              : 'Not assigned',
                          icon: Remix.building_2_line,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          title: 'Role',
                          value: user?.role
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase() ??
                              'MEMBER',
                          icon: Remix.government_line,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout Button
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.errorColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Remix.logout_box_r_line,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sign out of your account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(150),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Remix.arrow_right_s_line,
                            color: AppTheme.errorColor.withValues(alpha: 0.5),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with colored accent
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primary(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
}
