import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../custom_input.dart';
import '../../services/location_service.dart';
import '../mixins/location_validation_mixin.dart';
import '../loading_indicator.dart';

class LocationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final LocationService locationService;

  const LocationField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.locationService,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField>
    with LocationValidationMixin {
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    initializeLocationValidation(
      controller: widget.controller,
      locationService: widget.locationService,
    );
  }

  @override
  void dispose() {
    disposeLocationValidation();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final result = await widget.locationService.getCurrentLocation();
      if (result != null && !result.startsWith('Error')) {
        setState(() {
          widget.controller.text = result;
        });
      } else if (mounted) {
        _showErrorSnackBar(result ?? 'Error getting location');
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomInput(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryColor),
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      suffixIcon: _isGettingLocation || isValidatingLocation
          ? const SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: LoadingIndicator(color: AppTheme.primaryColor),
              ),
            )
          : SizedBox(
              width: 20,
              height: 20,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.my_location,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                onPressed: _getCurrentLocation,
              ),
            ),
      validator: (value) {
        if (locationError != null) {
          return locationError;
        }
        return widget.validator?.call(value);
      },
    );
  }
}
