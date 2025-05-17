class Booking {
  final String? id;
  final String? userId;
  final String bookingType; // 'oneWay' or 'roundTrip'
  final String pickupLocation;
  final String dropLocation;
  final DateTime pickupDateTime;
  final DateTime? returnDateTime;
  final String? vehicleType;
  final double? fare;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final List<Passenger>? passengers;
  final PaymentInfo? paymentInfo;

  Booking({
    this.id,
    this.userId,
    required this.bookingType,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupDateTime,
    this.returnDateTime,
    this.vehicleType,
    this.fare,
    required this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    this.passengers,
    this.paymentInfo,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    List<Passenger>? passengersList;
    if (json['passengers'] != null) {
      passengersList = List<Passenger>.from(
        json['passengers'].map((x) => Passenger.fromJson(x)),
      );
    }

    return Booking(
      id: json['id'] ?? json['bookingId'],
      userId: json['userId'],
      bookingType: json['bookingType'] ?? 'oneWay',
      pickupLocation: json['pickupLocation'],
      dropLocation: json['dropLocation'],
      pickupDateTime: json['pickupDateTime'] != null
          ? DateTime.parse(json['pickupDateTime'])
          : DateTime.now(),
      returnDateTime: json['returnDateTime'] != null
          ? DateTime.parse(json['returnDateTime'])
          : null,
      vehicleType: json['vehicleType'],
      fare: json['fare']?.toDouble(),
      status: json['status'] ?? 'pending',
      driverId: json['driverId'],
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      vehicleNumber: json['vehicleNumber'],
      passengers: passengersList,
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookingType': bookingType,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'pickupDateTime': pickupDateTime.toIso8601String(),
      'returnDateTime': returnDateTime?.toIso8601String(),
      'vehicleType': vehicleType,
      'fare': fare,
      'status': status,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
      'passengers': passengers?.map((e) => e.toJson()).toList(),
      'paymentInfo': paymentInfo?.toJson(),
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? bookingType,
    String? pickupLocation,
    String? dropLocation,
    DateTime? pickupDateTime,
    DateTime? returnDateTime,
    String? vehicleType,
    double? fare,
    String? status,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? vehicleNumber,
    List<Passenger>? passengers,
    PaymentInfo? paymentInfo,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingType: bookingType ?? this.bookingType,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      pickupDateTime: pickupDateTime ?? this.pickupDateTime,
      returnDateTime: returnDateTime ?? this.returnDateTime,
      vehicleType: vehicleType ?? this.vehicleType,
      fare: fare ?? this.fare,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      passengers: passengers ?? this.passengers,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }
}

class Vehicle {
  final String id;
  final String name;
  final String type;
  final String imageUrl;
  final double basePrice;
  final int passengerCapacity;
  final String registrationNumber;
  final Map<String, dynamic>? additionalFeatures;

  Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.basePrice,
    required this.passengerCapacity,
    required this.registrationNumber,
    this.additionalFeatures,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      imageUrl: json['image_url'],
      basePrice: json['base_price'].toDouble(),
      passengerCapacity: json['passenger_capacity'],
      registrationNumber: json['registration_number'],
      additionalFeatures: json['additional_features'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'image_url': imageUrl,
      'base_price': basePrice,
      'passenger_capacity': passengerCapacity,
      'registration_number': registrationNumber,
      'additional_features': additionalFeatures,
    };
  }
}

class Passenger {
  final String name;
  final String contactNumber;
  final int age;
  final String? gender;

  Passenger({
    required this.name,
    required this.contactNumber,
    required this.age,
    this.gender,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      name: json['name'],
      contactNumber: json['contact_number'],
      age: json['age'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contact_number': contactNumber,
      'age': age,
      if (gender != null) 'gender': gender,
    };
  }
}

class PaymentInfo {
  final String paymentMethod;
  final String paymentStatus;
  final double amount;
  final String? transactionId;
  final DateTime? paymentDate;

  PaymentInfo({
    required this.paymentMethod,
    required this.paymentStatus,
    required this.amount,
    this.transactionId,
    this.paymentDate,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      paymentMethod: json['paymentMethod'] ?? 'cash',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      amount: json['amount']?.toDouble() ?? 0.0,
      transactionId: json['transactionId'],
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'amount': amount,
      'transactionId': transactionId,
      'paymentDate': paymentDate?.toIso8601String(),
    };
  }
} 