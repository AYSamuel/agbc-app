import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;
  final double borderRadius;
  final double elevation;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.borderRadius = 12.0,
    this.elevation = 2.0,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.neutralColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Focus(
          onFocusChange: (focused) {
            setState(() {
              isFocused = focused;
            });
          },
          child: DropdownButtonFormField<T>(
            value: widget.value,
            items: widget.items,
            onChanged: widget.enabled ? widget.onChanged : null,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: widget.value == null
                    ? AppTheme.neutralColor.withValues(alpha: 0.6)
                    : AppTheme.neutralColor.withValues(alpha: 0.4),
                fontWeight: FontWeight.w400,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
              errorStyle: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child:
                          Icon(widget.prefixIcon, color: AppTheme.primaryColor),
                    )
                  : null,
              suffixIcon: widget.value != null
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isFocused
                            ? AppTheme.primaryColor
                            : AppTheme.neutralColor.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      onPressed: () {
                        if (widget.onChanged != null) {
                          widget.onChanged!(null);
                        }
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: AppTheme.neutralColor.withAlpha((0.15 * 255).toInt()),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: AppTheme.neutralColor.withAlpha((0.15 * 255).toInt()),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: AppTheme.errorColor,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              isDense: true,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: widget.value == null
                  ? AppTheme.neutralColor.withValues(alpha: 0.6)
                  : (widget.enabled
                      ? AppTheme.darkNeutralColor
                      : AppTheme.neutralColor.withValues(alpha: 0.5)),
              fontWeight: FontWeight.w500,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
            validator: widget.validator,
            dropdownColor: AppTheme.cardColor,
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppTheme.primaryColor,
            ),
            isExpanded: true,
            menuMaxHeight: 300,
            isDense: true,
            elevation: widget.elevation.toInt(),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            hint: Text(
              widget.hint ?? '',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.neutralColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
