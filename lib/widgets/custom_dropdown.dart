import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomDropdown<T> extends StatefulWidget {
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
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    // Remove overlay before disposing to prevent setState on disposed widget
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOpen = false; // Update state without setState since we're disposing
    }
    
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    // Get the render box to determine the width
    final RenderBox? renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    final double dropdownWidth = renderBox?.size.width ?? MediaQuery.of(context).size.width - 32;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: dropdownWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: widget.dropdownColor ?? AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = item.value == widget.value;
                  
                  return InkWell(
                    onTap: () {
                      widget.onChanged?.call(item.value);
                      _removeOverlay();
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: index < widget.items.length - 1
                            ? Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          if (widget.prefixIcon != null) ...[
                            Icon(
                              widget.prefixIcon,
                              size: 16,
                              color: isSelected 
                                  ? AppTheme.primaryColor
                                  : AppTheme.neutralColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: DefaultTextStyle(
                              style: widget.style ??
                                  TextStyle(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.darkNeutralColor,
                                    fontWeight: isSelected 
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 16,
                                  ),
                              child: item.child,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      
      // Only call setState if the widget is still mounted
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      } else {
        // If not mounted, just update the state variable
        _isOpen = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTheme.subtitleStyle.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              key: _dropdownKey,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? AppTheme.backgroundColor
                    : AppTheme.backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.errorText != null
                      ? AppTheme.errorColor
                      : _isOpen
                          ? AppTheme.primaryColor
                          : AppTheme.neutralColor.withValues(alpha: 0.15),
                  width: _isOpen ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: widget.enabled
                            ? AppTheme.neutralColor.withValues(alpha: 0.6)
                            : AppTheme.neutralColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: widget.value != null
                          ? DefaultTextStyle(
                              style: widget.style ??
                                  TextStyle(
                                    color: widget.enabled
                                        ? AppTheme.darkNeutralColor
                                        : AppTheme.neutralColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
                                  ),
                              child: widget.items
                                  .firstWhere((item) => item.value == widget.value)
                                  .child,
                            )
                          : Text(
                              widget.hint ?? '',
                              style: TextStyle(
                                color: AppTheme.neutralColor.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: widget.enabled
                            ? AppTheme.primaryColor
                            : AppTheme.neutralColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(
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
