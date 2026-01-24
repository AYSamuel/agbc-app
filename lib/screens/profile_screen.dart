import 'package:flutter/material.dart';
import 'package:grace_portal/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/providers/branches_provider.dart';
import 'package:grace_portal/widgets/custom_back_button.dart';
import 'package:grace_portal/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final branchesProvider = Provider.of<BranchesProvider>(context);
    final user = authService.currentUserProfile;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Modern Header with Gradient Background
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Bar with Back Button (only show if there's a route to pop)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Row(
                      children: [
                        if (canPop) ...[
                          CustomBackButton(
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Text(
                          'My Profile',
                          style: AppTheme.titleStyle.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
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
                                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  backgroundImage: (user?.photoUrl != null &&
                                          user!.photoUrl!.isNotEmpty)
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child: (user?.photoUrl == null ||
                                          user!.photoUrl!.isEmpty)
                                      ? const Icon(Icons.person,
                                          size: 50, color: AppTheme.primaryColor)
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.secondaryColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Name
                          Text(
                            user?.displayName ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkNeutralColor,
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
                                const Icon(
                                  Icons.church,
                                  size: 16,
                                  color: AppTheme.neutralColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  branchDisplayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.neutralColor,
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
                    icon: Icons.person,
                    title: 'Personal Information',
                    accentColor: AppTheme.primaryColor,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          title: 'Email',
                          value: user?.email ?? 'Not set',
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          title: 'Phone',
                          value: user?.phoneNumber ?? 'Not set',
                          icon: Icons.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          title: 'Location',
                          value: user?.locationString ?? 'Not set',
                          icon: Icons.location_on,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Branch Information Section
                  _buildModernSection(
                    icon: Icons.church,
                    title: 'Branch Information',
                    accentColor: AppTheme.secondaryColor,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          title: 'Branch',
                          value: user?.branchId?.isNotEmpty == true
                              ? branchesProvider.getBranchName(user!.branchId!)
                              : 'Not assigned',
                          icon: Icons.church,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          title: 'Role',
                          value: user?.role.toString().split('.').last.toUpperCase() ?? 'MEMBER',
                          icon: Icons.badge,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.errorColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
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
                              Icons.logout,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sign out of your account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.neutralColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNeutralColor,
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
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkNeutralColor,
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
