import 'package:equatable/equatable.dart';

import '../models/tracking_model.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class TrackingSessionLoaded extends TrackingState {
  final TrackingSession session;

  const TrackingSessionLoaded(this.session);

  @override
  List<Object> get props => [session];
}

class ActiveTrackingChecked extends TrackingState {
  final TrackingSession? activeSession;

  const ActiveTrackingChecked(this.activeSession);

  @override
  List<Object?> get props => [activeSession];
}

class TrackingStarted extends TrackingState {
  final TrackingSession session;

  const TrackingStarted(this.session);

  @override
  List<Object> get props => [session];
}

class TrackingEnded extends TrackingState {
  final TrackingSession session;

  const TrackingEnded(this.session);

  @override
  List<Object> get props => [session];
}

class LocationUpdated extends TrackingState {
  final TrackingUpdate update;

  const LocationUpdated(this.update);

  @override
  List<Object> get props => [update];
}

class LocationHistoryLoaded extends TrackingState {
  final List<LocationPoint> locationHistory;

  const LocationHistoryLoaded(this.locationHistory);

  @override
  List<Object> get props => [locationHistory];
}

class TrackingError extends TrackingState {
  final String message;

  const TrackingError(this.message);

  @override
  List<Object> get props => [message];
} 