class Trip {
  final String id;
  final String bookingId;
  final String userId;
  final String driverId;
  final String pickupLocation;
  final String dropLocation;
  final DateTime pickupTime;
  final DateTime? dropTime;
  final String status; // 'pending', 'ongoing', 'completed', 'cancelled'
  final double distance;
  final double fare;
  final String? vehicleId;
  final String? vehicleName;
  final String? vehicleNumber;
  final TripRating? rating;
  final List<TripRoute>? route;

  Trip({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.driverId,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupTime,
    this.dropTime,
    required this.status,
    required this.distance,
    required this.fare,
    this.vehicleId,
    this.vehicleName,
    this.vehicleNumber,
    this.rating,
    this.route,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    List<TripRoute>? routeList;
    if (json['route'] != null) {
      routeList = List<TripRoute>.from(
        json['route'].map((x) => TripRoute.fromJson(x)),
      );
    }

    return Trip(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      driverId: json['driver_id'],
      pickupLocation: json['pickup_location'],
      dropLocation: json['drop_location'],
      pickupTime: DateTime.parse(json['pickup_time']),
      dropTime: json['drop_time'] != null ? DateTime.parse(json['drop_time']) : null,
      status: json['status'],
      distance: json['distance'].toDouble(),
      fare: json['fare'].toDouble(),
      vehicleId: json['vehicle_id'],
      vehicleName: json['vehicle_name'],
      vehicleNumber: json['vehicle_number'],
      rating: json['rating'] != null ? TripRating.fromJson(json['rating']) : null,
      route: routeList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'driver_id': driverId,
      'pickup_location': pickupLocation,
      'drop_location': dropLocation,
      'pickup_time': pickupTime.toIso8601String(),
      'drop_time': dropTime?.toIso8601String(),
      'status': status,
      'distance': distance,
      'fare': fare,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'vehicle_number': vehicleNumber,
      'rating': rating?.toJson(),
      'route': route?.map((r) => r.toJson()).toList(),
    };
  }

  Trip copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? driverId,
    String? pickupLocation,
    String? dropLocation,
    DateTime? pickupTime,
    DateTime? dropTime,
    String? status,
    double? distance,
    double? fare,
    String? vehicleId,
    String? vehicleName,
    String? vehicleNumber,
    TripRating? rating,
    List<TripRoute>? route,
  }) {
    return Trip(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      pickupTime: pickupTime ?? this.pickupTime,
      dropTime: dropTime ?? this.dropTime,
      status: status ?? this.status,
      distance: distance ?? this.distance,
      fare: fare ?? this.fare,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      rating: rating ?? this.rating,
      route: route ?? this.route,
    );
  }
}

class TripRating {
  final double rating;
  final String? comment;
  final DateTime createdAt;

  TripRating({
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory TripRating.fromJson(Map<String, dynamic> json) {
    return TripRating(
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TripRoute {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  TripRoute({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory TripRoute.fromJson(Map<String, dynamic> json) {
    return TripRoute(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
} 