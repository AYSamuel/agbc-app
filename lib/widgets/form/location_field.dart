import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/theme.dart';
import '../custom_input.dart';
import '../mixins/location_validation_mixin.dart';

class LocationField extends StatefulWidget {
  final Map<String, String> initialLocation;
  final Function(Map<String, String>) onLocationChanged;
  final String? Function(Map<String, String>)? validator;
  final bool enableGeocoding;
  final bool showSuggestions;

  const LocationField({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
    this.validator,
    this.enableGeocoding = true,
    this.showSuggestions = true,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField>
    with LocationValidationMixin {
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  String? _errorMessage;
  bool _isValidating = false;
  Timer? _debounceTimer;
  List<Map<String, String>> _suggestions = [];
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _cityController =
        TextEditingController(text: widget.initialLocation['city'] ?? '');
    _countryController =
        TextEditingController(text: widget.initialLocation['country'] ?? '');

    // Listen to changes and notify parent
    _cityController.addListener(_onCityChanged);
    _countryController.addListener(_onCountryChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    _cityController.dispose();
    _countryController.dispose();
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
      if (widget.showSuggestions) {
        _getSuggestions();
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

  Future<void> _getSuggestions() async {
    final city = _cityController.text.trim();
    final country = _countryController.text.trim();

    if (city.length < 2) {
      _hideSuggestions();
      return;
    }

    try {
      final query = country.isNotEmpty ? '$city, $country' : city;
      final suggestions = await getLocationSuggestions(query);

      if (mounted && suggestions.isNotEmpty) {
        setState(() {
          _suggestions = suggestions;
        });
        _showSuggestionsOverlay();
      } else {
        _hideSuggestions();
      }
    } catch (e) {
      _hideSuggestions();
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8, // Increased elevation
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return InkWell(
                    onTap: () => _selectSuggestion(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: index < _suggestions.length - 1
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
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion['display'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
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
      _showSuggestions = true;
    });
  }

  void _selectSuggestion(Map<String, String> suggestion) {
    _cityController.text = suggestion['city'] ?? '';
    _countryController.text = suggestion['country'] ?? '';
    _hideSuggestions();
    _onLocationChanged();
  }

  void _hideSuggestions() {
    _removeOverlay();
    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City Field
          CustomInput(
            label: 'City',
            controller: _cityController,
            hint: 'Enter your city',
            prefixIcon: Icon(Icons.location_city, color: AppTheme.primaryColor),
            suffixIcon: _isValidating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            textInputAction: TextInputAction.next,
            onTap: () {
              if (_showSuggestions) {
                _hideSuggestions();
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'City is required';
              }
              return validateCityInput(value, country: _countryController.text);
            },
          ),

          const SizedBox(height: 16),

          // Country Field with Autocomplete
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return getCommonCountries();
              }
              return filterCountries(textEditingValue.text);
            },
            onSelected: (String selection) {
              _countryController.text = selection;
              _onCountryChanged();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              // Sync with our controller
              if (controller.text != _countryController.text) {
                controller.text = _countryController.text;
              }

              return CustomInput(
                label: 'Country',
                controller: controller,
                focusNode: focusNode,
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
                          leading: const Icon(Icons.public, size: 16),
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => onSelected(option),
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
      ),
    );
  }
}
