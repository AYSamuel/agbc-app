import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

/// A mixin for validating city/country location data with real geocoding verification.
/// This mixin provides comprehensive validation methods for location input
/// in the format of city and country, compatible with JSONB storage.
mixin LocationValidationMixin {
  /// Validates a complete location map containing city and country
  /// Includes real location verification using geocoding
  Future<String?> validateLocationMapAsync(
      Map<String, String>? locationData) async {
    if (locationData == null || locationData.isEmpty) {
      return 'Please enter your location';
    }

    final city = locationData['city']?.trim();
    final country = locationData['country']?.trim();

    if (city == null || city.isEmpty) {
      return 'Please enter your city';
    }

    if (country == null || country.isEmpty) {
      return 'Please enter your country';
    }

    // Validate country first
    final countryError = validateCountryInput(country);
    if (countryError != null) {
      return countryError;
    }

    // Validate city format
    final cityFormatError = _validateCityFormat(city);
    if (cityFormatError != null) {
      return cityFormatError;
    }

    // Check if country exists in our database
    if (!_isValidCountry(country)) {
      return 'Please enter a valid country name';
    }

    // Real geocoding validation
    try {
      final isValid = await _validateLocationWithGeocoding(city, country);
      if (!isValid) {
        return 'Location not found. Please check the city and country names.';
      }
    } catch (e) {
      // If geocoding fails, fall back to basic validation
      debugPrint('Geocoding validation failed: $e');
      if (!_isPlausibleCityName(city)) {
        return 'Please enter a valid city name';
      }
    }

    return null;
  }

  /// Synchronous validation (without geocoding) for immediate feedback
  String? validateLocationMap(Map<String, String>? locationData) {
    if (locationData == null || locationData.isEmpty) {
      return 'Please enter your location';
    }

    final city = locationData['city']?.trim();
    final country = locationData['country']?.trim();

    if (city == null || city.isEmpty) {
      return 'Please enter your city';
    }

    if (country == null || country.isEmpty) {
      return 'Please enter your country';
    }

    // Validate country first
    final countryError = validateCountryInput(country);
    if (countryError != null) {
      return countryError;
    }

    // Validate city format
    final cityFormatError = _validateCityFormat(city);
    if (cityFormatError != null) {
      return cityFormatError;
    }

    // Check if country exists in our database
    if (!_isValidCountry(country)) {
      return 'Please enter a valid country name';
    }

    // Basic plausibility check
    if (!_isPlausibleCityName(city)) {
      return 'Please enter a valid city name';
    }

    return null;
  }

  /// Validates individual city input with optional geocoding
  Future<String?> validateCityInputAsync(String? value,
      {String? country}) async {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your city';
    }

    final trimmedValue = value.trim();

    // Format validation
    final formatError = _validateCityFormat(trimmedValue);
    if (formatError != null) {
      return formatError;
    }

    // If country is provided, do geocoding validation
    if (country != null && country.trim().isNotEmpty) {
      if (!_isValidCountry(country.trim())) {
        return 'Please select a valid country first';
      }

      try {
        final isValid =
            await _validateLocationWithGeocoding(trimmedValue, country);
        if (!isValid) {
          return 'City not found in $country. Please check the spelling.';
        }
      } catch (e) {
        debugPrint('Geocoding validation failed: $e');
        // Fall back to basic validation
        if (!_isPlausibleCityName(trimmedValue)) {
          return 'Please enter a valid city name';
        }
      }
    } else {
      // Basic validation without country context
      if (!_isPlausibleCityName(trimmedValue)) {
        return 'Please enter a valid city name';
      }
    }

    return null;
  }

  /// Synchronous city validation
  String? validateCityInput(String? value, {String? country}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your city';
    }

    final trimmedValue = value.trim();

    // Format validation
    final formatError = _validateCityFormat(trimmedValue);
    if (formatError != null) {
      return formatError;
    }

    // Basic plausibility check
    if (!_isPlausibleCityName(trimmedValue)) {
      return 'Please enter a valid city name';
    }

    return null;
  }

  /// Validates location using geocoding service
  Future<bool> _validateLocationWithGeocoding(
      String city, String country) async {
    try {
      // Try to geocode the location
      final query = '$city, $country';
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        return false;
      }

      // Verify the result by reverse geocoding
      final firstLocation = locations.first;
      final placemarks = await placemarkFromCoordinates(
        firstLocation.latitude,
        firstLocation.longitude,
      );

      if (placemarks.isEmpty) {
        return false;
      }

      final placemark = placemarks.first;

      // Check if the returned location matches our input
      final returnedCountry = placemark.country?.toLowerCase() ?? '';
      final returnedCity = placemark.locality?.toLowerCase() ??
          placemark.subAdministrativeArea?.toLowerCase() ??
          placemark.administrativeArea?.toLowerCase() ??
          '';

      final inputCountry = country.toLowerCase();
      final inputCity = city.toLowerCase();

      // Flexible matching - check if country matches and city is reasonable
      final countryMatches = _countryNamesMatch(returnedCountry, inputCountry);
      final cityMatches = returnedCity.contains(inputCity) ||
          inputCity.contains(returnedCity) ||
          _areSimilarCityNames(returnedCity, inputCity);

      return countryMatches && (cityMatches || returnedCity.isNotEmpty);
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return false;
    }
  }

  /// Checks if two country names refer to the same country
  bool _countryNamesMatch(String country1, String country2) {
    if (country1 == country2) return true;

    // Handle common variations
    final variations = _getCountryVariations();
    final normalized1 = variations[country1] ?? country1;
    final normalized2 = variations[country2] ?? country2;

    return normalized1.toLowerCase() == normalized2.toLowerCase();
  }

  /// Checks if two city names are similar (handles minor spelling differences)
  bool _areSimilarCityNames(String city1, String city2) {
    if (city1.isEmpty || city2.isEmpty) return false;

    // Simple similarity check - at least 70% character overlap
    final longer = city1.length > city2.length ? city1 : city2;
    final shorter = city1.length <= city2.length ? city1 : city2;

    if (shorter.length < 3) return longer == shorter;

    int matches = 0;
    for (int i = 0; i < shorter.length; i++) {
      if (i < longer.length && shorter[i] == longer[i]) {
        matches++;
      }
    }

    return (matches / shorter.length) >= 0.7;
  }

  /// Gets location suggestions using geocoding
  Future<List<Map<String, String>>> getLocationSuggestions(String query) async {
    if (query.trim().length < 3) {
      return [];
    }

    try {
      final locations = await locationFromAddress(query);
      final suggestions = <Map<String, String>>[];

      for (final location in locations.take(5)) {
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            final city = placemark.locality ??
                placemark.subAdministrativeArea ??
                placemark.administrativeArea ??
                '';
            final country = placemark.country ?? '';

            if (city.isNotEmpty && country.isNotEmpty) {
              suggestions.add({
                'city': city,
                'country': country,
                'display': '$city, $country',
              });
            }
          }
        } catch (e) {
          debugPrint('Error processing location suggestion: $e');
        }
      }

      return suggestions;
    } catch (e) {
      debugPrint('Error getting location suggestions: $e');
      return [];
    }
  }

  /// Validates individual country input with real country checking
  String? validateCountryInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your country';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Country name must be at least 2 characters';
    }

    if (trimmedValue.length > 50) {
      return 'Country name must be less than 50 characters';
    }

    if (!_isValidLocationName(trimmedValue)) {
      return 'Please enter a valid country name (letters, spaces, hyphens, apostrophes only)';
    }

    // Check if it's a real country
    if (!_isValidCountry(trimmedValue)) {
      return 'Please enter a valid country name';
    }

    return null;
  }

  /// Format validation for city names
  String? _validateCityFormat(String city) {
    if (city.length < 2) {
      return 'City name must be at least 2 characters';
    }

    if (city.length > 50) {
      return 'City name must be less than 50 characters';
    }

    if (!_isValidLocationName(city)) {
      return 'Please enter a valid city name (letters, spaces, hyphens, apostrophes only)';
    }

    return null;
  }

  /// Checks if a country name is valid by comparing against known countries
  bool _isValidCountry(String country) {
    final normalizedCountry = country.toLowerCase().trim();
    final validCountries =
        _getAllCountries().map((c) => c.toLowerCase()).toSet();

    // Direct match
    if (validCountries.contains(normalizedCountry)) {
      return true;
    }

    // Check for common variations and abbreviations
    final countryVariations = _getCountryVariations();
    return countryVariations.containsKey(normalizedCountry);
  }

  /// Basic plausibility check for city names
  bool _isPlausibleCityName(String city) {
    final normalizedCity = city.toLowerCase().trim();

    // Check against obviously invalid patterns
    if (_isObviouslyInvalidCity(normalizedCity)) {
      return false;
    }

    // Check against known major cities (this is a basic implementation)
    return _isKnownCityOrPlausible(normalizedCity);
  }

  /// Checks for obviously invalid city patterns
  bool _isObviouslyInvalidCity(String city) {
    // Cities that are clearly not real
    final invalidPatterns = [
      'test',
      'example',
      'sample',
      'dummy',
      'fake',
      'invalid',
      'asdf',
      'qwerty',
      '123',
      'abc',
      'xyz',
      'none',
      'null',
      'undefined',
      'unknown',
      'n/a',
      'na',
      'tbd',
      'temp'
    ];

    return invalidPatterns.any((pattern) => city.contains(pattern));
  }

  /// Basic check for known cities or plausible city names
  bool _isKnownCityOrPlausible(String city) {
    if (city.length < 2 || city.length > 50) {
      return false;
    }

    // Cities shouldn't contain numbers (with rare exceptions)
    if (RegExp(r'\d').hasMatch(city)) {
      return false;
    }

    // Should contain only valid characters
    return _isValidLocationName(city);
  }

  /// Gets all valid countries
  List<String> _getAllCountries() {
    return [
      'Afghanistan',
      'Albania',
      'Algeria',
      'Andorra',
      'Angola',
      'Argentina',
      'Armenia',
      'Australia',
      'Austria',
      'Azerbaijan',
      'Bahamas',
      'Bahrain',
      'Bangladesh',
      'Barbados',
      'Belarus',
      'Belgium',
      'Belize',
      'Benin',
      'Bhutan',
      'Bolivia',
      'Bosnia and Herzegovina',
      'Botswana',
      'Brazil',
      'Brunei',
      'Bulgaria',
      'Burkina Faso',
      'Burundi',
      'Cambodia',
      'Cameroon',
      'Canada',
      'Cape Verde',
      'Central African Republic',
      'Chad',
      'Chile',
      'China',
      'Colombia',
      'Comoros',
      'Congo',
      'Costa Rica',
      'Croatia',
      'Cuba',
      'Cyprus',
      'Czech Republic',
      'Denmark',
      'Djibouti',
      'Dominica',
      'Dominican Republic',
      'Ecuador',
      'Egypt',
      'El Salvador',
      'Equatorial Guinea',
      'Eritrea',
      'Estonia',
      'Ethiopia',
      'Fiji',
      'Finland',
      'France',
      'Gabon',
      'Gambia',
      'Georgia',
      'Germany',
      'Ghana',
      'Greece',
      'Grenada',
      'Guatemala',
      'Guinea',
      'Guinea-Bissau',
      'Guyana',
      'Haiti',
      'Honduras',
      'Hungary',
      'Iceland',
      'India',
      'Indonesia',
      'Iran',
      'Iraq',
      'Ireland',
      'Israel',
      'Italy',
      'Jamaica',
      'Japan',
      'Jordan',
      'Kazakhstan',
      'Kenya',
      'Kiribati',
      'Kuwait',
      'Kyrgyzstan',
      'Laos',
      'Latvia',
      'Lebanon',
      'Lesotho',
      'Liberia',
      'Libya',
      'Liechtenstein',
      'Lithuania',
      'Luxembourg',
      'Madagascar',
      'Malawi',
      'Malaysia',
      'Maldives',
      'Mali',
      'Malta',
      'Marshall Islands',
      'Mauritania',
      'Mauritius',
      'Mexico',
      'Micronesia',
      'Moldova',
      'Monaco',
      'Mongolia',
      'Montenegro',
      'Morocco',
      'Mozambique',
      'Myanmar',
      'Namibia',
      'Nauru',
      'Nepal',
      'Netherlands',
      'New Zealand',
      'Nicaragua',
      'Niger',
      'Nigeria',
      'North Korea',
      'North Macedonia',
      'Norway',
      'Oman',
      'Pakistan',
      'Palau',
      'Panama',
      'Papua New Guinea',
      'Paraguay',
      'Peru',
      'Philippines',
      'Poland',
      'Portugal',
      'Qatar',
      'Romania',
      'Russia',
      'Rwanda',
      'Saint Kitts and Nevis',
      'Saint Lucia',
      'Saint Vincent and the Grenadines',
      'Samoa',
      'San Marino',
      'Sao Tome and Principe',
      'Saudi Arabia',
      'Senegal',
      'Serbia',
      'Seychelles',
      'Sierra Leone',
      'Singapore',
      'Slovakia',
      'Slovenia',
      'Solomon Islands',
      'Somalia',
      'South Africa',
      'South Korea',
      'South Sudan',
      'Spain',
      'Sri Lanka',
      'Sudan',
      'Suriname',
      'Sweden',
      'Switzerland',
      'Syria',
      'Taiwan',
      'Tajikistan',
      'Tanzania',
      'Thailand',
      'Timor-Leste',
      'Togo',
      'Tonga',
      'Trinidad and Tobago',
      'Tunisia',
      'Turkey',
      'Turkmenistan',
      'Tuvalu',
      'Uganda',
      'Ukraine',
      'United Arab Emirates',
      'United Kingdom',
      'United States',
      'Uruguay',
      'Uzbekistan',
      'Vanuatu',
      'Vatican City',
      'Venezuela',
      'Vietnam',
      'Yemen',
      'Zambia',
      'Zimbabwe'
    ];
  }

  /// Gets common country variations and abbreviations
  Map<String, String> _getCountryVariations() {
    return {
      'usa': 'United States',
      'us': 'United States',
      'america': 'United States',
      'united states of america': 'United States',
      'uk': 'United Kingdom',
      'britain': 'United Kingdom',
      'england': 'United Kingdom',
      'great britain': 'United Kingdom',
      'uae': 'United Arab Emirates',
      'russia': 'Russia',
      'russian federation': 'Russia',
      'south korea': 'South Korea',
      'north korea': 'North Korea',
      'czech republic': 'Czech Republic',
      'czechia': 'Czech Republic',
      'holland': 'Netherlands',
    };
  }

  /// Validates that both city and country are provided and valid
  String? validateCityAndCountry(String? city, String? country) {
    final countryError = validateCountryInput(country);
    if (countryError != null) {
      return countryError;
    }

    final cityError = validateCityInput(city, country: country);
    if (cityError != null) {
      return cityError;
    }

    return null;
  }

  /// Async validation for both city and country
  Future<String?> validateCityAndCountryAsync(
      String? city, String? country) async {
    final countryError = validateCountryInput(country);
    if (countryError != null) {
      return countryError;
    }

    final cityError = await validateCityInputAsync(city, country: country);
    if (cityError != null) {
      return cityError;
    }

    return null;
  }

  /// Formats location data for display
  String formatLocationDisplay(Map<String, String>? locationData) {
    if (locationData == null || locationData.isEmpty) {
      return 'No location set';
    }

    final city = locationData['city']?.trim();
    final country = locationData['country']?.trim();

    if (city != null &&
        country != null &&
        city.isNotEmpty &&
        country.isNotEmpty) {
      return '${capitalizeLocationName(city)}, ${capitalizeLocationName(country)}';
    } else if (city != null && city.isNotEmpty) {
      return capitalizeLocationName(city);
    } else if (country != null && country.isNotEmpty) {
      return capitalizeLocationName(country);
    }

    return 'No location set';
  }

  /// Creates a location map from city and country strings
  Map<String, String> createLocationMap(String? city, String? country) {
    final Map<String, String> locationMap = {};

    if (city != null && city.trim().isNotEmpty) {
      locationMap['city'] = capitalizeLocationName(city.trim());
    }

    if (country != null && country.trim().isNotEmpty) {
      // Normalize country name to standard form
      final normalizedCountry = _normalizeCountryName(country.trim());
      locationMap['country'] = normalizedCountry;
    }

    return locationMap;
  }

  /// Normalizes country name to standard form
  String _normalizeCountryName(String country) {
    final normalized = country.toLowerCase().trim();
    final variations = _getCountryVariations();

    if (variations.containsKey(normalized)) {
      return variations[normalized]!;
    }

    return capitalizeLocationName(country);
  }

  /// Checks if a location name contains only valid characters
  bool _isValidLocationName(String name) {
    // Allow letters (including accented characters), spaces, hyphens, apostrophes, and periods
    final validNameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-'.]+$");
    return validNameRegex.hasMatch(name) && !_containsConsecutiveSpaces(name);
  }

  /// Checks for consecutive spaces which should not be allowed
  bool _containsConsecutiveSpaces(String name) {
    return name.contains(RegExp(r'\s{2,}'));
  }

  /// Capitalizes the first letter of each word in a location name
  String capitalizeLocationName(String name) {
    if (name.trim().isEmpty) return name;

    return name.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Normalizes location input by trimming and capitalizing
  String normalizeLocationInput(String input) {
    return capitalizeLocationName(input.trim());
  }

  /// Checks if a location map is complete (has both city and country)
  bool isLocationComplete(Map<String, String>? locationData) {
    if (locationData == null || locationData.isEmpty) {
      return false;
    }

    final city = locationData['city']?.trim();
    final country = locationData['country']?.trim();

    return city != null &&
        city.isNotEmpty &&
        country != null &&
        country.isNotEmpty;
  }

  /// Gets a list of common countries for dropdown/autocomplete
  List<String> getCommonCountries() {
    return [
      'United States',
      'Canada',
      'United Kingdom',
      'Australia',
      'Germany',
      'France',
      'Italy',
      'Spain',
      'Netherlands',
      'Sweden',
      'Norway',
      'Denmark',
      'Finland',
      'Switzerland',
      'Austria',
      'Belgium',
      'Ireland',
      'New Zealand',
      'Japan',
      'South Korea',
      'Singapore',
      'Malaysia',
      'Thailand',
      'Philippines',
      'Indonesia',
      'India',
      'China',
      'Brazil',
      'Mexico',
      'Argentina',
      'Chile',
      'Colombia',
      'Peru',
      'South Africa',
      'Nigeria',
      'Kenya',
      'Egypt',
      'Morocco',
      'Israel',
      'Turkey',
      'Russia',
      'Poland',
      'Czech Republic',
      'Hungary',
      'Romania',
      'Bulgaria',
      'Croatia',
      'Greece',
      'Portugal',
    ];
  }

  /// Filters countries based on user input for autocomplete
  List<String> filterCountries(String query) {
    if (query.trim().isEmpty) {
      return getCommonCountries();
    }

    final lowercaseQuery = query.toLowerCase();
    final allCountries = _getAllCountries();

    return allCountries
        .where((country) => country.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Suggests corrections for invalid country names
  List<String> suggestCountryCorrections(String invalidCountry) {
    final query = invalidCountry.toLowerCase().trim();
    final allCountries = _getAllCountries();

    // Find countries that start with the same letters
    final suggestions = allCountries
        .where((country) => country
            .toLowerCase()
            .startsWith(query.substring(0, query.length.clamp(0, 3))))
        .take(5)
        .toList();

    if (suggestions.isEmpty) {
      // Fallback to countries containing the query
      return allCountries
          .where((country) => country.toLowerCase().contains(query))
          .take(5)
          .toList();
    }

    return suggestions;
  }
}
