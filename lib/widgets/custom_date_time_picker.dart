import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../utils/focus_helper.dart';

enum DateTimePickerMode {
  date,
  time,
  dateAndTime,
}

class CustomDateTimePicker extends FormField<DateTime> {
  CustomDateTimePicker({
    super.key,
    required String label,
    DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    DateTimePickerMode mode = DateTimePickerMode.dateAndTime,
    String? hintText,
    IconData? prefixIcon,
    super.validator,
    DateTime? firstDate,
    DateTime? lastDate,
    bool clearable = true,
  }) : super(
          initialValue: value,
          builder: (FormFieldState<DateTime> state) {
            // If the user passes a value that is different from the state value,
            // we should probably respect the external value if we want it controlled.
            // But FormField is designed to hold its own state.
            // For now, we rely on the key hack or just just mapping.
            return _CustomDateTimePickerField(
              label: label,
              value: state.value,
              onChanged: (newValue) {
                state.didChange(newValue);
                onChanged(newValue);
              },
              mode: mode,
              hintText: hintText,
              prefixIcon: prefixIcon,
              errorText: state.errorText,
              firstDate: firstDate,
              lastDate: lastDate,
              clearable: clearable,
            );
          },
        );
}

class _CustomDateTimePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTimePickerMode mode;
  final String? hintText;
  final IconData? prefixIcon;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool clearable;

  const _CustomDateTimePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.mode,
    this.hintText,
    this.prefixIcon,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.clearable = true,
  });

  void _pickDateTime(BuildContext context) {
    // Dismiss keyboard
    FocusHelper.unfocus(context);
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        DateTime tempPickedDate = value ?? DateTime.now();

        // Ensure within bounds
        if (firstDate != null && tempPickedDate.isBefore(firstDate!)) {
          tempPickedDate = firstDate!;
        }
        if (lastDate != null && tempPickedDate.isAfter(lastDate!)) {
          tempPickedDate = lastDate!;
        }

        return Container(
          height: 350,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.textMuted(context).withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Text(
                      label.isNotEmpty ? label : 'Select Date',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onChanged(tempPickedDate);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Key feature: Cupertino Picker
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: GoogleFonts.inter(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: _getCupertinoMode(),
                    initialDateTime: tempPickedDate,
                    minimumDate: firstDate,
                    maximumDate: lastDate,
                    use24hFormat: false,
                    onDateTimeChanged: (DateTime newDate) {
                      tempPickedDate = newDate;
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  CupertinoDatePickerMode _getCupertinoMode() {
    switch (mode) {
      case DateTimePickerMode.date:
        return CupertinoDatePickerMode.date;
      case DateTimePickerMode.time:
        return CupertinoDatePickerMode.time;
      case DateTimePickerMode.dateAndTime:
        return CupertinoDatePickerMode.dateAndTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = _getDisplayText();
    final hasValue = value != null;
    final isError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: () => _pickDateTime(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isError
                    ? AppTheme.error(context)
                    : AppTheme.textMuted(context).withValues(alpha: 0.15),
                width: isError ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(
                    prefixIcon,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: hasValue
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (clearable && hasValue)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onChanged(null);
                    },
                  ),
              ],
            ),
          ),
        ),
        if (isError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              color: AppTheme.error(context),
              fontWeight: FontWeight.w500,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }

  String _getDisplayText() {
    if (value == null) {
      return hintText ?? _getDefaultHint();
    }

    switch (mode) {
      case DateTimePickerMode.date:
        return DateFormat('MMM dd, yyyy').format(value!);
      case DateTimePickerMode.time:
        return DateFormat('h:mm a').format(value!);
      case DateTimePickerMode.dateAndTime:
        return DateFormat('MMM dd, yyyy • h:mm a').format(value!);
    }
  }

  String _getDefaultHint() {
    switch (mode) {
      case DateTimePickerMode.date:
        return 'Select date';
      case DateTimePickerMode.time:
        return 'Select time';
      case DateTimePickerMode.dateAndTime:
        return 'Select date and time';
    }
  }
}
