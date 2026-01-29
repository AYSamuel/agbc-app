import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../models/recurrence.dart';
import '../config/theme.dart';
import 'custom_dropdown.dart';
import 'custom_input.dart';
import 'custom_date_time_picker.dart';

class RecurrenceOptionsWidget extends StatefulWidget {
  final bool isRecurring;
  final ValueChanged<bool> onRecurringChanged;
  final RecurrenceFrequency frequency;
  final ValueChanged<RecurrenceFrequency> onFrequencyChanged;
  final int interval;
  final ValueChanged<int> onIntervalChanged;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onEndDateChanged;
  final String itemType; // "Task" or "Meeting"

  const RecurrenceOptionsWidget({
    super.key,
    required this.isRecurring,
    required this.onRecurringChanged,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.interval,
    required this.onIntervalChanged,
    this.endDate,
    required this.onEndDateChanged,
    this.itemType = 'Task',
  });

  @override
  State<RecurrenceOptionsWidget> createState() =>
      _RecurrenceOptionsWidgetState();
}

class _RecurrenceOptionsWidgetState extends State<RecurrenceOptionsWidget> {
  late TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    _intervalController =
        TextEditingController(text: widget.interval.toString());
  }

  @override
  void didUpdateWidget(RecurrenceOptionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interval != oldWidget.interval) {
      // Only update text if the value is different and not currently being edited to avoid cursor jumping
      // But since we are passing value back up, we should ensure sync.
      // For simple number input, checking equality is usually enough.
      if (int.tryParse(_intervalController.text) != widget.interval) {
        _intervalController.text = widget.interval.toString();
      }
    }
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  String _getFrequencyLabel(RecurrenceFrequency freq) {
    switch (freq) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
      case RecurrenceFrequency.none:
        return 'None';
    }
  }

  String _getIntervalHint() {
    switch (widget.frequency) {
      case RecurrenceFrequency.daily:
        return widget.interval == 1
            ? 'Repeats every day'
            : 'Repeats every ${widget.interval} days';
      case RecurrenceFrequency.weekly:
        return widget.interval == 1
            ? 'Repeats every week'
            : 'Repeats every ${widget.interval} weeks';
      case RecurrenceFrequency.monthly:
        return widget.interval == 1
            ? 'Repeats every month'
            : 'Repeats every ${widget.interval} months';
      case RecurrenceFrequency.yearly:
        return widget.interval == 1
            ? 'Repeats every year'
            : 'Repeats every ${widget.interval} years';
      case RecurrenceFrequency.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set up this ${widget.itemType.toLowerCase()} to repeat automatically',
          style: GoogleFonts.inter(
            fontSize: 14,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Switch(
              value: widget.isRecurring,
              onChanged: widget.onRecurringChanged,
              activeTrackColor: AppTheme.primary(context),
            ),
            const SizedBox(width: 8),
            Text(
              'Enable Recurring',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (widget.isRecurring) ...[
          const SizedBox(height: 16),
          CustomDropdown<RecurrenceFrequency>(
            label: 'Repeat',
            value: widget.frequency,
            items: RecurrenceFrequency.values
                .where((f) => f != RecurrenceFrequency.none)
                .map((f) => DropdownMenuItem<RecurrenceFrequency>(
                      value: f,
                      child: Text(_getFrequencyLabel(f)),
                    ))
                .toList(),
            onChanged: (freq) {
              if (freq != null) {
                widget.onFrequencyChanged(freq);
              }
            },
            validator: null,
          ),
          const SizedBox(height: 16),
          CustomInput(
            label: 'Every (interval)',
            controller: _intervalController,
            hint: 'e.g., 1',
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final parsed = int.tryParse(val);
              widget.onIntervalChanged(
                  parsed == null || parsed <= 0 ? 1 : parsed);
            },
            validator: (val) {
              final parsed = int.tryParse(val ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Enter a positive number';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            _getIntervalHint(),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ends',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          CustomDateTimePicker(
            key: ValueKey(widget.endDate),
            label: 'End Date',
            value: widget.endDate,
            hintText: 'Never',
            clearable: true,
            onChanged: widget.onEndDateChanged,
            mode: DateTimePickerMode.date,
            validator: (value) {
              return null;
            },
          ),
          const SizedBox(height: 8),
          if (widget.endDate == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Remix.information_line,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.itemType} instances will be created for the next 3 months automatically.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
