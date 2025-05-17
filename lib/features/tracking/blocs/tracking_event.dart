import 'package:equatable/equatable.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrackingSessionEvent extends TrackingEvent {
  final String sessionId;

  const LoadTrackingSessionEvent({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}

class CheckActiveTrackingEvent extends TrackingEvent {
  final String tripId;

  const CheckActiveTrackingEvent({required this.tripId});

  @override
  List<Object> get props => [tripId];
}

class StartTrackingEvent extends TrackingEvent {
  final String tripId;
  final String userId;
  final String driverId;
  final String bookingId;
  final double initialLatitude;
  final double initialLongitude;

  const StartTrackingEvent({
    required this.tripId,
    required this.userId,
    required this.driverId,
    required this.bookingId,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  List<Object> get props => [
        tripId,
        userId,
        driverId,
        bookingId,
        initialLatitude,
        initialLongitude,
      ];
}

class EndTrackingEvent extends TrackingEvent {
  final String sessionId;

  const EndTrackingEvent({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}

class UpdateLocationEvent extends TrackingEvent {
  final String sessionId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? altitude;
  final double? accuracy;

  const UpdateLocationEvent({
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.altitude,
    this.accuracy,
  });

  @override
  List<Object?> get props => [
        sessionId,
        latitude,
        longitude,
        speed,
        heading,
        altitude,
        accuracy,
      ];
}

class LoadLocationHistoryEvent extends TrackingEvent {
  final String sessionId;

  const LoadLocationHistoryEvent({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}

class ResetTrackingEvent extends TrackingEvent {} 