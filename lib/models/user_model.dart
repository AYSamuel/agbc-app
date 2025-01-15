/// UserModel represents a church member or staff in the AGBC app.
/// Handles user profile information, roles, permissions, and church departments.
class UserModel {
  // Basic user information
  final String uid; // Unique identifier for the user
  final String email; // User's email address
  final String displayName; // User's display name
  final String? phoneNumber; // User's contact number
  final String? photoUrl; // URL to user's profile photo
  final DateTime createdAt; // When the account was created
  final DateTime lastLogin; // Last login timestamp

  // Church affiliation
  final String churchId; // Primary church branch ID
  final String role; // Primary role (admin, pastor, worker, member)
  final String location; // User's location/city

  // Department involvement
  final List<String>
      departments; // Church departments (choir, media, ushering, etc.)
  final DateTime?
      departmentJoinDate; // When they joined their current department

  // Account status
  final bool isActive; // Whether the account is active
  final bool emailVerified; // Whether email has been verified
  final Map<String, bool> permissions; // Specific permissions
  final Map<String, dynamic> notificationSettings; // Notification preferences

  final DateTime? dateJoined; // When they joined the church

  /// Constructor for creating a new UserModel instance
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.churchId,
    required this.role,
    required this.location,
    this.phoneNumber,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    this.departments = const [],
    this.departmentJoinDate,
    this.isActive = true,
    this.emailVerified = false,
    this.permissions = const {},
    this.notificationSettings = const {},
    this.dateJoined,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastLogin = lastLogin ?? DateTime.now();

  /// Creates a UserModel instance from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      phoneNumber: json['phoneNumber'],
      photoUrl: json['photoUrl'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      churchId: json['churchId'] ?? '',
      role: json['role'] ?? 'member',
      location: json['location'] ?? '',
      departments: List<String>.from(json['departments'] ?? []),
      departmentJoinDate: json['departmentJoinDate'] != null
          ? DateTime.parse(json['departmentJoinDate'])
          : null,
      isActive: json['isActive'] ?? true,
      emailVerified: json['emailVerified'] ?? false,
      permissions: Map<String, bool>.from(json['permissions'] ?? {}),
      notificationSettings:
          Map<String, dynamic>.from(json['notificationSettings'] ?? {}),
      dateJoined: json['dateJoined'] != null
          ? DateTime.parse(json['dateJoined'])
          : null,
    );
  }

  /// Converts the UserModel instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'churchId': churchId,
      'role': role,
      'location': location,
      'departments': departments,
      'departmentJoinDate': departmentJoinDate?.toIso8601String(),
      'isActive': isActive,
      'emailVerified': emailVerified,
      'permissions': permissions,
      'notificationSettings': notificationSettings,
      'dateJoined': dateJoined?.toIso8601String(),
    };
  }

  /// Checks if user is in a specific department
  bool isInDepartment(String department) {
    return departments.contains(department.toLowerCase());
  }

  /// Checks if user has a specific permission
  bool hasPermission(String permission) {
    return permissions[permission] ?? false;
  }

  /// Checks if user is an admin
  bool get isAdmin => role == 'admin';

  /// Checks if user is a pastor
  bool get isPastor => role == 'pastor';

  /// Creates a copy of the user with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? churchId,
    String? role,
    String? location,
    List<String>? departments,
    DateTime? departmentJoinDate,
    bool? isActive,
    bool? emailVerified,
    Map<String, bool>? permissions,
    Map<String, dynamic>? notificationSettings,
    DateTime? dateJoined,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      churchId: churchId ?? this.churchId,
      role: role ?? this.role,
      location: location ?? this.location,
      departments: departments ?? this.departments,
      departmentJoinDate: departmentJoinDate ?? this.departmentJoinDate,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      permissions: permissions ?? this.permissions,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      dateJoined: dateJoined ?? this.dateJoined,
    );
  }

  /// Two users are considered equal if they have the same UID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
