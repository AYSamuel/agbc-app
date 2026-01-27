import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../config/theme.dart';
import '../custom_input.dart';
import '../mixins/location_validation_mixin.dart';
import 'dart:async';

class LocationField extends StatefulWidget {
  final Function(Map<String, String>) onLocationChanged;
  final String? Function(Map<String, String>)? validator;
  final bool enableGeocoding;
  final bool showSuggestions;
  final Map<String, String>? initialLocation;

  const LocationField({
    super.key,
    required this.onLocationChanged,
    this.validator,
    this.enableGeocoding = true,
    this.showSuggestions = true,
    this.initialLocation,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField>
    with LocationValidationMixin {
  late TextEditingController _cityController;
  late TextEditingController _countryController;

  Timer? _debounceTimer;
  String? _errorMessage;
  bool _isValidating = false;
  bool _isLoadingSuggestions = false;
  FocusNode? _trackedFocusNode;
  VoidCallback? _focusListener;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(
      text: widget.initialLocation?['city'] ?? '',
    );
    _countryController = TextEditingController(
      text: widget.initialLocation?['country'] ?? '',
    );
  }

  @override
  void dispose() {
    // Cancel any pending timer first
    _debounceTimer?.cancel();

    // Remove focus listener if exists
    if (_trackedFocusNode != null && _focusListener != null) {
      _trackedFocusNode!.removeListener(_focusListener!);
    }

    // Dispose controllers
    _cityController.dispose();
    _countryController.dispose();

    super.dispose();
  }

  void _onCityChanged() {
    _debounceValidation();
    _onLocationChanged();
  }

  void _debounceValidation() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (widget.enableGeocoding) {
        _validateWithGeocoding();
      }
    });
  }

  Future<void> _validateWithGeocoding() async {
    final city = _cityController.text.trim();
    final country = _countryController.text.trim();

    if (city.isEmpty || country.isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    try {
      final location = {'city': city, 'country': country};
      final error = await validateLocationMapAsync(location);

      if (mounted) {
        setState(() {
          _errorMessage = error;
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error validating location';
          _isValidating = false;
        });
      }
    }
  }

  void _onLocationChanged() {
    final location = {
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
    };

    // Basic validation (synchronous)
    if (!widget.enableGeocoding) {
      final error =
          widget.validator?.call(location) ?? validateLocationMap(location);
      setState(() {
        _errorMessage = error;
      });
    }

    // Notify parent
    widget.onLocationChanged(location);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // City Field with Autocomplete
        Autocomplete<Map<String, String>>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            // Only show options if has sufficient text
            if (textEditingValue.text.length < 2) {
              // Schedule setState after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isLoadingSuggestions) {
                  setState(() {
                    _isLoadingSuggestions = false;
                  });
                }
              });
              return const Iterable<Map<String, String>>.empty();
            }

            // Set loading state after build completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isLoadingSuggestions) {
                setState(() {
                  _isLoadingSuggestions = true;
                });
              }
            });

            try {
              final query = _countryController.text.isNotEmpty
                  ? '${textEditingValue.text}, ${_countryController.text}'
                  : textEditingValue.text;
              final suggestions = await getLocationSuggestions(query);

              // Schedule setState after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isLoadingSuggestions) {
                  setState(() {
                    _isLoadingSuggestions = false;
                  });
                }
              });

              return suggestions;
            } catch (e) {
              // Schedule setState after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isLoadingSuggestions) {
                  setState(() {
                    _isLoadingSuggestions = false;
                  });
                }
              });
              return const Iterable<Map<String, String>>.empty();
            }
          },
          displayStringForOption: (Map<String, String> option) =>
              option['city'] ?? '',
          onSelected: (Map<String, String> selection) {
            setState(() {
              _cityController.text = selection['city'] ?? '';
              if (selection['country']?.isNotEmpty == true) {
                _countryController.text = selection['country'] ?? '';
              }
              _isLoadingSuggestions = false; // Reset loading state
            });
            _onLocationChanged();

            // Dismiss keyboard and remove focus after selection
            FocusScope.of(context).unfocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Sync autocomplete controller with our city controller after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (controller.text != _cityController.text) {
                controller.text = _cityController.text;
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
              }
            });

            // Add focus listener only once per focus node
            if (_trackedFocusNode != focusNode) {
              // Remove old listener if exists
              if (_trackedFocusNode != null && _focusListener != null) {
                _trackedFocusNode!.removeListener(_focusListener!);
              }

              // Create new listener
              _focusListener = () {
                if (!focusNode.hasFocus && _isLoadingSuggestions) {
                  // Field lost focus, clear loading state
                  setState(() {
                    _isLoadingSuggestions = false;
                  });
                }
              };

              // Add listener to new focus node
              focusNode.addListener(_focusListener!);
              _trackedFocusNode = focusNode;
            }

            return CustomInput(
              label: 'City',
              controller: controller,
              focusNode:
                  focusNode, // Use the autocomplete's provided focus node
              hint: 'Start typing for suggestions...',
              prefixIcon: const Icon(Remix.community_line),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                _cityController.text = value;
                // Clear country when user manually edits city
                // This ensures country is only filled when user selects from dropdown
                if (_countryController.text.isNotEmpty) {
                  setState(() {
                    _countryController.text = '';
                    _errorMessage = null; // Clear any validation errors
                  });
                }
                _onCityChanged();
              },
              validator: (String? value) {
                // Use custom validator if provided, otherwise use default
                if (widget.validator != null) {
                  final locationMap = {
                    'city': _cityController.text,
                    'country': _countryController.text,
                  };
                  return widget.validator!(locationMap);
                }

                // Default validation: ensure city is not empty
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your city';
                }
                return null;
              },
              errorText: _errorMessage,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final screenHeight = MediaQuery.of(context).size.height;
            final maxHeight = screenHeight * 0.3; // 30% of screen height, max

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: MediaQuery.of(context).size.width - 32,
                  constraints: BoxConstraints(
                    maxHeight: maxHeight.clamp(150.0, 250.0),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.1)),
                  ),
                  child: _isLoadingSuggestions && options.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.primary(context),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Searching for cities...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : options.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Remix.search_eye_line,
                                      size: 32,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No cities found',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Remix.community_line,
                                    size: 16,
                                    color: AppTheme.primary(context),
                                  ),
                                  title: Text(
                                    option['city'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle:
                                      option['country']?.isNotEmpty == true
                                          ? Text(
                                              option['country']!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            )
                                          : null,
                                  onTap: () => onSelected(option),
                                  hoverColor: AppTheme.primary(context)
                                      .withValues(alpha: 0.05),
                                  splashColor: AppTheme.primary(context)
                                      .withValues(alpha: 0.1),
                                );
                              },
                            ),
                ),
              ),
            );
          },
        ),

        // Helper text for autocomplete
        if (_cityController.text.isEmpty ||
            (_cityController.text.isNotEmpty &&
                _cityController.text.length < 2 &&
                !_isLoadingSuggestions)) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Remix.information_line,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Type at least 2 characters to see city suggestions',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],

        // Loading suggestions indicator (alternative position)
        if (_isLoadingSuggestions &&
            _cityController.text.length >= 2 &&
            !_isValidating) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Searching for cities...',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // Country Field (Read-only, auto-filled from city selection)
        CustomInput(
          label: 'Country',
          controller: _countryController,
          hint: 'Select a city to auto-fill country',
          prefixIcon: const Icon(Remix.global_line),
          enabled: false,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select a city from the suggestions above';
            }
            return null;
          },
        ),

        // Validation Status
        if (_isValidating) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Validating location...',
                style: TextStyle(
                  color: AppTheme.primary(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],

        // Show validation error if any
        if (_errorMessage != null && !_isValidating) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Remix.error_warning_line,
                color: AppTheme.error(context),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Please select a valid city from the suggestions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.error(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Success indicator
        if (_errorMessage == null &&
            !_isValidating &&
            _cityController.text.isNotEmpty &&
            _countryController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Icon(
            Remix.checkbox_circle_line,
            color: AppTheme.success(context),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Location verified',
            style: TextStyle(
              color: AppTheme.success(context),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
