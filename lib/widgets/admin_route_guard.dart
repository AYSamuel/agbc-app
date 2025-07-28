import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';

class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isAdmin) {
      // Show error and redirect to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Admin privileges required.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
      return const HomeScreen();
    }

    return child;
  }
}
