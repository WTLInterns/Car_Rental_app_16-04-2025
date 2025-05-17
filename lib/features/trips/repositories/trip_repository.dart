import 'package:flutter/foundation.dart';

import '../../../core/network/api_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/app_exception.dart';
import '../models/trip_model.dart';

class TripRepository {
  final ApiService _apiService;

  TripRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get user's trips history
  Future<List<Trip>> getUserTrips(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/trips?user_id=$userId',
      );

      final List<dynamic> tripsJson = response['trips'];
      return tripsJson.map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user trips: $e');
      }
      throw AppException(
        'Failed to load your trips. Please try again.',
        e.toString(),
      );
    }
  }

  /// Get driver's trips history
  Future<List<Trip>> getDriverTrips(String driverId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/trips/driver?driver_id=$driverId',
      );

      final List<dynamic> tripsJson = response['trips'];
      return tripsJson.map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching driver trips: $e');
      }
      throw AppException(
        'Failed to load your trips. Please try again.',
        e.toString(),
      );
    }
  }

  /// Get trip details by trip ID
  Future<Trip> getTripDetails(String tripId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/trips/$tripId',
      );

      return Trip.fromJson(response['trip']);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching trip details: $e');
      }
      throw AppException(
        'Failed to load trip details. Please try again.',
        e.toString(),
      );
    }
  }

  /// Submit trip rating
  Future<Trip> submitTripRating({
    required String tripId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.apiBaseUrl}/api/trips/$tripId/rate',
        body: {
          'rating': rating,
          if (comment != null) 'comment': comment,
        },
      );

      return Trip.fromJson(response['trip']);
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting trip rating: $e');
      }
      throw AppException(
        'Failed to submit rating. Please try again.',
        e.toString(),
      );
    }
  }

  /// Update trip status 
  Future<Trip> updateTripStatus({
    required String tripId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/trips/$tripId/status',
        body: {
          'status': status,
          if (additionalData != null) ...additionalData,
        },
      );

      return Trip.fromJson(response['trip']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating trip status: $e');
      }
      throw AppException(
        'Failed to update trip status. Please try again.',
        e.toString(),
      );
    }
  }

  /// Track trip location
  Future<Trip> updateTripLocation({
    required String tripId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.apiBaseUrl}/api/trips/$tripId/location',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return Trip.fromJson(response['trip']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating trip location: $e');
      }
      throw AppException(
        'Failed to update trip location. Please try again.',
        e.toString(),
      );
    }
  }
} 