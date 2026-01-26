import 'package:flutter/material.dart';
import '../config/theme.dart';

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
  static _CustomDropdownState? _currentlyOpen;
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
  void didUpdateWidget(CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If items have changed while the dropdown is open, close it to avoid RangeError
    // and provide safe UX as the data source has shifted.
    if (_isOpen && widget.items != oldWidget.items) {
      _removeOverlay();
    }
  }

  @override
  void dispose() {
    // Remove overlay before disposing to prevent setState on disposed widget
    if (_overlayEntry != null) {
      _removeOverlay();
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
    // Close any other open dropdown first
    if (_currentlyOpen != null && _currentlyOpen != this) {
      _currentlyOpen?._removeOverlay();
    }
    _currentlyOpen = this;

    _removeOverlay();

    // Get the render box to determine the width
    final RenderBox? renderBox =
        _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    final double dropdownWidth =
        renderBox?.size.width ?? MediaQuery.of(context).size.width - 32;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: dropdownWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: TapRegion(
            groupId: this,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: widget.dropdownColor ??
                      Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1)),
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
                              ? AppTheme.secondary(context)
                                  .withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: index < widget.items.length - 1
                              ? Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.1),
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
                                    ? AppTheme.secondary(context)
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppTheme.secondary(context)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6)),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: DefaultTextStyle(
                                style: widget.style ??
                                    TextStyle(
                                      color: isSelected
                                          ? AppTheme.secondary(context)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                child: item.child,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: AppTheme.secondary(context),
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
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _removeOverlay() {
    if (_currentlyOpen == this) {
      _currentlyOpen = null;
    }

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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary(context),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 8),
        ],
        TapRegion(
          groupId: this,
          onTapOutside: (event) => _removeOverlay(),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: Container(
                key: _dropdownKey,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.errorText != null
                        ? Theme.of(context).colorScheme.error
                        : _isOpen
                            ? AppTheme.secondary(context)
                            : AppTheme.inputBorderColor(context),
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
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
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      letterSpacing: 0.2,
                                    ),
                                child: widget.items
                                    .firstWhere(
                                        (item) => item.value == widget.value)
                                    .child,
                              )
                            : Text(
                                widget.hint ?? '',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
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
                              ? AppTheme.primary(context)
                              : AppTheme.textMuted(context)
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
