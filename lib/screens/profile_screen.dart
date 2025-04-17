import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:agbc_app/services/auth_service.dart';
import 'package:agbc_app/models/user_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.15),
                      AppTheme.backgroundColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture with Edit Button
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.transparent,
                            backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                                ? const Icon(Icons.person, size: 40, color: Color(0xFF1A237E))
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
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Name and Role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user?.role ?? 'member'),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getRoleColor(user?.role ?? 'member').withOpacity(0.3),
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
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Member of AGBC Lighthouse Berlin Church',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Personal Information Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 16),
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
              ),

              // Church Information Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Church Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Departments',
                      value: user?.departments.isNotEmpty ?? false
                          ? user!.departments.join(', ')
                          : 'Not assigned',
                      icon: Icons.group,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Member Since',
                      value: user?.dateJoined != null
                          ? '${user!.dateJoined!.day}/${user.dateJoined!.month}/${user.dateJoined!.year}'
                          : 'Not set',
                      icon: Icons.calendar_today,
                    ),
                  ],
                ),
              ),

              // Logout Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        await authService.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
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
                                      fontWeight: FontWeight.w500,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
} 