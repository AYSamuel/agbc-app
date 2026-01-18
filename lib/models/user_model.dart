/// UserModel represents a church member or staff in the Grace Portal app.
/// Enhanced with new schema features including location JSONB, settings, and metadata.
class UserModel {
  // Basic user information
  final String id; // User ID from Supabase Auth
  final String displayName;
  final String email;
  final UserRole role; // Using enum for type safety
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt; // New field for tracking updates
  final DateTime? lastLogin;

  // Church affiliation
  final String? branchId;
  final Map<String, dynamic>? location; // Now JSONB for structured location data

  // Department involvement
  final List<String> departments;
  final bool isActive;
  final bool emailVerified;
  
  // Enhanced settings and metadata
  final Map<String, dynamic> settings; // User preferences and settings
  final Map<String, dynamic> metadata; // Additional user metadata
  final String? notificationToken;
  final DateTime? notificationTokenUpdatedAt;

  /// Constructor for creating a new UserModel instance
  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    required this.isActive,
    required this.emailVerified,
    required this.departments,
    this.location,
    this.branchId,
    this.phoneNumber,
    this.photoUrl,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
    this.notificationToken,
    this.notificationTokenUpdatedAt,
  }) : settings = settings ?? {},
       metadata = metadata ?? {};

  /// Creates a UserModel instance from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.member,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      isActive: json['is_active'] as bool,
      emailVerified: json['email_verified'] as bool,
      departments: List<String>.from(json['departments'] as List? ?? []),
      location: json['location'] as Map<String, dynamic>?,
      branchId: json['branch_id'] as String?,
      phoneNumber: json['phone_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      notificationToken: json['notification_token'] as String?,
      notificationTokenUpdatedAt: json['notification_token_updated_at'] != null
          ? DateTime.parse(json['notification_token_updated_at'] as String)
          : null,
    );
  }

  /// Converts the UserModel instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
      'email_verified': emailVerified,
      'departments': departments,
      'location': location,
      'branch_id': branchId,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'settings': settings,
      'metadata': metadata,
      'notification_token': notificationToken,
      'notification_token_updated_at':
          notificationTokenUpdatedAt?.toIso8601String(),
    };
  }

  /// Checks if user is in a specific department
  bool isInDepartment(String department) {
    return departments.contains(department.toLowerCase());
  }

  /// Checks if user is an admin
  bool get isAdmin => role == UserRole.admin;

  /// Checks if user is a pastor
  bool get isPastor => role == UserRole.pastor;

  /// Checks if user is a worker
  bool get isWorker => role == UserRole.worker;

  /// Gets notification preference for a specific type
  bool getNotificationPreference(String type) {
    return settings['notifications']?[type] ?? true;
  }

  /// Gets user's timezone from settings
  /// Returns null if not set (will use device timezone)
  String? get timezone {
    return settings['timezone'] as String?;
  }

  /// Checks if user has a custom timezone set
  bool get hasCustomTimezone {
    return settings['timezone'] != null && (settings['timezone'] as String).isNotEmpty;
  }

  /// Gets user's location as a formatted string
  String? get locationString {
    if (location == null) return null;
    final city = location!['city'];
    final state = location!['state'];
    final country = location!['country'];
    
    List<String> parts = [];
    if (city != null) parts.add(city);
    if (state != null) parts.add(state);
    if (country != null) parts.add(country);
    
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Gets user's full name (alias for displayName)
  String get fullName => displayName;

  /// Creates a copy of the user with updated fields
  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    bool? isActive,
    bool? emailVerified,
    List<String>? departments,
    Map<String, dynamic>? location,
    String? branchId,
    String? phoneNumber,
    String? photoUrl,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
    String? notificationToken,
    DateTime? notificationTokenUpdatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      departments: departments ?? this.departments,
      location: location ?? this.location,
      branchId: branchId ?? this.branchId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
      notificationToken: notificationToken ?? this.notificationToken,
      notificationTokenUpdatedAt:
          notificationTokenUpdatedAt ?? this.notificationTokenUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Enum for user roles matching the database schema
enum UserRole {
  admin,
  pastor,
  worker,
  member,
}
