import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/location_service.dart';

/// A mixin that provides location validation functionality for widgets.
mixin LocationValidationMixin<T extends StatefulWidget> on State<T> {
  bool _isValidatingLocation = false;
  String? _locationError;
  Timer? _debounce;
  late final TextEditingController _controller;
  late final LocationService? _locationService;

  /// Initialize the location validation mixin with required dependencies.
  void initializeLocationValidation({
    required TextEditingController controller,
    required LocationService? locationService,
  }) {
    _controller = controller;
    _locationService = locationService;
    _controller.addListener(_handleTextChange);
  }

  /// Clean up resources when the widget is disposed.
  void disposeLocationValidation() {
    _controller.removeListener(_handleTextChange);
    _debounce?.cancel();
  }

  /// Get the current validation state.
  bool get isValidatingLocation => _isValidatingLocation;

  /// Get the current location error, if any.
  String? get locationError => _locationError;

  void _handleTextChange() {
    if (_locationService != null) {
      _debounceLocationValidation();
    }
  }

  void _debounceLocationValidation() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (_controller.text.isNotEmpty) {
        _validateLocation(_controller.text.trim());
      } else {
        setState(() => _locationError = null);
      }
    });
  }

  Future<void> _validateLocation(String location) async {
    if (!mounted) return;

    setState(() => _isValidatingLocation = true);

    try {
      final result =
          await _locationService!.validateAndNormalizeLocation(location);

      if (!mounted) return;

      if (result.isValid && result.normalizedLocation != null) {
        _updateLocationIfNeeded(result.normalizedLocation!, location);
        setState(() => _locationError = null);
      } else {
        setState(() => _locationError = result.error ?? 'Invalid location');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = 'Error validating location');
    } finally {
      if (mounted) {
        setState(() => _isValidatingLocation = false);
      }
    }
  }

  void _updateLocationIfNeeded(
      String normalizedLocation, String currentLocation) {
    if (normalizedLocation != _controller.text &&
        currentLocation == _controller.text.trim()) {
      _controller.text = normalizedLocation;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }
}
