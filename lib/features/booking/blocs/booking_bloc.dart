import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/booking_repository.dart';
import '../models/booking_model.dart';
import 'booking_state.dart';
import '../../../core/utils/app_exception.dart';
import 'booking_event.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;

  BookingBloc({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository,
        super(BookingInitial()) {
    on<LoadVehiclesEvent>(_onLoadVehicles);
    on<CalculateFareEvent>(_onCalculateFare);
    on<CreateBookingEvent>(_onCreateBooking);
    on<CancelBookingEvent>(_onCancelBooking);
    on<GetUserBookingsEvent>(_onGetUserBookings);
    on<GetBookingDetailsEvent>(_onGetBookingDetails);
    on<ResetBookingEvent>(_onResetBooking);
  }

  Future<void> _onLoadVehicles(
    LoadVehiclesEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      
      final vehicles = await _bookingRepository.getAvailableVehicles(
        pickupLocation: event.pickupLocation,
        dropLocation: event.dropLocation,
        pickupDateTime: event.pickupDateTime,
        vehicleType: event.vehicleType,
      );
      
      emit(VehiclesLoaded(vehicles));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> _onCalculateFare(
    CalculateFareEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      
      final fare = await _bookingRepository.calculateFare(
        pickupLocation: event.pickupLocation,
        dropLocation: event.dropLocation,
        vehicleType: event.vehicleType,
      );
      
      emit(FareCalculated(fare));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> _onCreateBooking(
    CreateBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      
      final booking = await _bookingRepository.createBooking(
        userId: event.userId,
        pickupLocation: event.pickupLocation,
        dropLocation: event.dropLocation,
        pickupDateTime: event.pickupDateTime,
        vehicleId: event.vehicleId,
        fare: event.fare,
        passengers: event.passengers,
      );
      
      emit(BookingCreated(booking));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      
      final success = await _bookingRepository.cancelBooking(
        event.bookingId,
        event.reason,
      );
      
      if (success) {
        emit(BookingCancelled());
      } else {
        emit(BookingError('Failed to cancel booking'));
      }
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> _onGetUserBookings(
    GetUserBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      final bookings = await _bookingRepository.getUserBookings(event.userId);
      emit(BookingsFetched(bookings));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> _onGetBookingDetails(
    GetBookingDetailsEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      final booking = await _bookingRepository.getBookingById(event.bookingId);
      emit(BookingDetailsFetched(booking));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  void _onResetBooking(
    ResetBookingEvent event,
    Emitter<BookingState> emit,
  ) {
    emit(BookingInitial());
  }
} 