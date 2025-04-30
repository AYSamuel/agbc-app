import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<void> initialize() async {
    // Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<String?> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Location permissions are permanently denied';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return formatLocation(place.locality, place.country);
      }
      return null;
    } catch (e) {
      return 'Error getting location: $e';
    }
  }

  String formatLocation(String? city, String? country) {
    return [city, country].where((element) => element != null).join(', ');
  }

  String normalizeLocation(String location) {
    // Trim whitespace
    location = location.trim();

    // Split by common separators
    List<String> parts = location.split(RegExp(r'[,;]'));

    // Clean up each part
    parts = parts.map((part) => part.trim()).toList();

    // Capitalize first letter of each word
    parts = parts
        .map((part) => part
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : '')
            .join(' '))
        .toList();

    // Join with comma and space
    return parts.join(', ');
  }

  Future<LocationResult> validateAndNormalizeLocation(String location) async {
    if (location.isEmpty) {
      return LocationResult(isValid: false, error: 'Please enter a location');
    }

    try {
      // First, try to validate the input as-is
      List<Location> locations = await locationFromAddress(location);

      if (locations.isNotEmpty) {
        // If we found a match with the original input, use it
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locations.first.latitude,
          locations.first.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Only normalize the formatting, not the content
          String formattedLocation = formatLocation(
              place.locality ?? location.split(',')[0].trim(),
              place.country ??
                  (location.split(',').length > 1
                      ? location.split(',')[1].trim()
                      : null));

          return LocationResult(
            isValid: true,
            normalizedLocation: formattedLocation,
            originalInput: location,
          );
        }
      }

      // If direct match fails, try with normalized input
      String normalizedLocation = normalizeLocation(location);
      if (normalizedLocation != location) {
        locations = await locationFromAddress(normalizedLocation);
        if (locations.isNotEmpty) {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            locations.first.latitude,
            locations.first.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String formattedLocation = formatLocation(
                place.locality ?? normalizedLocation.split(',')[0].trim(),
                place.country ??
                    (normalizedLocation.split(',').length > 1
                        ? normalizedLocation.split(',')[1].trim()
                        : null));

            return LocationResult(
              isValid: true,
              normalizedLocation: formattedLocation,
              originalInput: location,
            );
          }
        }
      }

      // If we still can't find a match, check if it's a known location format
      if (location.contains(',')) {
        // For locations with city,country format, accept them as valid
        return LocationResult(
          isValid: true,
          normalizedLocation:
              normalizeLocation(location), // Just normalize the formatting
          originalInput: location,
        );
      }

      return LocationResult(
          isValid: false,
          error: 'Invalid location. Please enter a valid city and country');
    } catch (e) {
      // If geocoding fails but the input looks like a valid location format, accept it
      if (location.contains(',')) {
        return LocationResult(
          isValid: true,
          normalizedLocation:
              normalizeLocation(location), // Just normalize the formatting
          originalInput: location,
        );
      }
      return LocationResult(
          isValid: false, error: 'Error validating location: $e');
    }
  }
}

class LocationResult {
  final bool isValid;
  final String? normalizedLocation;
  final String? originalInput;
  final String? error;

  LocationResult({
    required this.isValid,
    this.normalizedLocation,
    this.originalInput,
    this.error,
  });
}
