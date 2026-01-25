import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import '../widgets/custom_toast.dart';

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
        CustomToast.show(context,
            message: 'Access denied. Admin privileges required.',
            type: ToastType.error);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
      return const HomeScreen();
    }

    return child;
  }
}
