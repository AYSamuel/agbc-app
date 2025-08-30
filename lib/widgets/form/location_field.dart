import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../custom_input.dart';
import '../mixins/location_validation_mixin.dart';
import 'dart:async';

class LocationField extends StatefulWidget {
  final Function(Map<String, String>) onLocationChanged;
  final String? Function(Map<String, String>)? validator;
  final bool enableGeocoding;
  final bool showSuggestions;
  final Map<String, String>? initialLocation;
  final GlobalKey<FormState>? formKey;

  const LocationField({
    super.key,
    required this.onLocationChanged,
    this.validator,
    this.enableGeocoding = true,
    this.showSuggestions = true,
    this.initialLocation,
    this.formKey,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField>
    with LocationValidationMixin {
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late FocusNode _countryFocusNode;

  Timer? _debounceTimer;
  String? _errorMessage;
  bool _isValidating = false;

  // Remove the custom city focus node and listener since we'll use the autocomplete's focus node
  // late FocusNode _cityFocusNode;
  // late VoidCallback _cityFocusListener;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(
      text: widget.initialLocation?['city'] ?? '',
    );
    _countryController = TextEditingController(
      text: widget.initialLocation?['country'] ?? '',
    );
    // Only initialize country focus node
    _countryFocusNode = FocusNode();

    // Remove city focus listener setup since we'll handle focus differently
  }

  @override
  void dispose() {
    // Cancel any pending timer first
    _debounceTimer?.cancel();
    
    // Dispose controllers and focus nodes
    _cityController.dispose();
    _countryController.dispose();
    _countryFocusNode.dispose();
    
    super.dispose();
  }

  void _onCityChanged() {
    _debounceValidation();
    _onLocationChanged();
  }

  void _onCountryChanged() {
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

        // Trigger form validation after async validation completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Always trigger validation after async validation completes
          if (widget.formKey != null) {
            widget.formKey!.currentState!.validate();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error validating location';
          _isValidating = false;
        });

        // Also trigger validation on error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.formKey != null) {
            widget.formKey!.currentState!.validate();
          }
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
            // Only show options if has sufficient text (remove focus check since we'll use the autocomplete's focus)
            if (textEditingValue.text.length < 2) {
              return const Iterable<Map<String, String>>.empty();
            }

            try {
              final query = _countryController.text.isNotEmpty
                  ? '${textEditingValue.text}, ${_countryController.text}'
                  : textEditingValue.text;
              final suggestions = await getLocationSuggestions(query);
              return suggestions;
            } catch (e) {
              return const Iterable<Map<String, String>>.empty();
            }
          },
          displayStringForOption: (Map<String, String> option) =>
              option['city'] ?? '',
          onSelected: (Map<String, String> selection) {
            _cityController.text = selection['city'] ?? '';
            if (selection['country']?.isNotEmpty == true) {
              _countryController.text = selection['country'] ?? '';
            }
            _onLocationChanged();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Use a post-frame callback to sync controllers safely
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (controller.text != _cityController.text) {
                controller.text = _cityController.text;
              }
            });

            // Add focus listener for validation when field loses focus
            focusNode.addListener(() {
              if (!focusNode.hasFocus) {
                // City field lost focus, trigger validation immediately
                final city = _cityController.text.trim();
                final country = _countryController.text.trim();

                if (city.isNotEmpty && country.isNotEmpty && widget.enableGeocoding) {
                  // Cancel any pending debounced validation
                  _debounceTimer?.cancel();
                  // Trigger immediate validation
                  _validateWithGeocoding();
                }
              }
            });

            return CustomInput(
              label: 'City',
              controller: controller,
              focusNode: focusNode, // Use the autocomplete's provided focus node
              hint: 'Enter your city',
              prefixIcon: Icon(Icons.location_city, color: AppTheme.primaryColor),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                _cityController.text = value;
                _onCityChanged();
              },
              validator: widget.validator != null 
                  ? (String? value) {
                      // Convert the string value to a map for the LocationField validator
                      final locationMap = {
                        'city': _cityController.text,
                        'country': _countryController.text,
                      };
                      return widget.validator!(locationMap);
                    }
                  : null,
              errorText: _errorMessage,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: MediaQuery.of(context).size.width - 32,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_city,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(
                          option['city'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: option['country']?.isNotEmpty == true
                            ? Text(
                                option['country']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : null,
                        onTap: () => onSelected(option),
                        hoverColor: Colors.grey.shade100,
                        splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Country Field with Autocomplete
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            // Only show options if the field is focused and has text, or if it's focused and empty
            if (!_countryFocusNode.hasFocus) {
              return const Iterable<String>.empty();
            }
            if (textEditingValue.text.isEmpty) {
              return getCommonCountries();
            }
            return filterCountries(textEditingValue.text);
          },
          onSelected: (String selection) {
            _countryController.text = selection;
            _onCountryChanged();
            // Unfocus the country field after selection
            _countryFocusNode.unfocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Use a post-frame callback to sync controllers safely
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (controller.text != _countryController.text) {
                controller.text = _countryController.text;
              }
            });

            return CustomInput(
              label: 'Country',
              controller: controller,
              focusNode: _countryFocusNode, // Use our own focus node instead of the provided one
              hint: 'Enter your country',
              prefixIcon: Icon(Icons.public, color: AppTheme.primaryColor),
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                _countryController.text = value;
                _onCountryChanged();
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Country is required';
                }
                return validateCountryInput(value);
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: MediaQuery.of(context).size.width - 32,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.public,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => onSelected(option),
                        hoverColor: Colors.grey.shade100,
                        splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      );
                    },
                  ),
                ),
              ),
            );
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
                  color: AppTheme.primaryColor,
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
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 12,
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
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Location verified',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
