import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:agbc_app/services/auth_service.dart';
import 'package:agbc_app/providers/branches_provider.dart';
import 'package:agbc_app/models/church_branch_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout() async {
    try {
      final currentContext = context;
      final authService =
          Provider.of<AuthService>(currentContext, listen: false);
      await authService.signOut();
      if (!mounted) return;
      if (!currentContext.mounted) return;
      Navigator.of(currentContext).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(isLoggingOut: true),
        ),
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
    final branchesProvider =
        Provider.of<BranchesProvider>(context); // Listen to BranchesProvider
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.backgroundColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Profile Picture with Edit Button
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.transparent,
                                backgroundImage: (user?.photoUrl != null &&
                                        user!.photoUrl!.isNotEmpty)
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: (user?.photoUrl == null ||
                                        user!.photoUrl!.isEmpty)
                                    ? const Icon(Icons.person,
                                        size: 50, color: Color(0xFF1A237E))
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Name and Role
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user?.role ?? 'member'),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: _getRoleColor(user?.role ?? 'member')
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            user?.role.toUpperCase() ?? 'MEMBER',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          String branchDisplayName;
                          if (user?.branchId?.isNotEmpty == true) {
                            if (branchesProvider.isLoading) {
                              branchDisplayName = 'Loading branch...';
                            } else if (!branchesProvider.isInitialized) {
                              branchDisplayName =
                                  'Initializing branches...'; // Or some other placeholder
                            } else {
                              branchDisplayName =
                                  _getBranchName(user!.branchId!);
                            }
                          } else {
                            branchDisplayName = 'None assigned yet';
                          }
                          return Text(
                            branchDisplayName,
                            style: TextStyle(
                              fontSize: 16,
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
                      value: user?.location ?? 'Not set',
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
                          ? _getBranchName(user!.branchId!)
                          : 'Not assigned',
                      icon: Icons.church,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Location',
                      value: user?.location ?? 'Not set',
                      icon: Icons.location_on,
                    ),
                  ],
                ),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.errorColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.logout,
                                color: AppTheme.errorColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Sign out of your account',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
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

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'pastor':
        return Colors.purple;
      case 'worker':
        return Colors.blue;
      case 'member':
      default:
        return Colors.green;
    }
  }

  String _getBranchName(String branchId) {
    final branchesProvider =
        Provider.of<BranchesProvider>(context, listen: false);
    final branch = branchesProvider.branches.firstWhere(
      (branch) => branch.id == branchId,
      orElse: () => ChurchBranch(
        id: branchId,
        name: 'Unknown Branch',
        address: '',
        members: [],
        departments: [],
        location: '',
        createdBy: '',
      ),
    );
    return branch.name;
  }
}
