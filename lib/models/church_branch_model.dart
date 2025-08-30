class ChurchBranch {
  final String id;
  final String name;
  final Map<String, dynamic> location;
  final String address;
  final String? description;
  final String? pastorId;
  final String createdBy;
  final bool isActive;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChurchBranch({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.createdBy,
    this.description,
    this.pastorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    Map<String, dynamic>? settings,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       settings = settings ?? {};

  // Add locationString getter
  String get locationString {
    final parts = <String>[];
    if (location['city']?.toString().isNotEmpty == true) {
      parts.add(location['city'].toString());
    }
    if (location['state']?.toString().isNotEmpty == true) {
      parts.add(location['state'].toString());
    }
    if (location['country']?.toString().isNotEmpty == true) {
      parts.add(location['country'].toString());
    }
    return parts.isEmpty ? 'Location not specified' : parts.join(', ');
  }

  // Add fromJson factory constructor
  factory ChurchBranch.fromJson(Map<String, dynamic> json) {
    return ChurchBranch(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as Map<String, dynamic>? ?? {},
      address: json['address'] as String? ?? '',
      description: json['description'] as String?,
      pastorId: json['pastor_id'] as String?,
      createdBy: json['created_by'] as String,
      isActive: json['is_active'] as bool? ?? true,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // Add toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'address': address,
      'description': description,
      'pastor_id': pastorId,
      'created_by': createdBy,
      'is_active': isActive,
      'settings': settings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Add copyWith method for immutable updates
  ChurchBranch copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? location,
    String? address,
    String? description,
    String? pastorId,
    String? createdBy,
    bool? isActive,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChurchBranch(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      description: description ?? this.description,
      pastorId: pastorId ?? this.pastorId,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
