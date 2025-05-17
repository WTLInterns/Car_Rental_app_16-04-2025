class Driver {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String licenseNumber;
  final DateTime licenseExpiryDate;
  final String vehicleModel;
  final String vehicleColor;
  final String vehicleRegistrationNumber;
  final bool isOnDuty;
  final double? averageRating;
  final int completedTrips;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.licenseExpiryDate,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehicleRegistrationNumber,
    required this.isOnDuty,
    this.averageRating,
    required this.completedTrips,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      licenseNumber: json['license_number'],
      licenseExpiryDate: DateTime.parse(json['license_expiry_date']),
      vehicleModel: json['vehicle_model'],
      vehicleColor: json['vehicle_color'],
      vehicleRegistrationNumber: json['vehicle_registration_number'],
      isOnDuty: json['is_on_duty'],
      averageRating: json['average_rating']?.toDouble(),
      completedTrips: json['completed_trips'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'license_number': licenseNumber,
      'license_expiry_date': licenseExpiryDate.toIso8601String(),
      'vehicle_model': vehicleModel,
      'vehicle_color': vehicleColor,
      'vehicle_registration_number': vehicleRegistrationNumber,
      'is_on_duty': isOnDuty,
      'average_rating': averageRating,
      'completed_trips': completedTrips,
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleRegistrationNumber,
    bool? isOnDuty,
    double? averageRating,
    int? completedTrips,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleRegistrationNumber: vehicleRegistrationNumber ?? this.vehicleRegistrationNumber,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      averageRating: averageRating ?? this.averageRating,
      completedTrips: completedTrips ?? this.completedTrips,
    );
  }
} 