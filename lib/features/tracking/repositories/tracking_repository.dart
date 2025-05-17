import 'package:flutter/foundation.dart';

import '../../../core/network/api_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/app_exception.dart';
import '../models/tracking_model.dart';

class TrackingRepository {
  final ApiService _apiService;

  TrackingRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get tracking session details
  Future<TrackingSession> getTrackingSession(String sessionId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/tracking/sessions/$sessionId',
      );

      return TrackingSession.fromJson(response['tracking_session']);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tracking session: $e');
      }
      throw AppException(
        'Failed to load tracking information. Please try again.',
        e.toString(),
      );
    }
  }

  /// Get active tracking session for a trip
  Future<TrackingSession?> getActiveSessionForTrip(String tripId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/tracking/trips/$tripId/active',
      );

      if (response['tracking_session'] == null) {
        return null;
      }

      return TrackingSession.fromJson(response['tracking_session']);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching active tracking session: $e');
      }
      throw AppException(
        'Failed to load active tracking information. Please try again.',
        e.toString(),
      );
    }
  }

  /// Start a new tracking session
  Future<TrackingSession> startTracking({
    required String tripId,
    required String userId,
    required String driverId,
    required String bookingId,
    required double initialLatitude,
    required double initialLongitude,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.apiBaseUrl}/api/tracking/sessions/start',
        body: {
          'trip_id': tripId,
          'user_id': userId,
          'driver_id': driverId,
          'booking_id': bookingId,
          'initial_latitude': initialLatitude,
          'initial_longitude': initialLongitude,
          'start_time': DateTime.now().toIso8601String(),
        },
      );

      return TrackingSession.fromJson(response['tracking_session']);
    } catch (e) {
      if (kDebugMode) {
        print('Error starting tracking session: $e');
      }
      throw AppException(
        'Failed to start tracking. Please try again.',
        e.toString(),
      );
    }
  }

  /// End tracking session
  Future<TrackingSession> endTracking(String sessionId) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/tracking/sessions/$sessionId/end',
        body: {
          'end_time': DateTime.now().toIso8601String(),
        },
      );

      return TrackingSession.fromJson(response['tracking_session']);
    } catch (e) {
      if (kDebugMode) {
        print('Error ending tracking session: $e');
      }
      throw AppException(
        'Failed to end tracking. Please try again.',
        e.toString(),
      );
    }
  }

  /// Update location during tracking
  Future<TrackingUpdate> updateLocation({
    required String sessionId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? altitude,
    double? accuracy,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.apiBaseUrl}/api/tracking/sessions/$sessionId/update',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
          if (altitude != null) 'altitude': altitude,
          if (accuracy != null) 'accuracy': accuracy,
        },
      );

      return TrackingUpdate.fromJson(response['tracking_update']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating location: $e');
      }
      throw AppException(
        'Failed to update location. Please try again.',
        e.toString(),
      );
    }
  }

  /// Get location history
  Future<List<LocationPoint>> getLocationHistory(String sessionId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/tracking/sessions/$sessionId/history',
      );

      final List<dynamic> locationJson = response['location_history'];
      return locationJson.map((json) => LocationPoint.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching location history: $e');
      }
      throw AppException(
        'Failed to load location history. Please try again.',
        e.toString(),
      );
    }
  }
} 