class ChurchBranch {
  final String id;
  final String name;
  final String location;
  final String address;
  final String? description;
  final String? pastorId;
  final List<String> departments;
  final List<String> members;
  final DateTime createdAt;
  final String createdBy;
  final bool is_active;

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
    this.is_active = true,
  }) : departments = departments ?? [],
       members = members ?? [],
       createdAt = createdAt ?? DateTime.now();

  factory ChurchBranch.fromJson(Map<String, dynamic> json) {
    return ChurchBranch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      address: json['address'] ?? '',
      description: json['description'],
      pastorId: json['pastorId'],
      departments: (json['departments'] as List<dynamic>?)?.cast<String>() ?? [],
      members: (json['members'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      createdBy: json['createdBy'] ?? '',
      is_active: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'address': address,
      'description': description,
      'pastorId': pastorId,
      'departments': departments,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'is_active': is_active,
    };
  }

  ChurchBranch copyWith({
    String? id,
    String? name,
    String? location,
    String? address,
    String? description,
    String? pastorId,
    List<String>? departments,
    List<String>? members,
    DateTime? createdAt,
    String? createdBy,
    bool? is_active,
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
      createdBy: createdBy ?? this.createdBy,
      is_active: is_active ?? this.is_active,
    );
  }
} 