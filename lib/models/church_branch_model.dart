/// Enhanced ChurchBranch model with new schema features including location JSONB and settings.
class ChurchBranch {
  final String id;
  final String name;
  final Map<String, dynamic> location; // Now JSONB for structured location data
  final String address;
  final String? description;
  final String? pastorId;
  final List<String> departments;
  final List<String> members;
  final DateTime createdAt;
  final DateTime updatedAt; // New field for tracking updates
  final String createdBy;
  final bool isActive;
  final Map<String, dynamic> settings; // Branch-specific settings

  ChurchBranch({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.createdBy,
    this.description,
    this.pastorId,
    List<String>? departments,
    List<String>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    Map<String, dynamic>? settings,
  })  : departments = departments ?? [],
        members = members ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        settings = settings ?? {};

  factory ChurchBranch.fromJson(Map<String, dynamic> json) {
    return ChurchBranch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: Map<String, dynamic>.from(json['location'] as Map? ?? {}),
      address: json['address'] ?? '',
      description: json['description'],
      pastorId: json['pastor_id'],
      departments:
          (json['departments'] as List<dynamic>?)?.cast<String>() ?? [],
      members: (json['members'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      createdBy: json['created_by'] ?? '',
      isActive: json['is_active'] ?? true,
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'address': address,
      'description': description,
      'pastor_id': pastorId,
      'departments': departments,
      'members': members,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'is_active': isActive,
      'settings': settings,
    };
  }

  /// Gets location as a formatted string
  String get locationString {
    final city = location['city'];
    final state = location['state'];
    final country = location['country'];
    
    List<String> parts = [];
    if (city != null) parts.add(city);
    if (state != null) parts.add(state);
    if (country != null) parts.add(country);
    
    return parts.isEmpty ? address : parts.join(', ');
  }

  /// Gets branch timezone from settings
  String get timezone {
    return settings['timezone'] ?? 'UTC';
  }

  /// Checks if branch allows online meetings
  bool get allowsOnlineMeetings {
    return settings['allow_online_meetings'] ?? true;
  }

  ChurchBranch copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? location,
    String? address,
    String? description,
    String? pastorId,
    List<String>? departments,
    List<String>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return ChurchBranch(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      description: description ?? this.description,
      pastorId: pastorId ?? this.pastorId,
      departments: departments ?? this.departments,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChurchBranch &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
