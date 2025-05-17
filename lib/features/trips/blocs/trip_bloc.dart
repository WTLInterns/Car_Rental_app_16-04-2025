import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exception.dart';
import '../models/trip_model.dart';
import '../repositories/trip_repository.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository _tripRepository;

  TripBloc({required TripRepository tripRepository})
      : _tripRepository = tripRepository,
        super(TripInitial()) {
    on<LoadUserTripsEvent>(_onLoadUserTrips);
    on<LoadDriverTripsEvent>(_onLoadDriverTrips);
    on<LoadTripDetailsEvent>(_onLoadTripDetails);
    on<RateTripEvent>(_onRateTrip);
    on<UpdateTripStatusEvent>(_onUpdateTripStatus);
    on<UpdateTripLocationEvent>(_onUpdateTripLocation);
    on<ResetTripEvent>(_onResetTrip);
  }

  Future<void> _onLoadUserTrips(
    LoadUserTripsEvent event,
    Emitter<TripState> emit,
  ) async {
    try {
      emit(TripLoading());
      
      final trips = await _tripRepository.getUserTrips(event.userId);
      
      emit(UserTripsLoaded(trips));
    } catch (error) {
      emit(TripError(error.toString()));
    }
  }

  Future<void> _onLoadDriverTrips(
    LoadDriverTripsEvent event,
    Emitter<TripState> emit,
  ) async {
    try {
      emit(TripLoading());
      
      final trips = await _tripRepository.getDriverTrips(event.driverId);
      
      emit(DriverTripsLoaded(trips));
    } catch (error) {
      emit(TripError(error.toString()));
    }
  }

  Future<void> _onLoadTripDetails(
    LoadTripDetailsEvent event,
    Emitter<TripState> emit,
  ) async {
    try {
      emit(TripLoading());
      
      final trip = await _tripRepository.getTripDetails(event.tripId);
      
      emit(TripDetailsLoaded(trip));
    } catch (error) {
      emit(TripError(error.toString()));
    }
  }

  Future<void> _onRateTrip(
    RateTripEvent event,
    Emitter<TripState> emit,
  ) async {
    try {
      emit(TripLoading());
      
      final trip = await _tripRepository.submitTripRating(
        tripId: event.tripId,
        rating: event.rating,
        comment: event.comment,
      );
      
      emit(TripRated(trip));
    } catch (error) {
      emit(TripError(error.toString()));
    }
  }

  Future<void> _onUpdateTripStatus(
    UpdateTripStatusEvent event,
    Emitter<TripState> emit,
  ) async {
    try {
      emit(TripLoading());
      
      final trip = await _tripRepository.updateTripStatus(
        tripId: event.tripId,
        status: event.status,
        additionalData: event.additionalData,
      );
      
      emit(TripStatusUpdated(trip));
    } catch (error) {
      emit(TripError(error.toString()));
    }
  }

  Future<void> _onUpdateTripLocation(
    UpdateTripLocationEvent event,
    Emitter<TripState> emit,
  ) async {
    try {
      emit(TripLoading());
      
      final trip = await _tripRepository.updateTripLocation(
        tripId: event.tripId,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      
      emit(TripLocationUpdated(trip));
    } catch (error) {
      emit(TripError(error.toString()));
    }
  }

  void _onResetTrip(
    ResetTripEvent event,
    Emitter<TripState> emit,
  ) {
    emit(TripInitial());
  }
} 