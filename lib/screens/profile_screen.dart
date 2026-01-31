import 'package:flutter/material.dart';
import 'package:grace_portal/config/theme.dart';
import 'package:remixicon/remixicon.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/services/storage_service.dart';
import 'package:grace_portal/providers/branches_provider.dart';
import 'package:grace_portal/widgets/custom_back_button.dart';
import 'package:grace_portal/widgets/custom_toast.dart';
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
                // Profile Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Picture
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary(context)
                                      .withValues(alpha: 0.2),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: (user?.photoUrl != null &&
                                        user!.photoUrl!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: user.photoUrl!,
                                        width: 100,
                                        height: 100,
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
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _isUploadingPhoto ? null : _showImagePickerOptions,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary(context),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.secondary(context)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _isUploadingPhoto
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Remix.camera_line,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          user?.displayName ?? 'User',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user?.role ?? UserRole.member),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.role
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase() ??
                                'MEMBER',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Branch Info
                        Builder(builder: (context) {
                          String branchDisplayName;
                          if (user?.branchId?.isNotEmpty == true) {
                            branchDisplayName =
                                branchesProvider.getBranchName(user!.branchId!);
                          } else {
                            branchDisplayName = 'No branch assigned';
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Remix.community_line,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                branchDisplayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          );
                        }),
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
                          icon: Remix.community_line,
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
        return Colors.red;
      case UserRole.pastor:
        return Colors.purple;
      case UserRole.worker:
        return Colors.blue;
      case UserRole.member:
        return Colors.green;
    }
  }
}
