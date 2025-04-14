import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/widgets/radial_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showTaskCreationDialog(BuildContext context) {
    // TODO: Implement task creation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Task'),
        content: const Text('Task creation dialog will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMeetingCreationDialog(BuildContext context) {
    // TODO: Implement meeting creation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Meeting'),
        content: const Text('Meeting creation dialog will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'AGBC App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TODO: Add content sections for tasks and meetings
            Expanded(
              child: Center(
                child: Text(
                  'Welcome to AGBC App',
                  style: AppTheme.titleStyle,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: RadialMenu(
        onTaskPressed: () => _showTaskCreationDialog(context),
        onMeetingPressed: () => _showMeetingCreationDialog(context),
      ),
    );
  }
}
