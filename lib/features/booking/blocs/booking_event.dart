import 'package:equatable/equatable.dart';

import '../models/booking_model.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadVehiclesEvent extends BookingEvent {
  final String pickupLocation;
  final String dropLocation;
  final DateTime pickupDateTime;
  final String? vehicleType;

  const LoadVehiclesEvent({
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupDateTime,
    this.vehicleType,
  });

  @override
  List<Object?> get props => [
        pickupLocation,
        dropLocation,
        pickupDateTime,
        vehicleType,
      ];
}

class CalculateFareEvent extends BookingEvent {
  final String pickupLocation;
  final String dropLocation;
  final String vehicleType;

  const CalculateFareEvent({
    required this.pickupLocation,
    required this.dropLocation,
    required this.vehicleType,
  });

  @override
  List<Object> get props => [
        pickupLocation,
        dropLocation,
        vehicleType,
      ];
}

class CreateBookingEvent extends BookingEvent {
  final String userId;
  final String pickupLocation;
  final String dropLocation;
  final DateTime pickupDateTime;
  final String vehicleId;
  final double fare;
  final List<Passenger> passengers;

  const CreateBookingEvent({
    required this.userId,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupDateTime,
    required this.vehicleId,
    required this.fare,
    required this.passengers,
  });

  @override
  List<Object> get props => [
        userId,
        pickupLocation,
        dropLocation,
        pickupDateTime,
        vehicleId,
        fare,
        passengers,
      ];
}

class CancelBookingEvent extends BookingEvent {
  final String bookingId;
  final String reason;

  const CancelBookingEvent({
    required this.bookingId,
    required this.reason,
  });

  @override
  List<Object> get props => [bookingId, reason];
}

class GetBookingDetailsEvent extends BookingEvent {
  final String bookingId;

  const GetBookingDetailsEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class GetUserBookingsEvent extends BookingEvent {
  final String userId;

  const GetUserBookingsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class ResetBookingEvent extends BookingEvent {} 