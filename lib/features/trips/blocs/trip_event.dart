import 'package:equatable/equatable.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserTripsEvent extends TripEvent {
  final String userId;

  const LoadUserTripsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LoadDriverTripsEvent extends TripEvent {
  final String driverId;

  const LoadDriverTripsEvent({required this.driverId});

  @override
  List<Object> get props => [driverId];
}

class LoadTripDetailsEvent extends TripEvent {
  final String tripId;

  const LoadTripDetailsEvent({required this.tripId});

  @override
  List<Object> get props => [tripId];
}

class RateTripEvent extends TripEvent {
  final String tripId;
  final double rating;
  final String? comment;

  const RateTripEvent({
    required this.tripId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [tripId, rating, comment];
}

class UpdateTripStatusEvent extends TripEvent {
  final String tripId;
  final String status;
  final Map<String, dynamic>? additionalData;

  const UpdateTripStatusEvent({
    required this.tripId,
    required this.status,
    this.additionalData,
  });

  @override
  List<Object?> get props => [tripId, status, additionalData];
}

class UpdateTripLocationEvent extends TripEvent {
  final String tripId;
  final double latitude;
  final double longitude;

  const UpdateTripLocationEvent({
    required this.tripId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [tripId, latitude, longitude];
}

class ResetTripEvent extends TripEvent {} 