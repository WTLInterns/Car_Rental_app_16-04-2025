import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exception.dart';
import '../models/tracking_model.dart';
import '../repositories/tracking_repository.dart';
import 'tracking_event.dart';
import 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final TrackingRepository _trackingRepository;

  TrackingBloc({required TrackingRepository trackingRepository})
      : _trackingRepository = trackingRepository,
        super(TrackingInitial()) {
    on<LoadTrackingSessionEvent>(_onLoadTrackingSession);
    on<CheckActiveTrackingEvent>(_onCheckActiveTracking);
    on<StartTrackingEvent>(_onStartTracking);
    on<EndTrackingEvent>(_onEndTracking);
    on<UpdateLocationEvent>(_onUpdateLocation);
    on<LoadLocationHistoryEvent>(_onLoadLocationHistory);
    on<ResetTrackingEvent>(_onResetTracking);
  }

  Future<void> _onLoadTrackingSession(
    LoadTrackingSessionEvent event,
    Emitter<TrackingState> emit,
  ) async {
    try {
      emit(TrackingLoading());
      
      final session = await _trackingRepository.getTrackingSession(event.sessionId);
      
      emit(TrackingSessionLoaded(session));
    } catch (error) {
      emit(TrackingError(error.toString()));
    }
  }

  Future<void> _onCheckActiveTracking(
    CheckActiveTrackingEvent event,
    Emitter<TrackingState> emit,
  ) async {
    try {
      emit(TrackingLoading());
      
      final session = await _trackingRepository.getActiveSessionForTrip(event.tripId);
      
      emit(ActiveTrackingChecked(session));
    } catch (error) {
      emit(TrackingError(error.toString()));
    }
  }

  Future<void> _onStartTracking(
    StartTrackingEvent event,
    Emitter<TrackingState> emit,
  ) async {
    try {
      emit(TrackingLoading());
      
      final session = await _trackingRepository.startTracking(
        tripId: event.tripId,
        userId: event.userId,
        driverId: event.driverId,
        bookingId: event.bookingId,
        initialLatitude: event.initialLatitude,
        initialLongitude: event.initialLongitude,
      );
      
      emit(TrackingStarted(session));
    } catch (error) {
      emit(TrackingError(error.toString()));
    }
  }

  Future<void> _onEndTracking(
    EndTrackingEvent event,
    Emitter<TrackingState> emit,
  ) async {
    try {
      emit(TrackingLoading());
      
      final session = await _trackingRepository.endTracking(event.sessionId);
      
      emit(TrackingEnded(session));
    } catch (error) {
      emit(TrackingError(error.toString()));
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocationEvent event,
    Emitter<TrackingState> emit,
  ) async {
    try {
      final update = await _trackingRepository.updateLocation(
        sessionId: event.sessionId,
        latitude: event.latitude,
        longitude: event.longitude,
        speed: event.speed,
        heading: event.heading,
        altitude: event.altitude,
        accuracy: event.accuracy,
      );
      
      emit(LocationUpdated(update));
    } catch (error) {
      emit(TrackingError(error.toString()));
    }
  }

  Future<void> _onLoadLocationHistory(
    LoadLocationHistoryEvent event,
    Emitter<TrackingState> emit,
  ) async {
    try {
      emit(TrackingLoading());
      
      final locationHistory = await _trackingRepository.getLocationHistory(event.sessionId);
      
      emit(LocationHistoryLoaded(locationHistory));
    } catch (error) {
      emit(TrackingError(error.toString()));
    }
  }

  void _onResetTracking(
    ResetTrackingEvent event,
    Emitter<TrackingState> emit,
  ) {
    emit(TrackingInitial());
  }
} 