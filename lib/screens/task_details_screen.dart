import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';

class TaskDetailsScreen extends StatefulWidget {
  // ... (existing code)
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  // ... (existing code)
}

@override
Widget build(BuildContext context) {
  // ... (existing code)

  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Task Details',
        style: AppTheme.titleStyle,
      ),
    ),
    // ... (rest of the existing code)
  );
}

@override
void initState() {
  // ... (existing code)
}

@override
void dispose() {
  // ... (existing code)
  super.dispose();
}
} 