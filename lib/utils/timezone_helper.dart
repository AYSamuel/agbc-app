import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/user_model.dart';

class TimezoneHelper {
  static final _logger = Logger('TimezoneHelper');
  static bool _initialized = false;
  static String? _cachedDeviceTimezone;

  /// Initialize the timezone database. Call this once at app startup.
  static Future<void> initializeTimezones() async {
    if (_initialized) {
      _logger.fine('Timezones already initialized');
      return;
    }

    try {
      tz_data.initializeTimeZones();

      // Get and cache the device timezone using native API
      await _loadDeviceTimezone();

      _initialized = true;
      _logger.info('Timezones initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize timezones', e);
      rethrow;
    }
  }

  /// Load device timezone using native API and cache it
  static Future<void> _loadDeviceTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      _logger.info('Native timezone detected: $timezone');

      // Validate that it's a valid IANA timezone
      if (isValidTimezone(timezone)) {
        _cachedDeviceTimezone = timezone;
        _logger.info('Using timezone: $_cachedDeviceTimezone');
      } else {
        _logger.warning('Invalid timezone from native: $timezone, using UTC');
        _cachedDeviceTimezone = 'UTC';
      }
    } catch (e) {
      _logger.warning('Failed to get native timezone, using UTC', e);
      _cachedDeviceTimezone = 'UTC';
    }
  }

  /// Get the device's current timezone as an IANA timezone identifier.
  /// Returns the cached timezone detected at app startup.
  /// Falls back to 'UTC' if the timezone cannot be determined.
  static String getDeviceTimezone() {
    // Return cached timezone if available
    if (_cachedDeviceTimezone != null) {
      return _cachedDeviceTimezone!;
    }

    // Fallback to UTC if timezone not yet initialized
    _logger.warning('Timezone not initialized, falling back to UTC');
    return 'UTC';
  }

  /// Get the user's timezone. Returns the timezone from user settings if available,
  /// otherwise returns the device timezone.
  static String getUserTimezone(UserModel? user) {
    if (user == null) {
      return getDeviceTimezone();
    }

    // Check if user has a custom timezone set in their settings
    final userTimezone = user.settings['timezone'] as String?;

    if (userTimezone != null && userTimezone.isNotEmpty) {
      // Validate the timezone
      try {
        tz.getLocation(userTimezone);
        return userTimezone;
      } catch (e) {
        _logger.warning('Invalid user timezone: $userTimezone, using device timezone');
      }
    }

    return getDeviceTimezone();
  }

  /// Convert a local DateTime to UTC.
  ///
  /// [localDateTime] - The local date/time to convert
  /// [timezone] - The IANA timezone identifier (e.g., 'America/New_York')
  ///
  /// Returns the UTC DateTime.
  static DateTime convertToUtc(DateTime localDateTime, String timezone) {
    try {
      final location = tz.getLocation(timezone);
      final tzDateTime = tz.TZDateTime(
        location,
        localDateTime.year,
        localDateTime.month,
        localDateTime.day,
        localDateTime.hour,
        localDateTime.minute,
        localDateTime.second,
        localDateTime.millisecond,
        localDateTime.microsecond,
      );
      return tzDateTime.toUtc();
    } catch (e) {
      _logger.severe('Failed to convert to UTC from $timezone', e);
      // Fallback: assume the input is already in UTC
      return localDateTime.toUtc();
    }
  }

  /// Convert a UTC DateTime to a specific timezone.
  ///
  /// [utcDateTime] - The UTC date/time to convert
  /// [timezone] - The target IANA timezone identifier (e.g., 'America/New_York')
  ///
  /// Returns the DateTime in the specified timezone.
  static DateTime convertFromUtc(DateTime utcDateTime, String timezone) {
    try {
      final location = tz.getLocation(timezone);
      final tzDateTime = tz.TZDateTime.from(utcDateTime.toUtc(), location);
      return DateTime(
        tzDateTime.year,
        tzDateTime.month,
        tzDateTime.day,
        tzDateTime.hour,
        tzDateTime.minute,
        tzDateTime.second,
        tzDateTime.millisecond,
        tzDateTime.microsecond,
      );
    } catch (e) {
      _logger.severe('Failed to convert from UTC to $timezone', e);
      // Fallback: return the UTC datetime
      return utcDateTime;
    }
  }

  /// Format a UTC DateTime in a specific timezone using the given pattern.
  ///
  /// [utcDateTime] - The UTC date/time to format
  /// [timezone] - The IANA timezone identifier for display
  /// [pattern] - The date format pattern (e.g., 'yyyy-MM-dd HH:mm')
  ///
  /// Returns the formatted date string.
  static String formatInTimezone(
    DateTime utcDateTime,
    String timezone,
    String pattern,
  ) {
    try {
      final localDateTime = convertFromUtc(utcDateTime, timezone);
      return DateFormat(pattern).format(localDateTime);
    } catch (e) {
      _logger.severe('Failed to format datetime in $timezone', e);
      // Fallback: format the UTC datetime
      return DateFormat(pattern).format(utcDateTime);
    }
  }

  /// Get the timezone offset string (e.g., '+05:30', '-08:00') for a given timezone.
  ///
  /// [timezone] - The IANA timezone identifier
  /// [dateTime] - The date/time to get the offset for (needed for DST handling)
  ///
  /// Returns the offset string.
  static String getTimezoneOffset(String timezone, DateTime dateTime) {
    try {
      final location = tz.getLocation(timezone);
      final tzDateTime = tz.TZDateTime.from(dateTime.toUtc(), location);
      final offset = tzDateTime.timeZoneOffset;

      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60).abs();
      final sign = hours >= 0 ? '+' : '-';

      return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      _logger.warning('Failed to get timezone offset for $timezone', e);
      return '+00:00';
    }
  }

  /// Check if a timezone string is valid.
  static bool isValidTimezone(String timezone) {
    try {
      tz.getLocation(timezone);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get a list of common IANA timezone identifiers.
  /// Useful for timezone selection UI.
  static List<String> getCommonTimezones() {
    return [
      'UTC',
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'America/Phoenix',
      'America/Anchorage',
      'Pacific/Honolulu',
      'Europe/London',
      'Europe/Paris',
      'Europe/Berlin',
      'Europe/Rome',
      'Europe/Madrid',
      'Europe/Amsterdam',
      'Europe/Brussels',
      'Europe/Vienna',
      'Europe/Stockholm',
      'Europe/Warsaw',
      'Europe/Athens',
      'Europe/Helsinki',
      'Europe/Moscow',
      'Asia/Dubai',
      'Asia/Kolkata',
      'Asia/Bangkok',
      'Asia/Singapore',
      'Asia/Hong_Kong',
      'Asia/Tokyo',
      'Asia/Seoul',
      'Asia/Shanghai',
      'Australia/Sydney',
      'Australia/Melbourne',
      'Australia/Brisbane',
      'Australia/Perth',
      'Pacific/Auckland',
      'Africa/Cairo',
      'Africa/Johannesburg',
      'Africa/Lagos',
      'Africa/Nairobi',
      'America/Toronto',
      'America/Vancouver',
      'America/Mexico_City',
      'America/Sao_Paulo',
      'America/Buenos_Aires',
    ];
  }
}
