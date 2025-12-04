mixin FormValidationMixin {
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    // Enhanced email validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validates city/country location data
  String? validateLocationData(Map<String, String>? locationData) {
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
    
    if (city.length < 2) {
      return 'City name must be at least 2 characters';
    }
    
    if (country.length < 2) {
      return 'Country name must be at least 2 characters';
    }
    
    return null;
  }

  /// Validates individual city field
  String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your city';
    }
    if (value.trim().length < 2) {
      return 'City name must be at least 2 characters';
    }
    return null;
  }

  /// Validates individual country field
  String? validateCountry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your country';
    }
    if (value.trim().length < 2) {
      return 'Country name must be at least 2 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove spaces, dashes, and parentheses for validation
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with + (country code required)
    if (!cleanedValue.startsWith('+')) {
      return 'Phone number must include country code (e.g., +1234567890)';
    }

    // Enhanced phone number validation - must start with + and have 10-15 digits after
    final phoneRegex = RegExp(r'^\+[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid phone number with country code';
    }

    return null;
  }

  /// Validates required text fields
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  /// Validates text with minimum length
  String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }
}
