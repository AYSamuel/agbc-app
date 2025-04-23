import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomDropdown<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
            errorStyle: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(prefixIcon, color: AppTheme.neutralColor),
                  )
                : null,
            suffixIcon: value != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      if (onChanged != null) {
                        onChanged!(null);
                      }
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.blue[700]!,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.red[700]!,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            isDense: true,
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          validator: validator,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            color: AppTheme.neutralColor,
          ),
          isExpanded: true,
        ),
      ],
    );
  }
} 