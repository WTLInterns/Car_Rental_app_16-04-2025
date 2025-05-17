import 'package:equatable/equatable.dart';

import '../models/trip_model.dart';

abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class UserTripsLoaded extends TripState {
  final List<Trip> trips;

  const UserTripsLoaded(this.trips);

  @override
  List<Object> get props => [trips];
}

class DriverTripsLoaded extends TripState {
  final List<Trip> trips;

  const DriverTripsLoaded(this.trips);

  @override
  List<Object> get props => [trips];
}

class TripDetailsLoaded extends TripState {
  final Trip trip;

  const TripDetailsLoaded(this.trip);

  @override
  List<Object> get props => [trip];
}

class TripRated extends TripState {
  final Trip trip;

  const TripRated(this.trip);

  @override
  List<Object> get props => [trip];
}

class TripStatusUpdated extends TripState {
  final Trip trip;

  const TripStatusUpdated(this.trip);

  @override
  List<Object> get props => [trip];
}

class TripLocationUpdated extends TripState {
  final Trip trip;

  const TripLocationUpdated(this.trip);

  @override
  List<Object> get props => [trip];
}

class TripError extends TripState {
  final String message;

  const TripError(this.message);

  @override
  List<Object> get props => [message];
} 