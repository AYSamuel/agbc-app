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
  final bool isActive; // Whether the account is active
  final bool emailVerified; // Whether email has been verified
  final Map<String, dynamic> notificationSettings; // Notification preferences
  final String? notificationToken;
  final DateTime? notificationTokenUpdatedAt;

  /// Constructor for creating a new UserModel instance
  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.photoUrl,
    DateTime? createdAt,
    this.lastLogin,
    this.branchId,
    this.location,
    this.departments = const [],
    this.isActive = true,
    this.emailVerified = false,
    this.notificationSettings = const {'email': true, 'push': true},
    this.notificationToken,
    this.notificationTokenUpdatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a UserModel instance from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'member',
      phoneNumber: json['phone_number'],
      photoUrl: json['photo_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      branchId: json['branch_id'],
      location: json['location'],
      departments: List<String>.from(json['departments'] ?? []),
      isActive: json['is_active'] ?? true,
      emailVerified: json['email_verified'] ?? false,
      notificationSettings: Map<String, dynamic>.from(json['notification_settings'] ?? {'email': true, 'push': true}),
      notificationToken: json['notification_token'],
      notificationTokenUpdatedAt: json['notification_token_updated_at'] != null 
          ? DateTime.parse(json['notification_token_updated_at']) 
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
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'branch_id': branchId,
      'location': location,
      'departments': departments,
      'is_active': isActive,
      'email_verified': emailVerified,
      'notification_settings': notificationSettings,
      'notification_token': notificationToken,
      'notification_token_updated_at': notificationTokenUpdatedAt?.toIso8601String(),
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
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? branchId,
    String? location,
    List<String>? departments,
    bool? isActive,
    bool? emailVerified,
    Map<String, dynamic>? notificationSettings,
    String? notificationToken,
    DateTime? notificationTokenUpdatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      branchId: branchId ?? this.branchId,
      location: location ?? this.location,
      departments: departments ?? this.departments,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      notificationToken: notificationToken ?? this.notificationToken,
      notificationTokenUpdatedAt: notificationTokenUpdatedAt ?? this.notificationTokenUpdatedAt,
    );
  }
}
