import 'package:equatable/equatable.dart';

import '../models/booking_model.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class VehiclesLoaded extends BookingState {
  final List<Vehicle> vehicles;

  const VehiclesLoaded(this.vehicles);

  @override
  List<Object> get props => [vehicles];
}

class FareCalculated extends BookingState {
  final double fare;

  const FareCalculated(this.fare);

  @override
  List<Object> get props => [fare];
}

class BookingCreated extends BookingState {
  final Booking booking;

  const BookingCreated(this.booking);

  @override
  List<Object> get props => [booking];
}

class BookingCancelled extends BookingState {}

class BookingDetailsFetched extends BookingState {
  final Booking booking;

  const BookingDetailsFetched(this.booking);

  @override
  List<Object> get props => [booking];
}

class BookingsFetched extends BookingState {
  final List<Booking> bookings;

  const BookingsFetched(this.bookings);

  @override
  List<Object> get props => [bookings];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object> get props => [message];
} 