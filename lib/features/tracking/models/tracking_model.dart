class TrackingSession {
  final String id;
  final String tripId;
  final String userId;
  final String driverId;
  final String bookingId;
  final bool isActive;
  final DateTime startTime;
  final DateTime? endTime;
  final List<LocationPoint> locationHistory;

  TrackingSession({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.driverId,
    required this.bookingId,
    required this.isActive,
    required this.startTime,
    this.endTime,
    required this.locationHistory,
  });

  factory TrackingSession.fromJson(Map<String, dynamic> json) {
    List<LocationPoint> locationList = [];
    if (json['location_history'] != null) {
      locationList = List<LocationPoint>.from(
        json['location_history'].map((x) => LocationPoint.fromJson(x)),
      );
    }

    return TrackingSession(
      id: json['id'],
      tripId: json['trip_id'],
      userId: json['user_id'],
      driverId: json['driver_id'],
      bookingId: json['booking_id'],
      isActive: json['is_active'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      locationHistory: locationList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'driver_id': driverId,
      'booking_id': bookingId,
      'is_active': isActive,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location_history': locationHistory.map((point) => point.toJson()).toList(),
    };
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? altitude;
  final double? heading;
  final double? accuracy;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.altitude,
    this.heading,
    this.accuracy,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      speed: json['speed']?.toDouble(),
      altitude: json['altitude']?.toDouble(),
      heading: json['heading']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'altitude': altitude,
      'heading': heading,
      'accuracy': accuracy,
    };
  }
}

class TrackingUpdate {
  final String sessionId;
  final LocationPoint currentLocation;
  final String status;
  final double? estimatedTimeArrival;
  final double? distanceRemaining;

  TrackingUpdate({
    required this.sessionId,
    required this.currentLocation,
    required this.status,
    this.estimatedTimeArrival,
    this.distanceRemaining,
  });

  factory TrackingUpdate.fromJson(Map<String, dynamic> json) {
    return TrackingUpdate(
      sessionId: json['session_id'],
      currentLocation: LocationPoint.fromJson(json['current_location']),
      status: json['status'],
      estimatedTimeArrival: json['estimated_time_arrival']?.toDouble(),
      distanceRemaining: json['distance_remaining']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'current_location': currentLocation.toJson(),
      'status': status,
      'estimated_time_arrival': estimatedTimeArrival,
      'distance_remaining': distanceRemaining,
    };
  }
} 