/// This class handles all branch-specific data and provides methods
/// for JSON conversion and object manipulation.
class ChurchModel {
  // Core identification and basic information
  final String id; // Unique identifier for the branch
  final String name; // Name of the church branch
  final String location; // City/area where the branch is located
  final String personInCharge; // Pastor or leader in charge of this branch

  // Contact and address information
  final String contactEmail; // Official email address for the branch
  final String contactPhone; // Contact phone number for inquiries
  final String address; // Complete physical address of the branch
  final String cityCountry; // City and country of the branch

  // Administrative and operational details
  final DateTime establishedDate; // Date when this branch was established
  final List<String>
      serviceSchedule; // List of regular service times (e.g., "Sunday 9:00 AM")
  final int capacity; // Maximum seating capacity of the building
  final bool isMainBranch; // Indicates if this is the headquarters/main branch

  final List<String> departments;

  /// Constructor for creating a new ChurchModel instance
  /// Required parameters ensure essential information is always provided
  /// Optional parameters have default values to ensure null safety
  ChurchModel({
    required this.id,
    required this.name,
    required this.location,
    required this.personInCharge,
    this.contactEmail = '', // Default empty string if not provided
    this.contactPhone = '', // Default empty string if not provided
    this.address = '', // Default empty string if not provided
    this.cityCountry = '', // Default empty string if not provided
    DateTime? establishedDate, // Optional establishment date
    this.serviceSchedule = const [], // Default empty list if not provided
    this.capacity = 0, // Default capacity of 0 if not provided
    this.isMainBranch = false, // Default to not being main branch
    required this.departments,
  }) : establishedDate = establishedDate ??
            DateTime.now(); // Use current date if not provided

  /// Factory constructor to create a ChurchModel from JSON data
  /// Used when retrieving data from Firebase or other data sources
  factory ChurchModel.fromJson(Map<String, dynamic> json) {
    return ChurchModel(
      // Convert JSON data to appropriate types with null safety
      id: json['id'] ?? '', // Use empty string if id is null
      name: json['name'] ?? '', // Use empty string if name is null
      location: json['location'] ?? '', // Use empty string if location is null
      personInCharge: json['personInCharge'] ??
          '', // Use empty string if personInCharge is null
      contactEmail:
          json['contactEmail'] ?? '', // Use empty string if email is null
      contactPhone:
          json['contactPhone'] ?? '', // Use empty string if phone is null
      address: json['address'] ?? '', // Use empty string if address is null
      cityCountry: json['cityCountry'] ?? '', // Use empty string if cityCountry is null
      // Convert ISO8601 string to DateTime, use current date if null
      establishedDate: json['establishedDate'] != null
          ? DateTime.parse(json['establishedDate'])
          : null,
      // Convert JSON array to List<String>, use empty list if null
      serviceSchedule: List<String>.from(json['serviceSchedule'] ?? []),
      capacity: json['capacity'] ?? 0, // Use 0 if capacity is null
      isMainBranch:
          json['isMainBranch'] ?? false, // Use false if isMainBranch is null
      departments: List<String>.from(json['departments'] ?? []),
    );
  }

  /// Converts the ChurchModel instance to a JSON object
  /// Used when saving data to Firebase or other data sources
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'personInCharge': personInCharge,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'address': address,
      'cityCountry': cityCountry,
      'establishedDate': establishedDate
          .toIso8601String(), // Convert DateTime to ISO8601 string
      'serviceSchedule': serviceSchedule,
      'capacity': capacity,
      'isMainBranch': isMainBranch,
      'departments': departments,
    };
  }

  /// Creates a copy of the church model with updated fields
  /// Useful for updating specific fields while maintaining immutability
  ChurchModel copyWith({
    String? id,
    String? name,
    String? location,
    String? personInCharge,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? cityCountry,
    DateTime? establishedDate,
    List<String>? serviceSchedule,
    int? capacity,
    bool? isMainBranch,
    List<String>? departments,
  }) {
    return ChurchModel(
      // Use new value if provided, otherwise use existing value
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      personInCharge: personInCharge ?? this.personInCharge,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      cityCountry: cityCountry ?? this.cityCountry,
      establishedDate: establishedDate ?? this.establishedDate,
      serviceSchedule: serviceSchedule ?? this.serviceSchedule,
      capacity: capacity ?? this.capacity,
      isMainBranch: isMainBranch ?? this.isMainBranch,
      departments: departments ?? this.departments,
    );
  }

  /// Override equality operator to compare church branches
  /// Two churches are considered equal if they have the same ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChurchModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  /// Override hashCode to be consistent with equality operator
  /// Uses the ID's hash code since that's what we use for equality
  @override
  int get hashCode => id.hashCode;
}
