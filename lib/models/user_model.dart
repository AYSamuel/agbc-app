// lib/models/user_model.dart

class UserModel {
  final String uid; // Unique identifier for the user
  final String email; // User's email address
  final String displayName; // User's display name
  final String churchId; // ID of the church the user belongs to
  final String role; // Role of the user (admin, worker, member)
  final String location; // User's location (e.g., city)

  // Constructor for creating an instance of UserModel
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.churchId,
    required this.role,
    required this.location,
  });

  // Factory constructor to create a UserModel instance from a JSON object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'], // Map JSON uid to model property
      email: json['email'], // Map JSON email to model property
      displayName:
          json['displayName'], // Map JSON displayName to model property
      churchId: json['churchId'], // Map JSON churchId to model property
      role: json['role'], // Map JSON role to model property
      location: json['location'], // Map JSON location to model property
    );
  }

  // Method to convert a UserModel instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'uid': uid, // Include uid in JSON representation
      'email': email, // Include email in JSON representation
      'displayName': displayName, // Include displayName in JSON representation
      'churchId': churchId, // Include churchId in JSON representation
      'role': role, // Include role in JSON representation
      'location': location, // Include location in JSON representation
    };
  }
}
