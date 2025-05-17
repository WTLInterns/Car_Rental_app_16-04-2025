class Profile {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImage;
  final Address? address;
  final List<EmergencyContact>? emergencyContacts;
  final Map<String, dynamic>? preferences;
  final DateTime? joinedDate;
  final String? role; // "USER" or "DRIVER"
  final DriverDetails? driverDetails;

  Profile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
    this.address,
    this.emergencyContacts,
    this.preferences,
    this.joinedDate,
    this.role,
    this.driverDetails,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    List<EmergencyContact>? contacts;
    if (json['emergency_contacts'] != null) {
      contacts = List<EmergencyContact>.from(
        json['emergency_contacts'].map((x) => EmergencyContact.fromJson(x)),
      );
    }

    return Profile(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      profileImage: json['profile_image'],
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      emergencyContacts: contacts,
      preferences: json['preferences'],
      joinedDate: json['joined_date'] != null ? DateTime.parse(json['joined_date']) : null,
      role: json['role'],
      driverDetails: json['driver_details'] != null ? DriverDetails.fromJson(json['driver_details']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'address': address?.toJson(),
      'emergency_contacts': emergencyContacts?.map((x) => x.toJson()).toList(),
      'preferences': preferences,
      'joined_date': joinedDate?.toIso8601String(),
      'role': role,
      'driver_details': driverDetails?.toJson(),
    };
  }

  Profile copyWith({
    String? userId,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImage,
    Address? address,
    List<EmergencyContact>? emergencyContacts,
    Map<String, dynamic>? preferences,
    DateTime? joinedDate,
    String? role,
    DriverDetails? driverDetails,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      preferences: preferences ?? this.preferences,
      joinedDate: joinedDate ?? this.joinedDate,
      role: role ?? this.role,
      driverDetails: driverDetails ?? this.driverDetails,
    );
  }
}

class Address {
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  Address({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      line1: json['line1'],
      line2: json['line2'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
    };
  }
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phoneNumber;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      relationship: json['relationship'],
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone_number': phoneNumber,
    };
  }
}

class DriverDetails {
  final String licenseNumber;
  final DateTime licenseExpiryDate;
  final String vehicleModel;
  final String vehicleColor;
  final String vehicleRegistrationNumber;
  final bool isOnDuty;
  final double? rating;
  final int? totalTrips;

  DriverDetails({
    required this.licenseNumber,
    required this.licenseExpiryDate,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehicleRegistrationNumber,
    required this.isOnDuty,
    this.rating,
    this.totalTrips,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      licenseNumber: json['license_number'],
      licenseExpiryDate: DateTime.parse(json['license_expiry_date']),
      vehicleModel: json['vehicle_model'],
      vehicleColor: json['vehicle_color'],
      vehicleRegistrationNumber: json['vehicle_registration_number'],
      isOnDuty: json['is_on_duty'],
      rating: json['rating']?.toDouble(),
      totalTrips: json['total_trips'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'license_number': licenseNumber,
      'license_expiry_date': licenseExpiryDate.toIso8601String(),
      'vehicle_model': vehicleModel,
      'vehicle_color': vehicleColor,
      'vehicle_registration_number': vehicleRegistrationNumber,
      'is_on_duty': isOnDuty,
      'rating': rating,
      'total_trips': totalTrips,
    };
  }
} 