import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/app_exception.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final ApiService _apiService;
  
  BookingRepository({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  /// Fetches available vehicles for a booking
  Future<List<Vehicle>> getAvailableVehicles({
    required String pickupLocation,
    required String dropLocation,
    required DateTime pickupDateTime,
    String? vehicleType,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.apiBaseUrl}/api/vehicles/available',
        body: {
          'pickup_location': pickupLocation,
          'drop_location': dropLocation,
          'pickup_date_time': pickupDateTime.toIso8601String(),
          if (vehicleType != null) 'vehicle_type': vehicleType,
        },
      );

      final List<dynamic> vehiclesJson = response['vehicles'];
      return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching available vehicles: $e');
      }
      throw AppException(
        'Failed to load available vehicles. Please try again.',
        e.toString(),
      );
    }
  }
  
  /// Creates a new booking
  Future<Booking> createBooking({
    required String userId,
    required String pickupLocation,
    required String dropLocation,
    required DateTime pickupDateTime,
    required String vehicleId,
    required double fare,
    required List<Passenger> passengers,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.apiBaseUrl}/api/bookings/create',
        body: {
          'user_id': userId,
          'pickup_location': pickupLocation,
          'drop_location': dropLocation,
          'pickup_date_time': pickupDateTime.toIso8601String(),
          'vehicle_id': vehicleId,
          'fare': fare,
          'passengers': passengers.map((p) => p.toJson()).toList(),
          'status': 'pending',
        },
      );

      return Booking.fromJson(response['booking']);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating booking: $e');
      }
      throw AppException(
        'Failed to create booking. Please try again.',
        e.toString(),
      );
    }
  }
  
  /// Fetches a specific booking by ID
  Future<Booking> getBookingById(String bookingId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/bookings/$bookingId',
      );

      return Booking.fromJson(response['booking']);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching booking: $e');
      }
      throw AppException(
        'Failed to load booking details. Please try again.',
        e.toString(),
      );
    }
  }
  
  /// Cancels a booking
  Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/bookings/$bookingId/cancel',
        body: {
          'reason': reason,
        },
      );

      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling booking: $e');
      }
      throw AppException(
        'Failed to cancel booking. Please try again.',
        e.toString(),
      );
    }
  }
  
  /// Calculates estimated fare for a trip
  Future<double> calculateFare({
    required String pickupLocation,
    required String dropLocation,
    required String vehicleType,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.apiBaseUrl}/api/bookings/calculate-fare',
        body: {
          'pickup_location': pickupLocation,
          'drop_location': dropLocation,
          'vehicle_type': vehicleType,
        },
      );

      return double.parse(response['estimated_fare'].toString());
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating fare: $e');
      }
      throw AppException(
        'Failed to calculate fare. Please try again.',
        e.toString(),
      );
    }
  }
  
  /// Fetches bookings for a specific user
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/bookings/user/$userId',
      );

      final List<dynamic> bookingsJson = response['bookings'];
      return bookingsJson.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user bookings: $e');
      }
      throw AppException(
        'Failed to load your bookings. Please try again.',
        e.toString(),
      );
    }
  }
}

class BookingException extends AppException {
  BookingException(String message) : super(message, "Booking Error");
} 