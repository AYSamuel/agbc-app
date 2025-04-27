/// UserModel represents a church member or staff in the AGBC app.
/// Handles user profile information, roles, and church departments.
class UserModel {
  // Basic user information
  final String id; // User ID from Supabase Auth
  final String displayName;
  final String email;
  final String role;
  final String? phoneNumber; // User's contact number
  final String? photoUrl; // URL to user's profile photo
  final DateTime createdAt; // When the account was created
  final DateTime? lastLogin;

  // Church affiliation
  final String? branchId; // Current branch ID (nullable)
  final String? location; // User's location/city

  // Department involvement
  final List<String> departments; // Church departments (choir, media, ushering, etc.)
  final bool is_active; // Whether the account is active
  final bool email_verified; // Whether email has been verified
  final Map<String, bool> notificationSettings; // Notification preferences
  final String? notification_token;
  final DateTime? notification_token_updated_at;

  /// Constructor for creating a new UserModel instance
  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    required this.is_active,
    required this.email_verified,
    required this.departments,
    required this.notificationSettings,
    this.location,
    this.branchId,
    this.phoneNumber,
    this.photoUrl,
    this.notification_token,
    this.notification_token_updated_at,
  });

  /// Creates a UserModel instance from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('Creating UserModel from JSON: $json');
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login'] as String) : null,
      is_active: json['is_active'] as bool,
      email_verified: json['email_verified'] as bool,
      departments: List<String>.from(json['departments'] as List),
      notificationSettings: Map<String, bool>.from(json['notification_settings'] as Map),
      location: json['location'] as String?,
      branchId: json['branch_id'] as String?,
      phoneNumber: json['phone_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      notification_token: json['notification_token'],
      notification_token_updated_at: json['notification_token_updated_at'] != null 
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
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': is_active,
      'email_verified': email_verified,
      'departments': departments,
      'notification_settings': notificationSettings,
      'location': location,
      'branch_id': branchId,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'notification_token': notification_token,
      'notification_token_updated_at': notification_token_updated_at?.toIso8601String(),
    };
  }

  /// Checks if user is in a specific department
  bool isInDepartment(String department) {
    return departments.contains(department.toLowerCase());
  }

  /// Checks if user is an admin
  bool get isAdmin => role == 'admin';

  /// Checks if user is a pastor
  bool get isPastor => role == 'pastor';

  /// Creates a copy of the user with updated fields
  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? is_active,
    bool? email_verified,
    List<String>? departments,
    Map<String, bool>? notificationSettings,
    String? location,
    String? branchId,
    String? phoneNumber,
    String? photoUrl,
    String? notification_token,
    DateTime? notification_token_updated_at,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      is_active: is_active ?? this.is_active,
      email_verified: email_verified ?? this.email_verified,
      departments: departments ?? this.departments,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      location: location ?? this.location,
      branchId: branchId ?? this.branchId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      notification_token: notification_token ?? this.notification_token,
      notification_token_updated_at: notification_token_updated_at ?? this.notification_token_updated_at,
    );
  }
}
