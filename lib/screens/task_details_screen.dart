import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import 'package:google_fonts/google_fonts.dart';

/// A screen that displays the details of a task
class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({
    required this.task,
    super.key,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late TaskModel _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CustomBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          'Task Details',
          style: AppTheme.titleStyle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _task.title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _task.description,
              style: AppTheme.regularTextStyle,
            ),
            const SizedBox(height: 16),
            _buildStatusSection(),
            const SizedBox(height: 16),
            _buildDateSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkNeutralColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _task.status,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dates',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkNeutralColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildDateRow('Created', _task.createdAt),
        _buildDateRow('Due', _task.deadline),
      ],
    );
  }

  Widget _buildDateRow(String label, DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTheme.subtitleStyle,
          ),
          Text(
            _formatDate(date),
            style: AppTheme.regularTextStyle,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor() {
    switch (_task.status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
