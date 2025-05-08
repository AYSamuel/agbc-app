import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? hint;
  final String? label;
  final IconData? prefixIcon;
  final bool isExpanded;
  final TextStyle? style;
  final Color? dropdownColor;
  final String? Function(T?)? validator;
  final bool enabled;
  final String? errorText;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.label,
    this.prefixIcon,
    this.isExpanded = true,
    this.style,
    this.dropdownColor,
    this.validator,
    this.enabled = true,
    this.errorText,
    this.focusNode,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTheme.subtitleStyle.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: enabled
                ? AppTheme.backgroundColor
                : AppTheme.backgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? AppTheme.errorColor
                  : AppTheme.neutralColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    prefixIcon,
                    size: 20,
                    color: enabled
                        ? AppTheme.neutralColor.withValues(alpha: 0.6)
                        : AppTheme.neutralColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
              Expanded(
                child: DropdownButtonFormField<T>(
                  value: value,
                  isExpanded: isExpanded,
                  dropdownColor: dropdownColor ?? AppTheme.cardColor,
                  style: style ??
                      TextStyle(
                        color: enabled
                            ? AppTheme.darkNeutralColor
                            : AppTheme.neutralColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                  hint: hint != null
                      ? Text(
                          hint!,
                          style: TextStyle(
                            color: AppTheme.neutralColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        )
                      : null,
                  items: items,
                  onChanged: enabled ? onChanged : null,
                  validator: validator,
                  focusNode: focusNode,
                  autovalidateMode: autovalidateMode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: enabled
                        ? AppTheme.primaryColor
                        : AppTheme.neutralColor.withValues(alpha: 0.5),
                  ),
                  menuMaxHeight: 300,
                  borderRadius: BorderRadius.circular(12),
                  itemHeight: 48,
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: TextStyle(
              color: AppTheme.errorColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
