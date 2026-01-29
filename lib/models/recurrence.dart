/// Shared Enum for recurrence frequency matching the database schema
enum RecurrenceFrequency {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  static RecurrenceFrequency fromDatabaseValue(String value) {
    switch (value) {
      case 'daily':
        return RecurrenceFrequency.daily;
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'monthly':
        return RecurrenceFrequency.monthly;
      case 'yearly':
        return RecurrenceFrequency.yearly;
      case 'none':
      default:
        return RecurrenceFrequency.none;
    }
  }

  String get databaseValue {
    return toString().split('.').last;
  }
}
