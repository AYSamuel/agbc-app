import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for geocoding using OpenStreetMap's Nominatim API
/// Free, open-source alternative to Google Geocoding
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _cachePrefix = 'nominatim_cache_';
  static const Duration _cacheDuration = Duration(days: 30);

  // Rate limiting: Nominatim requires 1 request per second maximum
  DateTime? _lastRequestTime;

  /// Ensures we respect the 1 request/second rate limit
  Future<void> _respectRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest.inMilliseconds < 1000) {
        final waitTime = 1000 - timeSinceLastRequest.inMilliseconds;
        await Future.delayed(Duration(milliseconds: waitTime));
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Get cached search results if not expired
  Future<List<Map<String, String>>?> _getCachedResults(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cachePrefix$query');

      if (cached != null) {
        final data = jsonDecode(cached);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);

        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          debugPrint('Returning cached results for: $query');
          return List<Map<String, String>>.from(
            (data['results'] as List).map((e) => Map<String, String>.from(e))
          );
        }
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }

    return null;
  }

  /// Cache search results for future use
  Future<void> _cacheResults(String query, List<Map<String, String>> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'results': results,
      };
      await prefs.setString('$_cachePrefix$query', jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  /// Search for locations by query string
  /// Returns list of suggestions with city, country, and coordinates
  Future<List<Map<String, String>>> searchLocations(String query) async {
    if (query.trim().length < 2) return [];

    final normalizedQuery = query.trim().toLowerCase();

    // Check cache first
    final cached = await _getCachedResults(normalizedQuery);
    if (cached != null) {
      return cached;
    }

    try {
      await _respectRateLimit();

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
        'accept-language': 'en',
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AGBC-App/1.0 (Flutter)', // REQUIRED by Nominatim usage policy
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final results = <Map<String, String>>[];

        for (var item in data) {
          final address = item['address'] ?? {};

          // Extract city name (try multiple fields as different places use different fields)
          final city = address['city'] ??
                      address['town'] ??
                      address['village'] ??
                      address['municipality'] ??
                      address['county'] ??
                      address['state'] ?? '';

          final country = address['country'] ?? '';
          final displayName = item['display_name'] ?? '';

          if (city.isNotEmpty && country.isNotEmpty) {
            results.add({
              'city': city,
              'country': country,
              'display': '$city, $country',
              'full_address': displayName,
              'lat': item['lat']?.toString() ?? '',
              'lon': item['lon']?.toString() ?? '',
            });
          }
        }

        // Cache the results
        if (results.isNotEmpty) {
          await _cacheResults(normalizedQuery, results);
        }

        return results;
      } else {
        debugPrint('Nominatim API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Nominatim search error: $e');
      return [];
    }
  }

  /// Validate if a city exists in a country
  /// Returns true if location is found
  Future<bool> validateLocation(String city, String country) async {
    try {
      await _respectRateLimit();

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'city': city,
        'country': country,
        'format': 'json',
        'limit': '1',
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AGBC-App/1.0 (Flutter)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.isNotEmpty;
      }

      return false;
    } catch (e) {
      debugPrint('Nominatim validation error: $e');
      // Return true on error to allow form submission (graceful degradation)
      return true;
    }
  }

  /// Reverse geocode: Get address from coordinates
  /// Useful for getting location from GPS coordinates
  Future<Map<String, String>?> reverseGeocode(double lat, double lon) async {
    try {
      await _respectRateLimit();

      final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'addressdetails': '1',
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AGBC-App/1.0 (Flutter)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] ?? {};

        final city = address['city'] ??
                    address['town'] ??
                    address['village'] ?? '';
        final country = address['country'] ?? '';

        if (city.isNotEmpty && country.isNotEmpty) {
          return {
            'city': city,
            'country': country,
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('Nominatim reverse geocode error: $e');
      return null;
    }
  }
}
