// lib/models/church_model.dart

class ChurchModel {
  final String id; // Unique identifier for the church branch
  final String name; // Name of the church branch
  final String location; // Location of the church (e.g., city)
  final String personInCharge; // Name of the person in charge of the church

  // Constructor for creating an instance of ChurchModel
  ChurchModel({
    required this.id,
    required this.name,
    required this.location,
    required this.personInCharge,
  });

  // Factory constructor to create a ChurchModel instance from a JSON object
  factory ChurchModel.fromJson(Map<String, dynamic> json) {
    return ChurchModel(
      id: json['id'], // Map JSON id to model property
      name: json['name'], // Map JSON name to model property
      location: json['location'], // Map JSON location to model property
      personInCharge:
          json['personInCharge'], // Map JSON personInCharge to model property
    );
  }

  // Method to convert a ChurchModel instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Include id in JSON representation
      'name': name, // Include name in JSON representation
      'location': location, // Include location in JSON representation
      'personInCharge':
          personInCharge, // Include personInCharge in JSON representation
    };
  }
}
