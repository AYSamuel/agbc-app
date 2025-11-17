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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.backgroundColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Profile Picture with Edit Button
                        Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.transparent,
                                backgroundImage: (user?.photoUrl != null &&
                                        user!.photoUrl!.isNotEmpty)
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: (user?.photoUrl == null ||
                                        user!.photoUrl!.isEmpty)
                                    ? const Icon(Icons.person,
                                        size: 40, color: Color(0xFF1A237E))
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Name and Role
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user?.role ?? UserRole.member),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    _getRoleColor(user?.role ?? UserRole.member)
                                        .withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Builder(builder: (context) {
                          String branchDisplayName;
                          if (user?.branchId?.isNotEmpty == true) {
                            branchDisplayName =
                                branchesProvider.getBranchName(user!.branchId!);
                          } else {
                            branchDisplayName = 'None assigned yet';
                          }
                          return Text(
                            branchDisplayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Personal Information Section
                _buildSection(
                  context,
                  title: 'Personal Information',
                  children: [
                    _buildInfoCard(
                      context,
                      title: 'Email',
                      value: user?.email ?? 'Not set',
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Phone',
                      value: user?.phoneNumber ?? 'Not set',
                      icon: Icons.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Location',
                      value: user?.locationString ?? 'Not set',
                      icon: Icons.location_on,
                    ),
                  ],
                ),

                // Branch Information Section
                _buildSection(
                  context,
                  title: 'Branch Information',
                  children: [
                    _buildInfoCard(
                      context,
                      title: 'Branch',
                      value: user?.branchId?.isNotEmpty == true
                          ? branchesProvider.getBranchName(user!.branchId!)
                          : 'Not assigned',
                      icon: Icons.church,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Location',
                      value: user?.locationString ?? 'Not set',
                      icon: Icons.location_on,
                    ),
                  ],
                ),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.errorColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Sign out of your account',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
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
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}
